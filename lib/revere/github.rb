module Revere

  module Github

    BASE_URI      = ENV.fetch("GITHUB_BASE_URI")
    CLIENT_ID     = ENV.fetch("GITHUB_CLIENT_ID")
    CLIENT_SECRET = ENV.fetch("GITHUB_CLIENT_SECRET")
    AUTH_TOKEN    = ENV.fetch("GITHUB_AUTH_TOKEN")
    GITHUB_REPO   = ENV.fetch("GITHUB_REPO")

    UP_NEXT_LIST_ID     = ENV.fetch("UP_NEXT_LIST_ID")
    IN_PROGRESS_LIST_ID = ENV.fetch("IN_PROGRESS_LIST_ID")
    CODE_REVIEW_LIST_ID = ENV.fetch("CODE_REVIEW_LIST_ID")
    ON_STAGING_LIST_ID  = ENV.fetch("ON_STAGING_LIST_ID")
    RELEASED_LIST_ID    = ENV.fetch("RELEASED_LIST_ID")

    def self.create_access_token(code)
      HTTP.post("https://github.com/login/oauth/access_token", form: {client_id: CLIENT_ID, client_secret: CLIENT_SECRET, code: code})
    end

    def self.move_to_different_list(card_id, list_id)
      Trello.request(:put, "cards/#{card_id}/idList", value: list_id)
    end

    def self.github_checks(number)
      statuses_url = get_pull_request(number).fetch("statuses_url")

      request(:get, statuses_url).first.fetch("state")
      # the choices are "error" and "success"
    end

    def self.get_if_pull_request_has_been_merged(number)
      get_pull_request(number).fetch("merged")
    end

    def self.get_pull_request_status(number)
      get_pull_request(number).fetch("state")
    end

    # def self.all_pull_request_statuses(card_id)
    #   get_pull_request_numbers_from_trello_card(card_id).map { |number|
    #     get_pull_request_status(number)
    #   }
    # end

    def self.get_pull_request(number)
      request(:get, "repos/#{GITHUB_REPO}/pulls/#{number}")
    end

    def self.get_pull_request_number_from_trello_card(card_id)
      attachments = Trello.request(:get, "cards/#{card_id}/attachments")
      attachments
        .find_all { |i| i["url"].match %r"github.com/\S+/pull"}
        .map { |i| i["url"].split("/").last }
        .first
    end

    def self.create_webhook(callback_url, options={})
      response = request(:post, "repos/#{GITHUB_REPO}/hooks",
      {body:
        {
          name: "web",
          config: {
            url: callback_url,
            content_type: JSON
            }
          }.to_json
        })
      response.to_s
    end

    def self.request(verb, path, options={})

      uri = if path.include?("github.com/")
        Addressable::URI.parse(path)
      else
        Addressable::URI.parse(File.join(BASE_URI, path))
      end

      Revere.logger.info "Performing request: #{verb.to_s.upcase} #{uri}"

      response = HTTP.headers(
        authorization: "token #{AUTH_TOKEN}",
        Accept: "application/vnd.github.black-cat-preview+json"
      ).request(verb, uri.to_s, options)

      Revere.logger.info "Response #{response.code}, body: #{response.body}"

      if (200..299).cover? response.code
        JSON.parse(response.to_s)
      else
        raise "HTTP code is #{response.code}, response is #{response.to_s.inspect}, verb:#{verb}, uri:#{uri}"
      end

    end

    # def self.request(verb, path, options={})
    #
    #   uri = Addressable::URI.parse(File.join(BASE_URI, path))
    #
    #   Revere.logger.info "Performing request: #{verb.to_s.upcase} #{uri}"
    #
    #   response = HTTP.headers(authorization: "token #{AUTH_TOKEN}").request(verb, uri.to_s, options)
    #
    #   Revere.logger.info "Response #{response.code}, body: #{response.body}"
    #
    #   if (200..299).cover? response.code
    #     JSON.parse(response.to_s)
    #   else
    #     raise "HTTP code is #{response.code}, response is #{response.to_s.inspect}, verb:#{verb}, uri:#{uri}"
    #   end
    #
    # end

  end

end

# headers(authorization: "token #{AUTH_TOKEN}").
