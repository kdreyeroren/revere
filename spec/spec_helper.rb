ENV["RACK_ENV"] = "test"

require "webmock/rspec"
require "rack/test"
require_relative "../environment"
require "revere/web"

WebMock.disable_net_connect!
WebMock.enable!

RSpec.configure do |config|
  config.disable_monkey_patching!
end
