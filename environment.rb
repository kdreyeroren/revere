$LOAD_PATH.unshift(File.expand_path("../lib", __FILE__))
$stdout.sync = true

require "bundler/setup"
Bundler.setup

RACK_ENV = ENV.fetch("RACK_ENV", "development")
APP_ROOT = Pathname(File.expand_path("../", __FILE__))

if RACK_ENV != "production"
  require "dotenv"
  Dotenv.load(".env.#{RACK_ENV}", ".env")
end

require "revere"
Revere.configure
