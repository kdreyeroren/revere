require 'sinatra'
require './lib/revere'

get '/' do
  erb :index
end

post '/create_trello_webhook' do
  Revere.create_trello_webhook("#{request.base_url}/trello")
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

get '/get_webhooks' do
  Revere.get_webhooks.to_s
end


post '/create_zendesk_ticket' do
  Revere.create_zendesk_ticket
  redirect to('/')
end

get '/get_zendesk_ticket' do
  content_type :json
  Revere.get_zendesk_ticket("468")
end

post '/modify_zendesk_ticket' do
  Revere.modify_zendesk_ticket("468")
end

# get '/get_trello_list' do
#   Revere.get_trello_list()
# end

get '/get_trello_card' do
  Revere.get_trello_card("581a33404c42db4d16dde346")
end

get '/get_trello_list_name' do
  Revere.get_trello_list_name("581a33404c42db4d16dde346")
end

get '/get_trello_attachment' do
  Revere.get_trello_attachment("5829e45e3772201e9ea87d4e").inspect
end

post '/puts_trello_list_name_on_zendesk_ticket' do
  Revere.puts_trello_list_name_on_zendesk_ticket("5829e45e3772201e9ea87d4e"
  )
end
