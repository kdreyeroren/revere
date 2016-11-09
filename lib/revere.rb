require 'http'
require 'awesome_print'
require 'addressable/uri'

module Revere

  API_KEY = "669b68769fb45fe714cdc1c6b82704ee"
  TOKEN = "de0255fc31f9fa57fac4ab9bdd51778c1fb500e0e079d1a880677003c0b0ee18"
  ID_MODEL = "581909190fc6f3172e2961ad"
  TRELLO_BASE_URI = "https://trello.com/1/"

  card_id = "5819193dce60a92f84a486b8"


  def trello_request(verb, path, options={})
    uri = Addressable::URI.parse(File.join(TRELLO_BASE_URI, path))
    uri.query_values = { key: API_KEY, token: TOKEN }.merge(options)
    HTTP.request(verb, uri.to_s)
  end

  def get_trello_card(card_id)
    response = trello_request(:get, "cards/#{card_id}/list")

    if response.code == 200
      body = JSON.parse(response.to_s)
      ap body
      name = body.fetch("name")
      puts name
    else
      raise "HTTP code is #{response.code}, response is #{response.to_s}"
    end

  end

  def create_trello_webhook(callback_url)
    trello_request(:post, "webhooks", callbackURL: callback_url, idModel: ID_MODEL)
  end


  ZENDESK_USER = "dev@teachable.com/token"
  ZENDESK_TOKEN = "W2JFWU3YnFMrrDzAZVfseRtOE8vxYzxCtt2hD2Bi"
  ZENDESK_BASE_URI = "https://teachable1475385865.zendesk.com/api/v2/"

  ticket_id = "7"

  def zendesk_request(verb, path, data={})
    uri = Addressable::URI.parse(File.join(ZENDESK_BASE_URI, path))
    HTTP
      .basic_auth(user: ZENDESK_USER, pass: ZENDESK_TOKEN)
      .request(verb, uri.to_s, json: data)
  end

  def get_zendesk_ticket(ticket_id)
    response = zendesk_request(:get, "tickets/#{ticket_id}.json")

    if response.code == 200
      body = JSON.parse(response.to_s)
      ap body
      name = body.fetch("name")
      puts name
    else
      raise "HTTP code is #{response.code}, response is #{response.to_s}"
    end

  end


  def create_zendesk_request
    zendesk_request(:get, )
  end

  # def create_zendesk_webhook(callback_url)
  #   zendesk_request(:post, "webhooks", callbackURL: callback_url, idModel: ID_MODEL)
  # end

end
