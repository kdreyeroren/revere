module Revere
  module Zendesk

    class ZendeskError < RuntimeError
    end

    ZENDESK_CONFIG = YAML.load_file("config/zendesk.yml").fetch(RACK_ENV)

    BASE_URI = ENV.fetch("ZENDESK_BASE_URI")
    USER     = ENV.fetch("ZENDESK_USER")
    TOKEN    = ENV.fetch("ZENDESK_TOKEN")

    # MODIFY
    # You'll want to modify this with aspects of the Zendesk ticket you want to update. Use the field IDs from your
    # modified zendesk.yml file.
    def self.update_ticket(ticket_id, trello_list_name: "", github_links: [], trello_board_name: "")
      retries = 0
      begin
        ticket_obj = {
            ticket: {
              custom_fields: [
                {
                  id: field_id("trello_list_name"),
                  value: format_tags(trello_list_name)
                },
                {
                  id: field_id("trello_board_name"),
                  value: format_tags(trello_board_name)
                },
                {
                  id: field_id("github_links"),
                  value: github_links.join("\n")
                }
              ]
            }
        }
        request(:put, "tickets/#{ticket_id}.json", ticket_obj)
      rescue ZendeskError => error
        if error.message.include?("database collision") && ((retries += 1) < 5)
          sleep 1
          retry
        elsif error.message.include? "closed prevents ticket update"
          # noop
        elsif error.message.include? "policy metric"
          # noop
          # These were errors we could never find a source for and never seemed to cause any problems. Ah, the grand 
          # mysteries of life!
        else
          raise
        end
      end
    end

    # Updates the Zendesk custom fields with the list names. Called in the Rakefile.
    def self.update_ticket_fields(list_names)
      custom_field_options = list_names.map { |name| { name: name, value: Zendesk.format_tags(name) } }

      request(:put, "ticket_fields/#{field_id("trello_list_name")}.json", { "ticket_field": { "custom_field_options": custom_field_options}})
    end

    # Finds the school ID from within the Zendesk ticket. If you have an account ID or user ID stored in your ticket
    # somewhere, you can use this to find it, just replace the "school_id" in the method below with your own field name
    # stored in zendesk.yml.
    def self.school_id(ticket_id)
      body = request(:get, "tickets/#{ticket_id}.json")
      parsed_body = JSON.parse(body)
      parsed_body.dig("ticket", "custom_fields").find { |i| i["id"] == field_id("school_id").to_i }.fetch("value")
    end

    def self.field_id(field_name)
      ZENDESK_CONFIG.dig("custom_fields", "ticket", field_name, "id").to_s
    end

    # Formats the value in Zendesk so it can be used as a tag for the custom ticket field.
    def self.format_tags(list_name)
      list_name.downcase.gsub(/\W/, "_").squeeze("_")
    end

    # This is the template for Zendesk requests. You can always make more requests of your own using this method.
    def self.request(verb, path, data={})
      uri = Addressable::URI.parse(File.join(BASE_URI, path))

      Revere.logger.info "Performing request: #{verb.to_s.upcase} #{uri} with data #{data.inspect}"

      response = HTTP
        .basic_auth(user: USER, pass: TOKEN)
        .request(verb, uri.to_s, json: data)

      Revere.logger.info "Response #{response.code}, body: #{response.body}"

      if (200..299).cover? response.code
        response
      else
        raise ZendeskError, "HTTP code is #{response.code}, response is #{response.to_s.inspect}, verb:#{verb}, uri:#{uri}, data:#{data.inspect}"
      end
    end

  end
end
