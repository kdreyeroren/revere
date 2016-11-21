source "https://rubygems.org"

ruby "2.3.1"

gem "sinatra"
gem "http"
gem "addressable"
gem "verbose_hash_fetch"
gem "pry"
gem "rake"
gem "dotenv", groups: [:development, :test]
gem "sentry-raven"

group :development do
  gem "awesome_print"
end

group :test do
  gem "rack-test"
  gem "rspec"
  gem "webmock"
end

group :production do
  gem "thin"
end
