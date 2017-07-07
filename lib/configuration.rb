# require "yaml"
#
# require "http"
# require "addressable/uri"
# require "verbose_hash_fetch"
# require "raven"
# require "robust-redis-lock"
#
# require "revere/trello"
# require "revere/zendesk"
#
# module Configuration
#
#   # MODIFY
#   # This is where the meat of your app will go!
#   def self.sync_single_ticket
#
#     Revere.lock("card_#{card_id}", tries) do
#       card = Trello.get_card(card_id)
#
#       card.zendesk_ticket_ids.each do |ticket_id|
#         Zendesk.update_ticket(
#           # You'll have all the Zendesk ticket updating code here.
#           ticket_id,
#           trello_list_name:  card.list_name,
#           github_links:      card.github_links,
#           trello_board_name: card.board_name
#         )
#       end
#
#       # MODIFY
#       # This is where we got all unique school IDs associated with a particular Trello card
#       # since sometimes there were multiple Zendesk tickets attached to each card. I'm leaving this in
#       # in case you have a similar need to find unique identifiers on your own card/ticket combos.
#       school_ids = card.zendesk_ticket_ids.uniq.map { |ticket_id|
#         Zendesk.school_id(ticket_id)
#       }.compact.reject(&:empty?).uniq
#
#       # MODIFY
#       # We modified each card to have an attachment with the school ID as a link to the school in our backend
#       # system. This is where you'll do something similar.
#       school_ids.each do |school_id|
#         update_trello_card(card, school_id)
#       end
#     end
#
#   end
#
#
#
# end
