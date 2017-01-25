RSpec.describe Revere do

  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  TRELLO_BASE_URI  = Revere::Trello::BASE_URI
  ZENDESK_BASE_URI = Revere::Zendesk::BASE_URI
  BOARD_ID_DEV_Q   = Revere::Trello::BOARD_ID_DEV_Q
  BOARD_ID_SPRINT  = Revere::Trello::BOARD_ID_SPRINT

  # Zendesk
  def stub_zendesk_ticket(ticket_id)
    stub_request(:put, %r"#{ZENDESK_BASE_URI}tickets/#{ticket_id}.json")
      .to_return(status: 200)
  end

  def stub_zendesk_ticket_with_school(ticket_id, school_id)
    stub_request(:get, %r"#{ZENDESK_BASE_URI}tickets/#{ticket_id}.json")
      .to_return(body: {ticket: {custom_fields: [{id: 45144647, value: "#{school_id}"}]}}.to_json)
  end

  def zendesk_request(ticket_id, list_name, board_name, github_url)
    a_request(:put, %r"#{ZENDESK_BASE_URI}tickets/#{ticket_id}.json")
      .with(body: {ticket: {custom_fields: [{id: "46456408", value: list_name}, {id: "52244747", value: board_name}, {id: "47614828", value: github_url}]}}.to_json)
  end

  # Trello
  def stub_trello_attachment(card_id, body)
    stub_request(:get, %r"#{TRELLO_BASE_URI}cards/#{card_id}/attachments\?")
      .to_return(status: 200, body: body.to_json)
  end

  def stub_trello_list(card_id, body)
    stub_request(:get, %r"#{TRELLO_BASE_URI}cards/#{card_id}/list\?")
      .to_return(status: 200, body: body.to_json)
  end

  def stub_trello_posted_attachments(card_id)
    stub_request(:post, %r"#{TRELLO_BASE_URI}cards/#{card_id}/attachments\?")
      .to_return(status: 200, body: "{}")
  end

  def stub_trello_board_dev_q(card_id, body)
    stub_request(:get, %r"#{TRELLO_BASE_URI}boards/#{BOARD_ID_DEV_Q}/cards").to_return(status: 200, body: body.to_json)
  end

  def stub_trello_board_sprint(card_id, body)
    stub_request(:get, %r"#{TRELLO_BASE_URI}boards/#{BOARD_ID_SPRINT}/cards").to_return(status: 200, body: body.to_json)
  end

  def stub_trello_board_with_card_id(card_id, body)
    stub_request(:get, %r"#{TRELLO_BASE_URI}cards/#{card_id}/board").to_return(status: 200, body: body.to_json)
  end


  # Github
  def stub_github_pulls
    stub_request(:get, %r"#{GITHUB_BASE_URI}repos/#{GITHUB_REPO}/pulls/$")
  end

  def stub_github_pr(number)
    stub_request(:get, %r"#{GITHUB_BASE_URI}repos/#{GITHUB_REPO}/pulls/#{number}")
  end

  def stub_github_status_to_cr(number)
    stub_github_pr(number).to_return(status: 200, body: {state: "open", statuses_url: "http://github.com/blah", merged: false}.to_json)
    stub_request(:get, "http://github.com/blah").to_return(body: [{state: "success"}].to_json)
  end

  def stub_github_status_to_staging(number)
    stub_github_pr(number).to_return(status: 200, body: {state: "closed", statuses_url: "http://github.com/blah", merged: true}.to_json)
    stub_request(:get, "http://github.com/blah").to_return(body: [{state: "success"}].to_json)
  end

  def stub_github_status_not_to_cr(number)
    stub_github_pr(number).to_return(status: 200, body: {state: "closed", statuses_url: "http://github.com/blah", merged: false}.to_json)
    stub_request(:get, "http://github.com/blah").to_return(body: [{state: "success"}].to_json)
  end

  def stub_github_status_not_to_cr2(number)
    stub_github_pr(number).to_return(status: 200, body: {state: "closed", statuses_url: "http://github.com/blah", merged: true}.to_json)
    stub_request(:get, "http://github.com/blah").to_return(body: [{state: "success"}].to_json)
  end

  def stub_github_status_not_to_staging(number)
    stub_github_pr(number).to_return(status: 200, body: {state: "closed", statuses_url: "http://github.com/blah", merged: true}.to_json)
    stub_request(:get, "http://github.com/blah").to_return(body: [{state: "error"}].to_json)
  end


  it "updates single zendesk ticket" do
    ticket_id = "1337"
    school_id = "12345"
    card_id = "trello_card_id"
    list_name = "list_name"
    board_name = "board_name"
    stub_trello_attachment(card_id, [{url: "zendesk.com/ticket/#{ticket_id}"}, {url: "github.com/issues/#{ticket_id}"}])
    stub_trello_list(card_id, {name: list_name})
    stub_trello_board_with_card_id(card_id, {name: board_name})
    stub_zendesk_ticket(ticket_id)
    stub_zendesk_ticket_with_school(ticket_id, school_id)
    stub_trello_posted_attachments(card_id)

    post "/trello", {action: {data: {card: {id: card_id}}}}.to_json

    expect(zendesk_request(ticket_id, list_name, board_name, "github.com/issues/#{ticket_id}")).to have_been_made
  end

  it "handles multiple zendesk attachments" do
    card_id = "trello_card_id"
    ticket_id_1 = "1337"
    ticket_id_2 = "666"
    school_id = "12345"
    list_name = "list_name"
    board_name = "board_name"
    stub_trello_attachment(card_id, [{url: "zendesk.com/ticket/#{ticket_id_1}"}, {url: "zendesk.com/ticket/#{ticket_id_2}"}])
    stub_trello_list(card_id, {name: list_name})
    stub_trello_board_with_card_id(card_id, {name: board_name})
    stub_zendesk_ticket(ticket_id_1)
    stub_zendesk_ticket(ticket_id_2)
    stub_zendesk_ticket_with_school(ticket_id_1, school_id)
    stub_zendesk_ticket_with_school(ticket_id_2, school_id)
    stub_trello_posted_attachments(card_id)

    post "/trello", {action: {data: {card: {id: card_id}}}}.to_json

    expect(zendesk_request(ticket_id_1, list_name, board_name, "")).to have_been_made
    expect(zendesk_request(ticket_id_2, list_name, board_name, "")).to have_been_made
  end

  it "handles multiple github links" do
    card_id = "trello_card_id"
    ticket_id = "1337"
    list_name = "list name"
    board_name = "board_name"
    school_id = "12345"
    stub_trello_attachment(card_id, [{url: "zendesk.com/ticket/#{ticket_id}"}, {url: "github.com/issue/4242"}, {url: "github.com/issue/5"}])
    stub_trello_list(card_id, {name: list_name})
    stub_trello_board_with_card_id(card_id, {name: board_name})
    stub_zendesk_ticket(ticket_id)
    stub_zendesk_ticket_with_school(ticket_id, school_id)
    stub_trello_posted_attachments(card_id)

    post "/trello", {action: {data: {card: {id: card_id}}}}.to_json

    # why doesn't using list_name instead of "list_name" work here??
    expect(zendesk_request(ticket_id, "list_name", "board_name", "github.com/issue/4242\ngithub.com/issue/5")).to have_been_made
  end

  it "handles other types of attachments" do
    stub_trello_attachment("trello_card_id", [{url: "boston.com/imwithstupid"}])
    stub_trello_list("trello_card_id", {name: "list name"})

    post "/trello", {action: {data: {card: {id: "trello_card_id"}}}}.to_json

    expect(a_request(:put, %r"#{ZENDESK_BASE_URI}tickets/1337.json")).to_not have_been_made
  end

  it "syncs all the cards" do
    card_id = "trello_card_id"
    ticket_id = "1337"
    list_name = "list name"
    board_name = "board_name"
    # stub_trello_board_with_card_id(card_id, [{id: board_id}])
    stub_trello_board_dev_q(card_id, [{id: card_id}])
    stub_trello_board_sprint(card_id, [])
    # stub_trello_attachment(board_id, [{url: "zendesk.com/ticket/#{ticket_id}"}])
    stub_trello_attachment(card_id, [{url: "zendesk.com/ticket/#{ticket_id}"}])
    stub_trello_list(card_id, {name: list_name})
    stub_trello_board_with_card_id(card_id, {name: board_name})
    stub_zendesk_ticket(ticket_id)
    stub_trello_posted_attachments(card_id)
    stub_request(:get, %r"#{ZENDESK_BASE_URI}tickets/#{ticket_id}.json")
       .to_return(body: {ticket: {custom_fields: [{id: 45144647, value: "12345"}]}}.to_json)

    Revere.sync_multiple_tickets

    expect(zendesk_request("1337", "list_name", "board_name", "")).to have_been_made
  end

  it "does not crash when trying to update a closed ticket" do

    stub_request(:put, %r"#{ZENDESK_BASE_URI}tickets/1234.json")
      .to_return(status: 422, body: {"error":"RecordInvalid","description":"Record validation errors","details":{"status":[{"description":"Status: closed prevents ticket update"}]}}.to_json)

    Revere::Zendesk.update_ticket("1234", trello_list_name: "list name")

    # no error
  end

end
