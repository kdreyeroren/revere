RSpec.describe Revere do

  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  TRELLO_BASE_URI = Revere::Trello::BASE_URI
  ZENDESK_BASE_URI = Revere::Zendesk::BASE_URI
  TRELLO_BOARD_ID = Revere::Trello::BOARD_ID

  def stub_trello_attachment(card_id, body)
    stub_request(:get, %r"#{TRELLO_BASE_URI}cards/#{card_id}/attachments\?")
      .to_return(status: 200, body: body.to_json)
  end

  def stub_trello_list(card_id, body)
    stub_request(:get, %r"#{TRELLO_BASE_URI}cards/#{card_id}/list\?")
      .to_return(status: 200, body: body.to_json)
  end

  def stub_zendesk_ticket(ticket_id)
    stub_request(:put, %r"#{ZENDESK_BASE_URI}tickets/#{ticket_id}.json")
      .to_return(status: 200)
  end

  def stub_trello_board(body)
    stub_request(:get, %r"#{TRELLO_BASE_URI}boards/#{TRELLO_BOARD_ID}/cards")
      .to_return(status: 200, body: body.to_json, headers: {})
  end

  def zendesk_request(ticket_id, list_name, github_url)
    a_request(:put, %r"#{ZENDESK_BASE_URI}tickets/#{ticket_id}.json")
      .with(body: {ticket: {custom_fields: [{id: "46456408", value: list_name}, {id: "47614828", value: github_url}]}}.to_json)
  end


  it "creates a trello webhook" do
    allow(Revere::Trello).to receive(:create_webhook).and_return("hello")

    post "/create_trello_webhook"

    expect(last_response.status).to eq 200
    expect(last_response.body).to include "hello"
    expect(Revere::Trello).to have_received(:create_webhook).with("http://example.org/trello")
  end

  it "creates a trello webhook with a stub" do
    stub_request(:post, %r{#{TRELLO_BASE_URI}webhooks\?callbackURL=http://example.org/trello})
      .to_return(status: 200, body: "{}", headers: {})

    post "/create_trello_webhook"

    expect(last_response.status).to eq 200
  end

  it "does everything" do
    stub_trello_attachment("trello_card_id", [{url: "zendesk.com/ticket/1337"}, {url: "github.com/issues/1337"}])
    stub_trello_list("trello_card_id", {name: "list name"})
    stub_zendesk_ticket("1337")

    post "/trello", {action: {data: {card: {id: "trello_card_id"}}}}.to_json

    expect(zendesk_request("1337", "list_name", "github.com/issues/1337")).to have_been_made
  end

  it "handles multiple zendesk attachments" do
    stub_trello_attachment("trello_card_id", [{url: "zendesk.com/ticket/1337"}, {url: "zendesk.com/ticket/666"}])
    stub_trello_list("trello_card_id", {name: "list name"})
    stub_zendesk_ticket("1337")
    stub_zendesk_ticket("666")

    post "/trello", {action: {data: {card: {id: "trello_card_id"}}}}.to_json

    expect(zendesk_request("1337", "list_name", "")).to have_been_made
    expect(zendesk_request("666", "list_name", "")).to have_been_made
  end

  it "handles other types of attachments" do
    stub_trello_attachment("trello_card_id", [{url: "boston.com/imwithstupid"}])
    stub_trello_list("trello_card_id", {name: "list name"})

    post "/trello", {action: {data: {card: {id: "trello_card_id"}}}}.to_json

    expect(a_request(:put, %r"#{ZENDESK_BASE_URI}tickets/1337.json")).to_not have_been_made
  end

  it "syncs all the cards" do
    stub_trello_board([{id: 1234}])
    stub_trello_attachment("1234", [{url: "zendesk.com/ticket/1337"}])
    stub_trello_list("1234", {name: "list name"})
    stub_zendesk_ticket("1337")

    Revere.sync_multiple_tickets

    expect(zendesk_request("1337", "list_name", "")).to have_been_made
  end

  it "does not crash when trying to update a closed ticket" do
    stub_request(:put, %r"#{ZENDESK_BASE_URI}tickets/1234.json")
      .to_return(status: 422, body: {"error":"RecordInvalid","description":"Record validation errors","details":{"status":[{"description":"Status: closed prevents ticket update"}]}}.to_json)

      Revere::Zendesk.update_ticket("1234", trello_list_name: "list name")

      # no error
  end


end
