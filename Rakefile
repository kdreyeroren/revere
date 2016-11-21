desc "syncs all trello cards with zendesk tickets"
task :sync => :environment do
  Revere.sync_tickets
end

task :environment do
  require_relative "environment"
end
