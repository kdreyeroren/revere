# Revere

## Synopsis

This is a little app that connects Zendesk to Trello, pulling relevant information from each platform to the other so you don't have to constantly switch back and forth. If you use Trello and Zendesk together as an issue management system, Revere can save you time.

The name is "Revere" like Paul Revere, because he was a messenger of information, and I'm from Lexington.

### Background

We had a system in which, when a customer had a problem that requires a bug fix, the customer care associate would take the customer's Zendesk ticket and attach it to a Trello card on a board dedicated to "questions only the engineers can solve." That board had several lists: New, In Progress, Fixed, Deployed, etc. This forced both engineers and customer care associates to go back and forth all the time: the CC team constantly checked which lane the card was in, and if a problem had been fixed they had no way of knowing automatically. Additionally, engineers were constantly having to go back to Zendesk and find the account associated with the ticket so they could troubleshoot. This wasted a lot of time, so I built Revere.

You'll notice that there are a lot of references to "school" in here - our product was an education platform, so our accounts were all schools with IDs and URLs that pointed to the school in our backend system. You can of course use it with whatever type of account details you like; I took out identifying information but you should be able to change "school" to "account" or "user" or anything else.

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

- To run tests:
```
rspec
````

## How we used it

Revere has two parts - first, it updates the Zendesk ticket with information from the Trello card, and second, it updates the Trello card with information from the Zendesk ticket. You can modify the code to have it update each one with whatever information you choose.

### Zendesk

- Revere adds both the Trello list name and board name (in separate fields) to a ticket. Both of these are dropdown menus so that the Customer Care team can create custom views in Zendesk with each field. The list of list names is updated automatically (`Zendesk.update_ticket_fields`), but if you want to add an additional Trello board, that will have to be done manually.
- Revere adds any associated Github links (PRs, issues) to a field in a ticket. This way the CC team can keep track of what the engineering team is up to and make sure bugs and issues are being managed properly.

### Trello

- Revere automatically adds the school ID of any Trello card associated with a Zendesk ticket to the Trello card as an attachment with a clickable link to the school in our backend system.

## How it works

- `Revere.sync_single_ticket`
Anytime a card is moved on any of the connected Trello boards, a webhook is triggered. Upon triggering, this method syncs any Zendesk ticket associated with that card. It also updates the Trello card with the school ID of the associated ticket. Every hour, a rake task runs that syncs all the tickets on all the Trello boards in case the webhook hit an error and missed an update.

- `Revere.sync_multiple_tickets`
Rake task that runs every hour that syncs all cards on the Trello board with Zendesk tickets, in case the webhook missed something.

- `Revere.update_trello_list_names_in_zendesk`
Rake task that runs once a day which updates the list of Trello list names in Zendesk.

## Make it your own

Everyone will have a slightly different use case for Revere. We primarily used it for syncing school IDs from the Zendesk ticket to the Trello card, and then turning it into a link to the school's page on our backend system, but using Revere you can pull any piece of info from a Zendesk ticket and put it on your Trello card. Additionally, you can use it to keep any Trello board list names synced on Zendesk.

### Trello details

The Trello env vars we used were associated with a Trello account that we used as a bot. This tends to work better than using an actual person's Trello account as they often get asked questions they may not know the answers to or care about, so I recommend doing something similar.

### Zendesk details

We used a bunch of custom Zendesk fields to fit our needs. You'll want to update those in the zendesk.yml file for your own custom fields.

### Where to input your code

I left in the bulk of the code we used, so that you can see how everything fits together. Do a project search for the # MODIFY comment and you'll find all the places where you should modify the code to fit your needs.

## Spec

Spec currently works as-is. You'll probably want to update it as you build out your app to include brand-specific wording. To run spec, simply run `rspec`.

## env.test

Below is a sample `.env.test` file. Again, everything here works with the current spec, but you'll want to modify all of these test env vars to suit your system. Some of them do not have to fit the particular system's conventions; others do. Items to modify are below.

### Trello

For test purposes, the only Trello details that have to be accurate are list IDs and user ID. I created a test account separate even from my bot account, and I recommend you do the same, and use all associated IDs.

`TRELLO_API_KEY="TRELLO_API_KEY"
TRELLO_TOKEN="TRELLO_TOKEN"
TRELLO_BOARD_ID="TRELLO_BOARD_ID"
TRELLO_BASE_URI="http://trello-base-uri/"
TRELLO_USER_ID="your_real_test_user_ID"`

### Zendesk

`ZENDESK_USER="ZENDESK_USER"
ZENDESK_TOKEN="ZENDESK_TOKEN"
ZENDESK_BASE_URI="http://zendesk-base-uri/"`

### Github

You'll have to use your real Github repo below

`GITHUB_BASE_URI="https://api.github.com/"
GITHUB_REPO="github_username/repo_name"`

### Internal Variables

You'll want to use real internal URLs here.

`TARGET_URL="https://our_school_url.com/"```
