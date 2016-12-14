module Revere

  module Github

    # TODO: figure out authentication. don't cry.

    BASE_URI = ENV.fetch("GITHUB_BASE_URI")
    CLIENT_ID = ENV.fetch("GITHUB_CLIENT_ID")
    CLIENT_SECRET = ENV.fetch("GITHUB_CLIENT_SECRET")
    AUTH_TOKEN = ENV.fetch("GITHUB_AUTH_TOKEN")


    def self.create_access_token(code)
      HTTP.post("https://github.com/login/oauth/access_token", form: {client_id: CLIENT_ID, client_secret: CLIENT_SECRET, code: code})
    end

    def self.get_pull_request_status(number)
      response = request(:get, "repos/UseFedora/revere/pulls/#{number}")
      response.fetch("state")
    end

    def self.create_webhook(callback_url, options={})
      response = request(:post, "repos/UseFedora/revere/hooks",
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

      uri = Addressable::URI.parse(File.join(BASE_URI, path))

      Revere.logger.info "Performing request: #{verb.to_s.upcase} #{uri}"

      response = HTTP.headers(authorization: "token #{AUTH_TOKEN}").request(verb, uri.to_s, options)

      Revere.logger.info "Response #{response.code}, body: #{response.body}"

      if (200..299).cover? response.code
        JSON.parse(response.to_s)
      else
        raise "HTTP code is #{response.code}, response is #{response.to_s.inspect}, verb:#{verb}, uri:#{uri}"
      end

    end

  end

end

# headers(authorization: "token #{AUTH_TOKEN}").
