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
    trello_list_name = Trello.get_list_name(card_id)

    card.zendesk_ticket_ids.each do |ticket_id|
      Zendesk.update_ticket(ticket_id, trello_list_name: trello_list_name, github_links: card.github_links)
    end
  end

  def self.sync_multiple_tickets
    Trello.get_card_ids.each do |card_id|
      sync_single_ticket(card_id)
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
