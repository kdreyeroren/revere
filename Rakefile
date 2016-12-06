desc "syncs all trello cards with zendesk tickets"
task :sync => :environment do
  Revere.sync_multiple_tickets
end

task :environment do
  require_relative "environment"
end

desc "runs console"
task :console => :environment do
  require "pry"
  require "awesome_print"
  Pry.start(Revere)
end
