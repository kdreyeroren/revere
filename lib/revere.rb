require 'yaml'

require 'http'
require 'addressable/uri'
require 'verbose_hash_fetch'

require 'revere/trello'
require 'revere/zendesk'

module Revere

  def self.puts_trello_list_name_on_zendesk_ticket(card_id)
    # step 1. Find zendesk ticket ids
    ticket_ids = Trello.get_zendesk_ticket_ids_from_trello_attachments(card_id)
    # step 2. Find list name
    trello_list_name = Trello.get_list_name(card_id)
    # step 3. Send that name to Zendesk tickets
    ticket_ids.each do |ticket_id|
      Zendesk.modify_ticket_with_trello_list(ticket_id, trello_list_name)
    end
  end

  def self.sync_tickets
    Trello.get_card_ids.each do |card_id|
      puts_trello_list_name_on_zendesk_ticket(card_id)
    end
  end

  def self.logger
    @logger ||= Logger.new($stdout)
  end

end
