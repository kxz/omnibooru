require 'capistrano/ext/multistage'
require 'bundler/capistrano'
require 'whenever/capistrano'


### Settings

# Repository
set :repository, "git://github.com/kxz/omnibooru.git"
set :scm, :git
set :deploy_via, :remote_cache

# Server
set :application, "omnibooru"
set :user, "danbooru"
set :deploy_to, "/srv/danbooru2"
set :shared_children, %w(public/cache public/data public/images/advertisements
                         log tmp/pids tmp/sockets)
set :use_sudo, false
set :default_environment, {
  "PATH" => '/usr/local/rbenv/shims:$PATH'
}

# Multistage
set :stages, %w(production)
set :default_stage, "production"

# Bundler
set :bundle_cmd, "bundle"
set :bundle_flags, "--deployment --binstubs"

# Asset deployment
set :rake, "#{bundle_cmd} exec rake"
set :asset_env, "RAILS_RELATIVE_URL_ROOT=/booru RAILS_GROUPS=assets"

# Whenever
set :whenever_command, "#{bundle_cmd} exec whenever"
set :whenever_environment, defer {stage}


### Tasks

# delayed_job
namespace :delayed_job do
  desc "Start the delayed_job process"
  task :start, :roles => :app do
    run "systemctl --user start danbooru-delayed_job.service"
  end

  desc "Stop the delayed_job process"
  task :stop, :roles => :app do
    run "systemctl --user stop danbooru-delayed_job.service"
  end

  desc "Restart the delayed_job process"
  task :restart, :roles => :app do
    run "systemctl --user restart danbooru-delayed_job.service"
  end
end

after "deploy:stop", "delayed_job:stop"
after "deploy:start", "delayed_job:start"
after "deploy:restart", "delayed_job:restart"

# Deployment
namespace :deploy do
  desc "Create the shared config directory."
  task :setup_config, :roles => :app do
    run "mkdir -p #{shared_path}/config"
  end

  desc "Create `preview' and `sample' subdirectories within the shared data directory."
  task :setup_data_dirs, :roles => :app do
    run "mkdir #{shared_path}/data/preview"
    run "mkdir #{shared_path}/data/sample"
  end

  after "deploy:setup", "deploy:setup_config"
  after "deploy:setup", "deploy:setup_data_dirs"

  desc "Create symlinks to config files in the shared directory in the release directory."
  task :symlink_config, :roles => :app do
    %w(danbooru_local_config.rb database.yml secret_token session_secret_key).map do |file|
      run "ln -s #{shared_path}/config/#{file} #{release_path}/config/#{file}"
    end
  end

  after "deploy:finalize_update", "deploy:symlink_config"
end

# Unicorn
namespace :unicorn do
  desc "Start Unicorn master process"
  task :start, :roles => :app do
    run "systemctl --user start danbooru-unicorn.service"
  end

  desc "Stop Unicorn"
  task :stop, :roles => :app do
    run "systemctl --user stop danbooru-unicorn.service"
  end

  desc "Reload Unicorn"
  task :reload, :roles => :app do
    run "systemctl --user reload danbooru-unicorn.service"
  end

  desc "Restart Unicorn"
  task :restart, :roles => :app do
    run "systemctl --user restart danbooru-unicorn.service"
  end
end

after "deploy:stop", "unicorn:stop"
after "deploy:start", "unicorn:start"
after "deploy:restart", "unicorn:reload"
