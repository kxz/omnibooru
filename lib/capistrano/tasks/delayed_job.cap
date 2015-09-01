namespace :delayed_job do
  desc "Start the delayed_job process"
  task :start do
    on roles(:app) do
      execute "systemctl", "--user", "start", "danbooru-delayed_job.service"
    end
  end

  desc "Stop the delayed_job process"
  task :stop do
    on roles(:app) do
      execute "systemctl", "--user", "stop", "danbooru-delayed_job.service"
    end
  end

  desc "Restart the delayed_job process"
  task :restart do
    on roles(:app) do
      execute "systemctl", "--user", "restart", "danbooru-delayed_job.service"
    end
  end
end

before "deploy:started", "delayed_job:stop"
after "deploy:published", "delayed_job:start"
