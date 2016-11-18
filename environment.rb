$LOAD_PATH.unshift(File.expand_path("../lib", __FILE__))

require "bundler/setup"
Bundler.setup

if ENV["RACK_ENV"] != "production"
  require "dotenv"
  Dotenv.load(".env.#{ENV["RACK_ENV"]}", ".env")
end
