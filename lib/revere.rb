require "yaml"

require "http"
require "addressable/uri"
require "verbose_hash_fetch"
require "raven"
require "robust-redis-lock"

require "revere/trello"
require "revere/zendesk"

module Revere

  TARGET_BASE_URL = ENV.fetch("TARGET_URL")

  def self.configure
    Raven.configure do |config|
      config.dsn = ENV["SENTRY_DSN"] if ENV["SENTRY_DSN"]
      config.excluded_exceptions = []
    end
    if ENV["REDISCLOUD_URL"]
      uri = URI.parse(ENV["REDISCLOUD_URL"])
      Redis::Lock.redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
    else
      Redis::Lock.redis = Redis.new
    end
  end

  def self.sync_single_ticket(card_id, tries = 5)
    lock("card_#{card_id}", tries) do
      card = Trello.get_card(card_id)

      card.zendesk_ticket_ids.each do |ticket_id|
        Zendesk.update_ticket(
          ticket_id,
          trello_list_name:  card.list_name,
          github_links:      card.github_links,
          trello_board_name: card.board_name
        )
      end

      school_ids = card.zendesk_ticket_ids.uniq.map { |ticket_id|
        Zendesk.school_id(ticket_id)
      }.compact.reject(&:empty?).uniq


      school_ids.each do |school_id|
        update_trello_card(card, school_id)
      end
    end
  end


  # TODO
  def self.lock(lock_id, tries, &block)
    lock = Redis::Lock.new(lock_id)
    lock.synchronize do
      block.call # this should be the actual method that does the main action
    end
  rescue Redis::Lock::LostLock
    tries -= 1
    if tries > 0
      sleep 0.5
      retry
    else
      raise
    end
  end

  def self.sync_multiple_tickets
    Trello.get_card_ids.each do |card_id|
      sync_single_ticket(card_id)
      sleep 0.5
    end
  end

  def self.update_trello_list_names_in_zendesk
    names = Trello.get_list_names.uniq { |name| name.downcase }
    Zendesk.update_ticket_fields(names)
  end

  def self.update_trello_card(card, school_id)
    ### pull out
    return if school_id.to_s !~ /\A\d+\z/
    url = "#{TARGET_BASE_URL}#{school_id}"
    if card.school_id_urls.none? { |i| i == url }
      card.create_school_attachment(url, "School ID: #{school_id}") #TODO
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
