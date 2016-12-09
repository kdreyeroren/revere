require 'yaml'

require 'http'
require 'addressable/uri'
require 'verbose_hash_fetch'
require 'raven'

require 'revere/trello'
require 'revere/zendesk'

module Revere

  def self.configure
    Raven.configure do |config|
      config.dsn = ENV["SENTRY_DSN"] if ENV["SENTRY_DSN"]
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
      update_trello_card(card, ticket_id)
    end

    school_ids = card.zendesk_ticket_ids.map { |ticket_id|
      Zendesk.school_id(ticket_id)
    }.compact.reject(&:empty?).uniq

    school_ids.each do |school_id|
      update_trello_card(card, school_id)
    end
  end

  def self.sync_multiple_tickets
    Trello.get_card_ids.each do |card_id|
      sync_single_ticket(card_id)
    end
  end

  def self.update_trello_card(card, school_id)
    return if !school_id || school_id == ""
    url = "https://staff.teachable.com/schools/#{school_id}"
    if card.school_id_urls.none? { |i| i == url }
      card.create_school_attachment(url, "School ID: #{school_id}")
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
