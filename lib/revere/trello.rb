module Revere

  module Trello

    BOARD_ID = ENV.fetch("TRELLO_BOARD_ID")
    API_KEY = ENV.fetch("TRELLO_API_KEY")
    TOKEN = ENV.fetch("TRELLO_TOKEN")
    BASE_URI = ENV.fetch("TRELLO_BASE_URI")

    class Card

      def initialize(body)
        @body = body
      end

      def zendesk_ticket_ids
        zendesk_attachments = @body.find_all { |i| i["url"].include? "zendesk.com" }
        zendesk_attachments.map { |i| i["url"].split("/").last}
      end

      def github_links
        github_attachments = @body.find_all { |i| i["url"].include? "github.com" }
        github_attachments.map { |i| i["url"] }
      end

    end

    def self.get_card(card_id)
      body = request(:get, "cards/#{card_id}/attachments")
      Card.new(body)
    end

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

    def self.get_github_links_from_trello_attachments(card_id)

      body = request(:get, "cards/#{card_id}/attachments")

      github_attachments = body.find_all { |i| i["url"].include? "github.com" }
      github_attachments.map { |i| i["url"] }

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

      Revere.logger.info "Performing request: #{verb.to_s.upcase} #{uri}"

      response = HTTP.request(verb, uri.to_s)

      Revere.logger.info "Response #{response.code}, body: #{response.body}"

      if response.code == 200
        JSON.parse(response.to_s)
      else
        raise "HTTP code is #{response.code}, response is #{response.to_s.inspect}, verb:#{verb}, uri:#{uri}"
      end

    end

  end

end
