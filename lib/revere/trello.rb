module Revere

  module Trello

    BOARD_ID = ENV.fetch("TRELLO_BOARD_ID")
    API_KEY  = ENV.fetch("TRELLO_API_KEY")
    TOKEN    = ENV.fetch("TRELLO_TOKEN")
    BASE_URI = ENV.fetch("TRELLO_BASE_URI")
    CODE_REVIEW_ID = ENV.fetch("CODE_REVIEW_LIST_ID")

    class Card

      attr_reader :id

      def initialize(id)
        @id = id
      end

      def zendesk_ticket_ids
        attachment_request_body
          .find_all { |i| i["url"].include? "zendesk.com" }
          .map { |i| i["url"].split("/").last }
      end

      def github_links
        attachment_request_body
          .find_all { |i| i["url"].include? "github.com" }
          .map { |i| i["url"] }
      end

      def github_prs
        attachment_request_body
          .find_all { |i| i["url"].match %r{github.com.+/pull} }
          .map { |i| i["url"] }
      end

      def school_id_urls
        attachment_request_body
        .find_all { |i| i["url"].include? "staff.teachable.com" }
        .map { |i| i["url"] }
      end

      def create_school_attachment(url, name)
        Trello.request(:post, "cards/#{id}/attachments", url: url, name: name)
      end

      def list_name
        list_request.fetch("name")
      end

      def write_comment(text)
        Trello.request(:post, "cards/#{id}/actions/comments", text: text)
      end

      def comments
        comment_request_body
          .fetch("actions")
          .find_all { |i| i["type"] == "commentCard" }
          .map { |data| Comment.new(data) }
      end

      private

      def attachment_request_body
        @attachment_request_body ||= Trello.request(:get, "cards/#{id}/attachments")
      end

      def comment_request_body
        @comment_request_body ||= Trello.request(:get, "cards/#{id}", actions: "commentCard")
      end

      def list_request
        @list_request ||= Trello.request(:get, "cards/#{id}/list")
      end

    end


    class Comment

      def initialize(body)
        @body = body
      end

      def text
        @body.dig("data", "text")
      end

    end

    def self.get_card(card_id)
      Card.new(card_id)
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

    def self.move_card_to_code_review(card_id)
      request = request(:put, "cards/#{card_id}/idList", value: CODE_REVIEW_ID)
    end

    # template for trello requests
    def self.request(verb, path, options={})
      uri = Addressable::URI.parse(File.join(BASE_URI, path))
      uri.query_values = { key: API_KEY, token: TOKEN }.merge(options)

      Revere.logger.info "Performing request: #{verb.to_s.upcase} #{uri}"

      response = HTTP.request(verb, uri.to_s)

      Revere.logger.info "Response #{response.code}, body: #{response.body}"

      if (200..299).cover? response.code
        JSON.parse(response.to_s)
      else
        raise "HTTP code is #{response.code}, response is #{response.to_s.inspect}, verb:#{verb}, uri:#{uri}"
      end

    end

  end

end
