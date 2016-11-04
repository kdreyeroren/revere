require 'http'
require 'awesome_print'
require 'addressable/uri'

module Revere

  API_KEY = "669b68769fb45fe714cdc1c6b82704ee"
  TOKEN = "de0255fc31f9fa57fac4ab9bdd51778c1fb500e0e079d1a880677003c0b0ee18"
  ID_MODEL = "581909190fc6f3172e2961ad"

  def get_trello_card
    url = "https://api.trello.com/1/cards/5819193dce60a92f84a486b8/list?key=#{API_KEY}&token=#{TOKEN}"
    response = HTTP.get(url)

    # Later - have this app refresh every 10 minutes in case it misses a webhook

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
    uri = Addressable::URI.parse("https://trello.com/1/webhooks")
    uri.query_values = { key: API_KEY, token: TOKEN, callbackURL: callback_url, idModel: ID_MODEL}
    HTTP.post(uri.to_s)
  end

end
