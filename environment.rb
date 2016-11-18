$LOAD_PATH.unshift(File.expand_path("../lib", __FILE__))

require "bundler/setup"
Bundler.setup

RACK_ENV = ENV.fetch("RACK_ENV", "development")

if RACK_ENV != "production"
  require "dotenv"
  Dotenv.load(".env.#{RACK_ENV}", ".env")
end
