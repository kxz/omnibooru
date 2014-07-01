set :output, "log/whenever.log"

every 1.day do
  runner "DailyMaintenance.new.run"
end

every 1.day, :at => "1:00 am" do
  script "donmai/backup_db"
  script "donmai/prune_backup_dbs"
end

every 1.week, :at => "1:30 am" do
  runner "WeeklyMaintenance.new.run"
end
