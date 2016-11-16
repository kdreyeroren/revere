module Revere

  module Trello

    API_KEY = "c0adc43d9655dfd60edf14ff73521625"
    TOKEN = "ac073e4208909bd457b5cec7954235d63d0e089f682516c8fe0c86b8661ecb2e"
    ID_MODEL = "5817c317669034928804c17d"
    TRELLO_BASE_URI = "https://trello.com/1/"

    # pulls out the list name
    def self.get_list_name(card_id)
      body = request(:get, "cards/#{card_id}/list")
      list_id = body.fetch("name")
    end

    def self.get_zendesk_ticket_ids_from_trello_attachments(card_id)

      body = request(:get, "cards/#{card_id}/attachments")

      zendesk_attachments = body.find_all { |i| i["url"].include? "zendesk.com" }
      zendesk_ticket_ids = zendesk_attachments.map { |i| i["url"].split("/").last}

    end

    # triggers the webhook
    def self.create_webhook(callback_url)
      response = request(:post, "webhooks", callbackURL: callback_url, idModel: ID_MODEL)
      response.to_s
    end

    # template for trello requests
    def self.request(verb, path, options={})
      uri = Addressable::URI.parse(File.join(TRELLO_BASE_URI, path))
      uri.query_values = { key: API_KEY, token: TOKEN }.merge(options)
      response = HTTP.request(verb, uri.to_s)

      if response.code == 200
        body = JSON.parse(response.to_s)
      else
        raise "HTTP code is #{response.code}, response is #{response.to_s}"
      end

    end

  end

end
