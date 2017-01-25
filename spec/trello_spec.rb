RSpec.describe Revere do

  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  TRELLO_BASE_URI  = Revere::Trello::BASE_URI
  ZENDESK_BASE_URI = Revere::Zendesk::BASE_URI
  BOARD_ID_DEV_Q   = Revere::Trello::BOARD_ID_DEV_Q
  BOARD_ID_SPRINT  = Revere::Trello::BOARD_ID_SPRINT

  # Trello
  def stub_trello_attachment(card_id, body)
    stub_request(:get, %r"#{TRELLO_BASE_URI}cards/#{card_id}/attachments\?")
      .to_return(status: 200, body: body.to_json)
  end

  def stub_trello_posted_attachments(card_id)
    stub_request(:post, %r"#{TRELLO_BASE_URI}cards/#{card_id}/attachments\?")
      .to_return(status: 200, body: "{}")
  end

  def stub_trello_comment_card(card_id)
    stub_request(:get, %r"#{TRELLO_BASE_URI}cards/#{card_id}\?actions=commentCard")
      .to_return(body: {"actions" => []}.to_json)
  end

  def stub_trello_posted_comment(card_id)
    stub_request(:post, %r"#{TRELLO_BASE_URI}cards/#{card_id}/actions/comments")
      .to_return(status: 200, body: "{}")
  end

  # Github
  def stub_github_pr(number)
    stub_request(:get, %r"#{GITHUB_BASE_URI}repos/#{GITHUB_REPO}/pulls/#{number}")
  end

  it "creates a trello webhook for dev questions board" do
    allow(Revere::Trello).to receive(:create_webhook_dev_q).and_return("hello")

    post "/create_trello_webhook_dev_q"

    expect(last_response.status).to eq 200
    expect(last_response.body).to include "hello"
    expect(Revere::Trello).to have_received(:create_webhook_dev_q).with("http://example.org/trello")
  end

  it "creates a trello webhook for dev q with a stub" do
    stub_request(:post, %r{#{TRELLO_BASE_URI}webhooks\?callbackURL=http://example.org/trello})
      .to_return(status: 200, body: "{}", headers: {})

    post "/create_trello_webhook_dev_q"

    expect(last_response.status).to eq 200
  end

  it "creates a trello webhook for sprint board" do
    allow(Revere::Trello).to receive(:create_webhook_sprint).and_return("hello")

    post "/create_trello_webhook_sprint"

    expect(last_response.status).to eq 200
    expect(last_response.body).to include "hello"
    expect(Revere::Trello).to have_received(:create_webhook_sprint).with("http://example.org/trello")
  end

  it "creates a trello webhook for sprint with a stub" do
    stub_request(:post, %r{#{TRELLO_BASE_URI}webhooks\?callbackURL=http://example.org/trello})
      .to_return(status: 200, body: "{}", headers: {})

    post "/create_trello_webhook_sprint"

    expect(last_response.status).to eq 200
  end


  it "puts the school id in a trello attachment" do
    card_id = "trello_card_id"
    ticket_id = "zendesk_ticket_id"
    school_id = "12345"

    stub_trello_attachment(card_id, [{url: "zendesk.com/ticket/#{ticket_id}"}])
    stub_trello_posted_attachments(card_id)

    Revere.update_trello_card(Revere::Trello::Card.new(card_id), school_id)

    expect(a_request(:post, %r"#{TRELLO_BASE_URI}cards/trello_card_id/attachments").with(query: {key: Revere::Trello::API_KEY, token: Revere::Trello::TOKEN, url: "https://staff.teachable.com/schools/12345", name: "School ID: #{school_id}"})).to have_been_made
  end

  it "doesn't put the school id in the card if it's already there" do
    card_id = "trello_card_id"
    ticket_id = "zendesk_ticket_id"
    school_id = "45678"

    stub_trello_attachment(card_id, [{url: "zendesk.com/ticket/#{ticket_id}"}, {url: "https://staff.teachable.com/schools/#{school_id}"}])

    Revere.update_trello_card(Revere::Trello::Card.new(card_id), school_id)

    expect(a_request(:post, %r"#{TRELLO_BASE_URI}cards/trello_card_id/attachments")).to_not have_been_made
  end

  it "does nothing if there's no school ID" do
    card_id = "trello_card_id"
    ticket_id = "zendesk_ticket_id"

    stub_trello_comment_card(card_id)
    stub_request(:get, %r"#{ZENDESK_BASE_URI}tickets/#{ticket_id}.json")
      .to_return(body: {ticket: {custom_fields: [{id: 45144647, value: ""}]}}.to_json)
    stub_trello_posted_comment(card_id)

    Revere.update_trello_card(Revere::Trello::Card.new(card_id), "")

    expect(a_request(:post, %r"#{TRELLO_BASE_URI}cards/trello_card_id/actions/comments").with(query: {key: Revere::Trello::API_KEY, token: Revere::Trello::TOKEN, text: "School ID: 12345"})).to_not have_been_made
  end

end
