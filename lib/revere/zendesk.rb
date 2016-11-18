module Revere
  module Zendesk

    ZENDESK_CONFIG = YAML.load_file("config/zendesk.yml").fetch(RACK_ENV)

    BASE_URI = ENV.fetch("ZENDESK_BASE_URI")
    USER = ENV.fetch("ZENDESK_USER")
    TOKEN = ENV.fetch("ZENDESK_TOKEN")

    def self.modify_ticket_with_trello_list(ticket_id, trello_list_name)
      request(:put, "tickets/#{ticket_id}.json", {
        ticket: {
          custom_fields: [{
            id: ZENDESK_CONFIG.dig("custom_fields", "ticket", "trello_list_name", "id").to_s,
            value: trello_list_name
          }]
        }
      })
    end

    # template for zendesk requests
    def self.request(verb, path, data={})
      uri = Addressable::URI.parse(File.join(BASE_URI, path))
      response = HTTP
        .basic_auth(user: USER, pass: TOKEN)
        .request(verb, uri.to_s, json: data)

      if response.code == 200
        response
      else
        raise "HTTP code is #{response.code}, response is #{response.to_s.inspect}, verb:#{verb}, uri:#{uri}, data:#{data.inspect}"
      end
    end

  end
end
