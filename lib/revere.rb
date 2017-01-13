require "yaml"

require "http"
require "addressable/uri"
require "verbose_hash_fetch"
require "raven"

require "revere/trello"
require "revere/zendesk"
require "revere/github"

module Revere

  def self.configure
    Raven.configure do |config|
      config.dsn = ENV["SENTRY_DSN"] if ENV["SENTRY_DSN"]
      config.excluded_exceptions = []
    end
  end

  def self.sync_single_ticket(card_id)
    card = Trello.get_card(card_id)

    card.zendesk_ticket_ids.each do |ticket_id|
      Zendesk.update_ticket(
        ticket_id,
        trello_list_name:  card.list_name,
        github_links:      card.github_links
      )
    end

    school_ids = card.zendesk_ticket_ids.uniq.map { |ticket_id|
      Zendesk.school_id(ticket_id)
    }.compact.reject(&:empty?).uniq

    school_ids.each do |school_id|
      update_trello_card(card, school_id)
    end
  end

  def self.sync_multiple_tickets
    Trello.get_card_ids.each do |card_id|
      sync_single_ticket(card_id)
      sleep 0.5
    end
  end

  def self.update_trello_card(card, school_id)
    return if !school_id || school_id == ""
    url = "https://staff.teachable.com/schools/#{school_id}"
    if card.school_id_urls.none? { |i| i == url }
      card.create_school_attachment(url, "School ID: #{school_id}")
    end
  end

  def self.move_all_trello_cards
    Trello.get_card_ids.each do |card_id|
      move_trello_card_to_new_list(card_id)
    end
  end

  def self.move_trello_card_to_new_list(card_id)
      card = Trello.get_card(card_id)
      list_name = card.list_name
      pr_number = Github.get_pull_request_number_from_trello_card(card_id)

      return if !pr_number || pr_number == nil

      pr_status = Github.get_pull_request_status(pr_number)
      github_status = Github.github_checks(pr_number)
      merged_status = Github.get_if_pull_request_has_been_merged(pr_number)

      if (list_name.include? "Progress") && (pr_status == "open") && (pr_status != "closed") && (github_status == "success")
        Trello.move_card_to_code_review(card_id)
      elsif (list_name.include? "Review") && (pr_status == "closed") && (pr_status != "open") && (merged_status == true) && (github_status == "success")
        Trello.move_card_to_staging(card_id)
      else
        # noop
      end
  end


  def self.logger
    @logger ||= build_logger
  end

  def self.build_logger
    if RACK_ENV == "test"
      FileUtils.mkdir_p(APP_ROOT.join("log"))
      Logger.new(APP_ROOT.join("log/test.log"))
    else
      Logger.new($stdout)
    end
  end


end
