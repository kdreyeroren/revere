module Revere

  module Trello

    API_KEY         = ENV.fetch("TRELLO_API_KEY")
    TOKEN           = ENV.fetch("TRELLO_TOKEN")
    BASE_URI        = ENV.fetch("TRELLO_BASE_URI")

    # MODIFY
    # Add any board you're using to the env file, as well as the env.test file, then link them up here.
    # You can have as many boards as you want.
    BOARDS = {
      "board" => ENV.fetch("TRELLO_BOARD_ID")
    }

    def self.boards
      BOARDS
    end

    class Card

      attr_reader :id

      def initialize(id)
        @id = id
      end

      # MODIFY
      # This is a skeleton method you can modify to find links or any other attachments on a trello card.
      # You can see examples of how to use `include` and `match` below.
      def skeleton_filter_method
        attachment_request_body
          .find_all { |i| i[] } # MODIFY inside the brackets
          .map { |i| i[] }
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
        .find_all { |i| i["url"].include?("our_school_url.com") }
        .map { |i| i["url"] }
      end

      # MODIFY
      # You'll probably want to rename this method. Connects on line 87 of revere.rb #TODO
      def create_school_attachment(url, name)
        Trello.request(:post, "cards/#{id}/attachments", url: url, name: name)
      end

      def list_name
        list_request.fetch("name")
      end

      def write_comment(text)
        Trello.request(:post, "cards/#{id}/actions/comments", text: text)
      end

      def board_name
        board_request.fetch("name")
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

      def board_request
        @board_request ||= Trello.request(:get, "cards/#{id}/board")
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

    def self.fetch_board_id(board_name)
      boards.fetch(board_name.to_s)
    end

    def self.get_card(card_id)
      Card.new(card_id)
    end

    # Creates the webhook
    def self.create_webhook(callback_url, board_name)
      board_id = boards.fetch(board_name)
      response = request(:post, "webhooks", callbackURL: callback_url, idModel: board_id)
      response.to_s
    end

    # Finds all the cards on each board
    def self.find_all_cards
      boards.each_value.map { |board_id| request(:get, "boards/#{board_id}/cards/open") }
    end

    # Maps card IDs to an array
    def self.get_card_ids
      find_all_cards.flatten.compact.map do |card|
        card.fetch("id")
      end
    end

    # Finds the names of each list on all boards
    def self.get_all_lists
      boards.each_value.map { |board_id| request(:get, "boards/#{board_id}/lists?fields=name") }
        .flatten
    end

    def self.get_list_names
      get_all_lists.map { |hash| hash.fetch("name")}
    end

    # This is the template for Trello requests. You can always make more requests of your own using this method.
    def self.request(verb, path, options={})
      uri = Addressable::URI.parse(File.join(BASE_URI, path))
      uri.query_values = { key: API_KEY, token: TOKEN }.merge(options)

      Revere.logger.info "Performing request: #{verb.to_s.upcase} #{uri}"

      response = HTTP.request(verb, uri.to_s)

      Revere.logger.info "Response #{response.code}, body: #{response.body}"

      if (200..299).cover? response.code
        JSON.parse(response.to_s)
      else
        if response.to_s.include?("invalid token")
          raise "HTTP code is #{response.code}, response is #{response.to_s.inspect}, verb:#{verb}, uri:#{uri}. To fix this, sign into the Teachabot Trello account and generate a new API token. Go to this page and click token: https://trello.com/app-key. The token expires about once a month."
        else
          raise "HTTP code is #{response.code}, response is #{response.to_s.inspect}, verb:#{verb}, uri:#{uri}"
        end
      end

    end

  end

end
