ENV["RACK_ENV"] = "test"

require "bundler/setup"
Bundler.setup

require "webmock/rspec"
require "revere"
require "rack/test"
require "./web"

WebMock.disable_net_connect!
WebMock.enable!

RSpec.configure do |config|
  config.disable_monkey_patching!
end
