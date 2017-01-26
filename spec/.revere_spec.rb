RSpec.describe Revere do

  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  TRELLO_BASE_URI  = Revere::Trello::BASE_URI
  ZENDESK_BASE_URI = Revere::Zendesk::BASE_URI
  BOARD_ID_DEV_Q   = Revere::Trello::BOARD_ID_DEV_Q
  BOARD_ID_SPRINT  = Revere::Trello::BOARD_ID_SPRINT
  GITHUB_BASE_URI  = Revere::Github::BASE_URI
  GITHUB_REPO      = Revere::Github::GITHUB_REPO

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

  def stub_trello_comment_card(card_id)
    stub_request(:get, %r"#{TRELLO_BASE_URI}cards/#{card_id}\?actions=commentCard")
      .to_return(body: {"actions" => []}.to_json)
  end

  def stub_trello_posted_comment(card_id)
    stub_request(:post, %r"#{TRELLO_BASE_URI}cards/#{card_id}/actions/comments")
      .to_return(status: 200, body: "{}")
  end

  def stub_trello_card_movement(card_id)
    stub_request(:put, %r"#{TRELLO_BASE_URI}cards/#{card_id}/idList").to_return(status: 200, body: "{}")
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

  def trello_comment_request(card_id, comment_text)
    a_request(:post, %r"#{TRELLO_BASE_URI}cards/#{card_id}/actions/comments")
      .with()
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
    pending
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

  xit "creates a github webhook" do
    allow(Revere::Github).to receive(:create_webhook).and_return("hello")

    post "/create_github_webhook"

    expect(last_response.status).to eq 200
    expect(last_response.body).to include "hello"
    expect(Revere::Github).to have_received(:create_webhook).with("http://example.org/github")
  end

  xit "creates a github webhook with a stub" do
    stub_request(:post, "#{GITHUB_BASE_URI}repos/#{GITHUB_REPO}/hooks")
      .with(body:
        {
          name: "web",
          active: true,
          config: {
            url: "http://example.org/github",
            content_type: JSON
            }
          }.to_json
        )
      .to_return(status: 200, body: "{}", headers: {})

    post "/create_github_webhook"

    expect(last_response.status).to eq 200
  end

  it "moves a trello card correctly from in progress to code review" do
    pending "I get back to the github bit"
    card_id = "trello_card_id"
    code_review_id = "code_review_id"
    number = "5"
    list_name = "In Progress"

    stub_trello_list(card_id, {name: list_name}).to_return(status: 200, body: "", headers: {})
    stub_trello_attachment(card_id, [{url: "github.com/revere/pull/#{number}"}])
    stub_github_pulls.to_return(status: 200, body: "{}")
    stub_github_status_to_cr(number)
    stub_trello_card_movement(card_id)
    stub_trello_card_movement(card_id).with(body: {value: "#{code_review_id}"}.to_json)

    Revere.move_trello_card_to_new_list(card_id)

    expect(stub_trello_card_movement(card_id)).to have_been_made
  end

  it "moves a trello card correctly from code review to staging" do
    pending "I get back to the github bit"
    card_id = "trello_card_id"
    staging_id = "staging_id"
    number = "5"
    list_name = "Code Review"

    stub_trello_list(card_id, {name: list_name}).to_return(status: 200, body: "", headers: {})
    stub_trello_attachment(card_id, [{url: "github.com/revere/pull/#{number}"}])
    stub_github_pulls.to_return(status: 200, body: "{}")
    stub_github_status_to_staging(number)
    stub_trello_card_movement(card_id)
    stub_trello_card_movement(card_id).with(body: {value: "#{staging_id}"}.to_json)

    Revere.move_trello_card_to_new_list(card_id)

    expect(stub_trello_card_movement(card_id)).to have_been_made
  end

  xit "does not move a trello card to code review if PR is closed" do
    card_id = "trello_card_id"
    code_review_id = "code_review_id"
    number = "5"
    list_name = "In Progress"

    stub_trello_list(card_id, {name: list_name}).to_return(status: 200, body: "", headers: {})
    stub_trello_attachment(card_id, [{url: "github.com/revere/pull/#{number}"}])
    stub_github_pulls.to_return(status: 200, body: "{}")
    stub_github_status_not_to_cr(number)
    stub_trello_card_movement(card_id)
    stub_trello_card_movement(card_id).with(body: {value: "#{code_review_id}"}.to_json)

    Revere.move_trello_card_to_new_list(card_id)

    expect(stub_trello_card_movement(card_id)).to_not have_been_made
  end

  xit "does not move a trello card to staging if github checks don't pass" do
    card_id = "trello_card_id"
    staging_id = "staging_id"
    number = "5"
    list_name = "Code Review"

    stub_trello_list(card_id, {name: list_name}).to_return(status: 200, body: "", headers: {})
    stub_trello_attachment(card_id, [{url: "github.com/revere/pull/#{number}"}])
    stub_github_pulls.to_return(status: 200, body: "{}")
    stub_github_status_not_to_staging(number)
    stub_trello_card_movement(card_id)
    stub_trello_card_movement(card_id).with(body: {value: "#{staging_id}"}.to_json)

    Revere.move_trello_card_to_new_list(card_id)

    expect(stub_trello_card_movement(card_id)).to_not have_been_made
  end

  xit "does not move a trello card to code review if pr is merged" do
    card_id = "trello_card_id"
    code_review_id = "code_review_id"
    number = "5"
    list_name = "Progress"

    stub_trello_list(card_id, {name: list_name}).to_return(status: 200, body: "", headers: {})
    stub_trello_attachment(card_id, [{url: "github.com/revere/pull/#{number}"}])
    stub_github_pulls.to_return(status: 200, body: "{}")
    stub_github_status_not_to_cr2(number)
    stub_trello_card_movement(card_id)
    stub_trello_card_movement(card_id).with(body: {value: "#{code_review_id}"}.to_json)

    Revere.move_trello_card_to_new_list(card_id)

    expect(stub_trello_card_movement(card_id)).to_not have_been_made
  end

  xit "does not move a trello card to staging if the list name is wrong" do
    card_id = "trello_card_id"
    staging_id = "staging_id"
    number = "5"
    list_name = "Progress"

    stub_trello_list(card_id, {name: list_name}).to_return(status: 200, body: "", headers: {})
    stub_trello_attachment(card_id, [{url: "github.com/revere/pull/#{number}"}])
    stub_github_pulls.to_return(status: 200, body: "{}")
    stub_github_status_not_to_staging(number)
    stub_trello_card_movement(card_id)
    stub_trello_card_movement(card_id).with(body: {value: "#{staging_id}"}.to_json)

    Revere.move_trello_card_to_new_list(card_id)

    expect(stub_trello_card_movement(card_id)).to_not have_been_made
  end

  xit "does nothing if there is no pr" do
    card_id = "trello_card_id"
    staging_id = "staging_id"
    number = "5"
    list_name = "Progress"

    stub_trello_list(card_id, {name: list_name}).to_return(status: 200, body: "", headers: {})
    stub_trello_attachment(card_id, [{url: "boston.com"}])
    stub_github_pulls.to_return(status: 200, body: "{}")
    stub_github_status_not_to_staging(number)
    stub_trello_card_movement(card_id)
    stub_trello_card_movement(card_id).with(body: {value: "#{staging_id}"}.to_json)

    Revere.move_trello_card_to_new_list(card_id)

    # no error
  end


end
