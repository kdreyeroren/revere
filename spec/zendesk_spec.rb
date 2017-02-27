RSpec.describe Revere do

  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  # Zendesk
  def stub_zendesk(verb, path, body = {}, status = 200)
    stub_request(verb, %r"#{Revere::Zendesk::BASE_URI}#{path}")
      .to_return(status: status, body: body.to_json)
  end

  def stub_zendesk_ticket(ticket_id)
    stub_zendesk(:put, "tickets/#{ticket_id}.json")
  end

  def stub_zendesk_ticket_with_school(ticket_id, school_id, body)
    stub_zendesk(:get, "tickets/#{ticket_id}.json", body)
  end

  def stub_trello_list_in_zendesk(custom_field_options)
    stub_zendesk(:put, "ticket_fields/#{Revere::Zendesk.field_id("trello_list_name")}.json", { "ticket_field": { "custom_field_options": custom_field_options}})
  end

  def zendesk_request(ticket_id, list_name, board_name, github_url)
    a_request(:put, %r"#{Revere::Zendesk::BASE_URI}tickets/#{ticket_id}.json")
      .with(body: {ticket: {custom_fields: [{id: Revere::Zendesk.field_id("trello_list_name"), value: list_name}, {id: Revere::Zendesk.field_id("trello_board_name"), value: board_name}, {id: Revere::Zendesk.field_id("github_links"), value: github_url}]}}.to_json)
  end


  # Trello
  def stub_trello(verb, path, body = {}, status = 200)
    stub_request(verb, %r"#{Revere::Trello::BASE_URI}#{path}")
      .to_return(status: status, body: body.to_json)
  end

  def stub_trello_attachment(card_id, body)
    stub_trello(:get, "cards/#{card_id}/attachments?", body)
  end

  def stub_trello_list(card_id, body)
    stub_trello(:get, "cards/#{card_id}/list?", body)
  end

  def stub_trello_posted_attachments(card_id, body)
    stub_trello(:post, "cards/#{card_id}/attachments?", body)
  end

  def stub_trello_cards_on_board(board_name, card_id, body)
    board_id = Revere::Trello.fetch_board_id(board_name)
    stub_trello(:get, "boards/#{board_id}/cards", body)
  end

  def stub_trello_board_with_card_id(card_id, body)
    stub_trello(:get, "cards/#{card_id}/board", body)
  end

  def stub_trello_list_by_board_with_name_field(board_name, body)
    board_id = Revere::Trello.fetch_board_id(board_name)
    stub_trello(:get, "boards/#{board_id}/lists", body)
  end


  # Github
  def stub_github(verb, path, body = {}, status = 200)
    stub_request(verb, %r"#{GITHUB_BASE_URI}#{path}")
      .to_return(status: status, body: body.to_json)
  end

  def stub_github_pulls
    stub_github(:get, %r"repos/#{Revere::Github::GITHUB_REPO}/pulls/$")
  end

  def stub_github_pr(number)
    stub_github(:get, "repos/#{Revere::Github::GITHUB_REPO}/pulls/#{number}")
  end

  it "updates single zendesk ticket" do
    ticket_id = "1337"
    school_id = "12345"
    card_id = "trello_card_id"
    list_name = "list_name"
    board_name = "board_name"
    body = {ticket: {custom_fields: [{id: 45144647, value: "#{school_id}"}]}}
    stub_trello_attachment(card_id, [{url: "zendesk.com/ticket/#{ticket_id}"}, {url: "github.com/issues/#{ticket_id}"}])
    stub_trello_list(card_id, {name: list_name})
    stub_trello_board_with_card_id(card_id, {name: board_name})
    stub_zendesk_ticket(ticket_id)
    stub_zendesk_ticket_with_school(ticket_id, school_id, body)
    stub_trello_posted_attachments(card_id, body)

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
    body = {ticket: {custom_fields: [{id: 45144647, value: "#{school_id}"}]}}
    stub_trello_attachment(card_id, [{url: "zendesk.com/ticket/#{ticket_id_1}"}, {url: "zendesk.com/ticket/#{ticket_id_2}"}])
    stub_trello_list(card_id, {name: list_name})
    stub_trello_board_with_card_id(card_id, {name: board_name})
    stub_zendesk_ticket(ticket_id_1)
    stub_zendesk_ticket(ticket_id_2)
    stub_zendesk_ticket_with_school(ticket_id_1, school_id, body)
    stub_zendesk_ticket_with_school(ticket_id_2, school_id, body)
    stub_trello_posted_attachments(card_id, {})

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
    body = {ticket: {custom_fields: [{id: 45144647, value: "#{school_id}"}]}}
    stub_trello_attachment(card_id, [{url: "zendesk.com/ticket/#{ticket_id}"}, {url: "github.com/issue/4242"}, {url: "github.com/issue/5"}])
    stub_trello_list(card_id, {name: list_name})
    stub_trello_board_with_card_id(card_id, {name: board_name})
    stub_zendesk_ticket(ticket_id)
    stub_zendesk_ticket_with_school(ticket_id, school_id, body)
    stub_trello_posted_attachments(card_id, {})

    post "/trello", {action: {data: {card: {id: card_id}}}}.to_json

    # why doesn't using list_name instead of "list_name" work here??
    expect(zendesk_request(ticket_id, "list_name", "board_name", "github.com/issue/4242\ngithub.com/issue/5")).to have_been_made
  end

  it "handles other types of attachments" do
    stub_trello_attachment("trello_card_id", [{url: "boston.com/imwithstupid"}])
    stub_trello_list("trello_card_id", {name: "list name"})

    post "/trello", {action: {data: {card: {id: "trello_card_id"}}}}.to_json

    expect(a_request(:put, %r"#{Revere::Zendesk::BASE_URI}tickets/1337.json")).to_not have_been_made
  end

  it "syncs all the cards" do
    card_id = "trello_card_id"
    ticket_id = "1337"
    list_name = "list name"
    board_name = "board_name"
    stub_trello_cards_on_board(:dev_q, card_id, [{id: card_id}])
    stub_trello_cards_on_board(:sprint, card_id, [])
    stub_trello_cards_on_board(:icebox, card_id, [])
    stub_trello_cards_on_board(:ios_app, card_id, [])
    stub_trello_cards_on_board(:customer_care, card_id, [])
    stub_trello_attachment(card_id, [{url: "zendesk.com/ticket/#{ticket_id}"}])
    stub_trello_list(card_id, {name: list_name})
    stub_trello_board_with_card_id(card_id, {name: board_name})
    stub_zendesk_ticket(ticket_id)
    stub_trello_posted_attachments(card_id, {})
    stub_request(:get, %r"#{Revere::Zendesk::BASE_URI}tickets/#{ticket_id}.json")
       .to_return(body: {ticket: {custom_fields: [{id: 45144647, value: "12345"}]}}.to_json)

    Revere.sync_multiple_tickets

    expect(zendesk_request("1337", "list_name", "board_name", "")).to have_been_made
  end

  it "does not crash when trying to update a closed ticket" do

    stub_request(:put, %r"#{Revere::Zendesk::BASE_URI}tickets/1234.json")
      .to_return(status: 422, body: {"error":"RecordInvalid","description":"Record validation errors","details":{"status":[{"description":"Status: closed prevents ticket update"}]}}.to_json)

    Revere::Zendesk.update_ticket("1234", trello_list_name: "list name")

    # no error
  end

  it "updates the trello list names in zendesk" do
    #card_id = "trello_card_id"
    list_name1 = "list name 1"
    list_name2 = "list name 2"
    value1 = "list_name_1"
    value2 = "list_name_2"

    allow(Revere::Trello).to receive(:boards).and_return({"dev_q" => "12345", "sprint" => "67890"})

    stub_trello_list_by_board_with_name_field(:dev_q, [{name: list_name1}])
    stub_trello_list_by_board_with_name_field(:sprint, [{name: list_name2}])
    stub_trello_list_in_zendesk([{name: list_name1, value: value1},{name: list_name2, value: value2}])

    Revere.update_trello_list_names_in_zendesk

    expect(a_request(:put, %r"#{Revere::Zendesk::BASE_URI}ticket_fields/#{Revere::Zendesk.field_id("trello_list_name")}.json")
      .with(body: {ticket_field: {custom_field_options: [{name: list_name1, value: value1},{name: list_name2, value: value2}]}}.to_json))
      .to have_been_made
  end

end
