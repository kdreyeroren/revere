RSpec.describe Revere do

  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  it "creates a trello webhook" do
    allow(Revere).to receive(:create_trello_webhook).and_return("hello")
    post "/create_trello_webhook"
    expect(last_response.status).to eq 200
    expect(last_response.body).to include "hello"
    expect(Revere).to have_received(:create_trello_webhook).with("http://example.org/trello")
  end

  it "creates a trello webhook with a stub" do
    stub_request(:post, %r{https://trello.com/1/webhooks\?callbackURL=http://example.org/trello})
      .to_return(status: 200, body: "", headers: {})
    post "/create_trello_webhook"
    expect(last_response.status).to eq 200
  end

  it "does everything" do
    stub_request(:get, %r"https://trello.com/1/cards/some%20id/attachments\?")
      .to_return(status: 200, body: [{url: "zendesk.com/ticket/1337"}].to_json)
    stub_request(:get, %r"https://trello.com/1/cards/some%20id/list\?")
      .to_return(status: 200, body: {name: "list name"}.to_json)
    stub_request(:put, %r"https://teachable1475385865.zendesk.com/api/v2/tickets/1337.json")
      .to_return(status: 200)
    post "/trello", {action: {data: {card: {id: "some id"}}}}.to_json
    expect(a_request(:put, %r"https://teachable1475385865.zendesk.com/api/v2/tickets/1337.json")
    .with(body: {ticket: {custom_fields: [{id: "46456408", value: "list name"}]}}.to_json))
    .to have_been_made
  end

end
