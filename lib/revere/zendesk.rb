module Revere
  module Zendesk
    ZENDESK_USER = "dev@teachable.com/token"
    ZENDESK_TOKEN = "W2JFWU3YnFMrrDzAZVfseRtOE8vxYzxCtt2hD2Bi"
    ZENDESK_BASE_URI = "https://teachable1475385865.zendesk.com/api/v2/"
    TRELLO_LIST_NAME_ID = "46456408"

    def self.modify_ticket_with_trello_list(ticket_id, trello_list_name)
      response = request(:put, "tickets/#{ticket_id}.json", {
        ticket: {
          custom_fields: [{
            id: TRELLO_LIST_NAME_ID,
            value: trello_list_name
          }]
        }
      })

    end

    # template for zendesk requests
    def self.request(verb, path, data={})
      uri = Addressable::URI.parse(File.join(ZENDESK_BASE_URI, path))
      response = HTTP
        .basic_auth(user: ZENDESK_USER, pass: ZENDESK_TOKEN)
        .request(verb, uri.to_s, json: data)

        if response.code == 200
          response
        else
          raise "HTTP code is #{response.code}, response is #{response.to_s}"
        end
    end

  end
end
