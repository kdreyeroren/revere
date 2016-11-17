RSpec.describe Revere do

  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  it "creates a trello webhook" do
    allow(Revere::Trello).to receive(:create_webhook).and_return("hello")

    post "/create_trello_webhook"

    expect(last_response.status).to eq 200
    expect(last_response.body).to include "hello"
    expect(Revere::Trello).to have_received(:create_webhook).with("http://example.org/trello")
  end

  it "creates a trello webhook with a stub" do
    stub_request(:post, %r{https://trello.com/1/webhooks\?callbackURL=http://example.org/trello})
      .to_return(status: 200, body: "{}", headers: {})

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

  it "handles multiple zendesk attachments" do
    stub_request(:get, %r"https://trello.com/1/cards/some%20id/attachments\?")
      .to_return(status: 200, body: [{url: "zendesk.com/ticket/1337"}, {url: "zendesk.com/ticket/666"}].to_json)
    stub_request(:get, %r"https://trello.com/1/cards/some%20id/list\?")
      .to_return(status: 200, body: {name: "list name"}.to_json)
    stub_request(:put, %r"https://teachable1475385865.zendesk.com/api/v2/tickets/1337.json")
      .to_return(status: 200)
    stub_request(:put, %r"https://teachable1475385865.zendesk.com/api/v2/tickets/666.json")
      .to_return(status: 200)

    post "/trello", {action: {data: {card: {id: "some id"}}}}.to_json

    expect(a_request(:put, %r"https://teachable1475385865.zendesk.com/api/v2/tickets/1337.json")
    .with(body: {ticket: {custom_fields: [{id: "46456408", value: "list name"}]}}.to_json))
    .to have_been_made
    expect(a_request(:put, %r"https://teachable1475385865.zendesk.com/api/v2/tickets/666.json")
      .with(body: {ticket: {custom_fields: [{id: "46456408", value: "list name"}]}}.to_json))
  end

  it "handles other types of attachments" do
    stub_request(:get, %r"https://trello.com/1/cards/some%20id/attachments\?")
      .to_return(status: 200, body: [{url: "boston.com/imwithstupid"}].to_json)
    stub_request(:get, %r"https://trello.com/1/cards/some%20id/list\?")
      .to_return(status: 200, body: {name: "list name"}.to_json)

    post "/trello", {action: {data: {card: {id: "some id"}}}}.to_json

    expect(a_request(:put, %r"https://teachable1475385865.zendesk.com/api/v2/tickets/1337.json")).to_not have_been_made
  end

  it "syncs all the cards" do
    stub_request(:get, %r"https://trello.com/1/boards/5817c317669034928804c17d/cards")
      .to_return(status: 200, body: [{id: 1234}].to_json, headers: {})
    stub_request(:get, %r"https://trello.com/1/cards/1234/attachments\?")
      .to_return(status: 200, body: [{url: "zendesk.com/ticket/1337"}].to_json)
    stub_request(:get, %r"https://trello.com/1/cards/1234/list\?")
      .to_return(status: 200, body: {name: "list name"}.to_json)
    stub_request(:put, %r"https://teachable1475385865.zendesk.com/api/v2/tickets/1337.json")
      .to_return(status: 200)

    Revere.sync_tickets

    expect(a_request(:put, %r"https://teachable1475385865.zendesk.com/api/v2/tickets/1337.json")
      .with(body: {ticket: {custom_fields: [{id: "46456408", value: "list name"}]}}.to_json))
      .to have_been_made
  end

end
