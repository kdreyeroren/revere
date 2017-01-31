# Revere

## Synopsis

This is a little app that connects Zendesk to Trello, to keep the Customer Care team from having to go back and forth too much.

The name is "Revere" like Paul Revere, because he was a messenger of information, and I'm from Lexington.

## Installation

- Regular installation:  
```
bundle install
thin start  
```

- To test the server:  
```
gem install shotgun
shotgun
ngrok http 9393
```

- To test webhooks:
```
bundle install
thin --threaded start
ngrok http 3000
```

## Features

#### Zendesk

- Revere adds both the Trello list name and board name (in separate fields) to a ticket. Both of these are dropdown menus so that the Customer Care team can create custom views in Zendesk with each field. The list of list names is updated automatically, but if you want to add a new board, that will have to be done manually.
- Revere adds any associated Github links (PRs, issues) to a field in a ticket. This way the CC team can keep track of what the engineering team is up to and make sure things are being managed properly.

#### Trello

- Revere automatically adds the school ID of any Trello card associated with a Zendesk ticket to the Trello card as an attachment with a clickable link to the school in the Staff App.

## How it works

- `Revere.sync_single_ticket`
Anytime a card is moved on any of the connected Trello boards, a webhook is triggered. Upon triggering, this method syncs any Zendesk ticket associated with that card. It also updates the Trello card with the school ID of the associated ticket. Every hour, a rake task runs that syncs all the tickets on all the Trello boards in case the webhook hit an error and missed an update.

- `Revere.sync_multiple_tickets`
Rake task that runs every hour that syncs all cards on the Trello board with Zendesk tickets, in case the webhook missed something.

- `Revere.update_trello_list_names_in_zendesk`
Rake task that runs once a day which updates the list of Trello list names in Zendesk.
