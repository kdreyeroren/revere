RSpec.describe Revere do

  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  TRELLO_BASE_URI  = Revere::Trello::BASE_URI
  ZENDESK_BASE_URI = Revere::Zendesk::BASE_URI

  GITHUB_BASE_URI  = Revere::Github::BASE_URI
  GITHUB_REPO      = Revere::Github::GITHUB_REPO

  # Trello
  def stub_trello_attachment(card_id, body)
    stub_request(:get, %r"#{TRELLO_BASE_URI}cards/#{card_id}/attachments\?")
      .to_return(status: 200, body: body.to_json)
  end

  def stub_trello_list(card_id, body)
    stub_request(:get, %r"#{TRELLO_BASE_URI}cards/#{card_id}/list\?")
      .to_return(status: 200, body: body.to_json)
  end

  def stub_trello_card_movement(card_id)
    stub_request(:put, %r"#{TRELLO_BASE_URI}cards/#{card_id}/idList").to_return(status: 200, body: "{}")
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
