require 'sinatra'

use Raven::Rack

before do
  env["rack.logger"] = Revere.logger
end

get '/' do
  erb :index
end

post '/create_trello_webhook' do
  Revere::Trello.create_webhook("#{request.base_url}/trello")
end

head '/trello' do
  200
end

post '/trello' do
  request.body.rewind
  request_payload = JSON.parse request.body.read
  logger.info("payload:#{request_payload.inspect}")
  card_id = request_payload.dig("action", "data", "card", "id")
  Revere.sync_single_ticket(card_id) if card_id
  200
end
