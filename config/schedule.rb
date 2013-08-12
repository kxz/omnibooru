set :output, "log/whenever.log"

every 1.day do
  runner "DailyMaintenance.new.run"
end

every 1.day, :at => "1:00 am" do
  command "cd /srv/danbooru2/current ; script/donmai/backup_db"
  command "cd /srv/danbooru2/current ; script/donmai/prune_backup_dbs"
  command "psql --set statement_timeout=0 -c \"vacuum analyze;\" danbooru2"
end

every 1.week, :at => "1:30 am" do
  runner "WeeklyMaintenance.new.run"
end
