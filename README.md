# Revere

## Synopsis

This is a little app that connects Zendesk to Trello.

The name is "Revere" like Paul Revere, because he was a messenger, and I'm from Lexington.

## Installation

Regular installation:
    bundle install
    thin start

Testing server:
    gem install shotgun
    shotgun
    ngrok http 9393

To test webhooks:
    bundle install
    thin --threaded start
