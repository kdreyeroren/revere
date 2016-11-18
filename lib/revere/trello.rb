module Revere

  module Trello

    BOARD_ID = ENV.fetch("TRELLO_BOARD_ID")
    API_KEY = ENV.fetch("TRELLO_API_KEY")
    TOKEN = ENV.fetch("TRELLO_TOKEN")
    BASE_URI = ENV.fetch("TRELLO_BASE_URI")

    # pulls out the list name
    def self.get_list_name(card_id)
      body = request(:get, "cards/#{card_id}/list")
      body.fetch("name")
    end

    def self.get_zendesk_ticket_ids_from_trello_attachments(card_id)

      body = request(:get, "cards/#{card_id}/attachments")

      zendesk_attachments = body.find_all { |i| i["url"].include? "zendesk.com" }
      zendesk_attachments.map { |i| i["url"].split("/").last}

    end

    # triggers the webhook
    def self.create_webhook(callback_url)
      response = request(:post, "webhooks", callbackURL: callback_url, idModel: BOARD_ID)
      response.to_s
    end

    def self.find_all_cards
      request(:get, "boards/#{BOARD_ID}/cards")
    end

    def self.get_card_ids
      find_all_cards.map do |card|
        card.fetch("id")
      end
    end

    # template for trello requests
    def self.request(verb, path, options={})
      uri = Addressable::URI.parse(File.join(BASE_URI, path))
      uri.query_values = { key: API_KEY, token: TOKEN }.merge(options)
      response = HTTP.request(verb, uri.to_s)

      if response.code == 200
        JSON.parse(response.to_s)
      else
        raise "HTTP code is #{response.code}, response is #{response.to_s.inspect}, verb:#{verb}, uri:#{uri}, data:#{data.inspect}"
      end

    end

  end

end
