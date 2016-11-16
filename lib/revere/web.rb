require 'sinatra'
require 'revere'

get '/' do
  erb :index
end

post '/create_trello_webhook' do
  Revere::Trello.create_webhook("#{request.base_url}/trello")
  # redirect to('/')
end

head '/trello' do
  200
end

post '/trello' do
  request.body.rewind
  request_payload = JSON.parse request.body.read
  card_id = request_payload.dig("action", "data", "card", "id")
  Revere.puts_trello_list_name_on_zendesk_ticket(card_id)
  200
end
