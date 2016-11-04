require 'sinatra'
require './lib/revere'

get '/' do
  erb :index
end

post '/create_trello_webhook' do
  create_trello_webhook("#{request.base_url}/trello")
  redirect to('/')
end

head '/trello' do
  200
end

post '/trello' do
  200
end
