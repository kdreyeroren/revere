require 'http'
require 'awesome_print'
require 'addressable/uri'
require 'verbose_hash_fetch'

module Revere

  API_KEY = "c0adc43d9655dfd60edf14ff73521625"
  TOKEN = "ac073e4208909bd457b5cec7954235d63d0e089f682516c8fe0c86b8661ecb2e"
  ID_MODEL = "5817c317669034928804c17d"
  TRELLO_BASE_URI = "https://trello.com/1/"

  card_id = "5819193dce60a92f84a486b8"

  # template for trello requests
  def self.trello_request(verb, path, options={})
    uri = Addressable::URI.parse(File.join(TRELLO_BASE_URI, path))
    uri.query_values = { key: API_KEY, token: TOKEN }.merge(options)
    HTTP.request(verb, uri.to_s)
  end

  # pulls out the list name
  def self.get_trello_list_name(card_id)
    response = trello_request(:get, "cards/#{card_id}/list")

    if response.code == 200
      body = JSON.parse(response.to_s)
      list_id = body.fetch("name")
    else
      raise "HTTP code is #{response.code}, response is #{response.to_s}"
    end

  end

  def self.get_zendesk_ticket_ids_from_trello_attachments(card_id)
    response = trello_request(:get, "cards/#{card_id}/attachments")

    if response.code == 200
      body = JSON.parse(response.to_s)
      zendesk_attachments = body.find_all { |i| i["url"].include? "zendesk.com" }
      zendesk_ticket_ids = zendesk_attachments.map { |i| i["url"].split("/").last}

    else
      raise "HTTP code is #{response.code}, response is #{response.to_s}"
    end

  end

  # triggers the webhook
  def self.create_trello_webhook(callback_url)
    trello_request(:post, "webhooks", callbackURL: callback_url, idModel: ID_MODEL)
  end


  ZENDESK_USER = "dev@teachable.com/token"
  ZENDESK_TOKEN = "W2JFWU3YnFMrrDzAZVfseRtOE8vxYzxCtt2hD2Bi"
  ZENDESK_BASE_URI = "https://teachable1475385865.zendesk.com/api/v2/"

  # ticket_id = "468"

  # template for zendesk requests
  def self.zendesk_request(verb, path, data={})
    uri = Addressable::URI.parse(File.join(ZENDESK_BASE_URI, path))
    HTTP
      .basic_auth(user: ZENDESK_USER, pass: ZENDESK_TOKEN)
      .request(verb, uri.to_s, json: data)
  end

  # gets a zendesk ticket
  def self.get_zendesk_ticket(ticket_id)
    response = zendesk_request(:get, "tickets/#{ticket_id}.json")

    if response.code == 200
      response.to_s
    else
      raise "HTTP code is #{response.code}, response is #{response.to_s}"
    end

  end

  # creates a zendesk ticket
  def self.create_zendesk_ticket
    zendesk_request(:post, "tickets.json", {
      ticket: {
        subject: "Test ticket 3!",
        comment: {
          body: "There is not enough chocolate in the world."
        }
      }
    })
  end

  # modifies a zendesk ticket
  def self.modify_zendesk_ticket(ticket_id)
    response = zendesk_request(:put, "tickets/#{ticket_id}.json", {
      ticket: {
        custom_fields: [{
          id: "46456408",
          value: "done"
        }]
      }
    })

    if response.code == 200
      response
    else
      raise "HTTP code is #{response.code}, response is #{response.to_s}"
    end

  end

  def self.modify_zendesk_ticket_with_trello_list(ticket_id, trello_list_name)
    response = zendesk_request(:put, "tickets/#{ticket_id}.json", {
      ticket: {
        custom_fields: [{
          id: "46456408",
          value: trello_list_name
        }]
      }
    })

    if response.code == 200
      response
    else
      raise "HTTP code is #{response.code}, response is #{response.to_s}"
    end

  end

  def self.puts_trello_list_name_on_zendesk_ticket(card_id)
    # step 1. Find zendesk ticket ids
    ticket_ids = get_zendesk_ticket_ids_from_trello_attachments(card_id)
    # step 2. Find list name
    trello_list_name = get_trello_list_name(card_id)
    # step 3. Send that name to Zendesk tickets
    ticket_ids.each do |ticket_id|
      modify_zendesk_ticket_with_trello_list(ticket_id, trello_list_name)
    end
  end


end
