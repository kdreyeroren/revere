require "sinatra"

use Raven::Rack

before do
  env["rack.logger"] = Revere.logger
end

get "/" do
  erb :index
end

post "/create_trello_webhook/:board_name" do |board_name|
  Revere::Trello.create_webhook("#{request.base_url}/trello", board_name)
end

head "/trello" do
  200
end

post "/trello" do
  request.body.rewind
  request_payload = JSON.parse request.body.read
  logger.info("payload:#{request_payload.inspect}")
  card_id = request_payload.dig("action", "data", "card", "id")
  Revere.sync_single_ticket(card_id) if card_id
  200
end

post "/create_github_webhook" do
  Revere::Github.create_webhook("#{request.base_url}/github")
end

get "/oauth" do
  Revere::Github.create_access_token(params[:code]).to_s
end

get "/github_root.json" do
  content_type :json
  Revere::Github.get_root.to_json
end
