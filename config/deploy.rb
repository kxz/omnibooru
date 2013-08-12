set :stages, %w(production)
set :default_stage, "production"
set :unicorn_env, defer {stage}
require 'capistrano/ext/multistage'

require 'capistrano-unicorn'
set :unicorn_user, "danbooru"

require 'bundler/capistrano'
set :bundle_cmd, "/usr/local/rbenv/shims/bundle"
set :bundle_flags, "--deployment --binstubs"

set :default_environment, {
  "PATH" => '/usr/local/rbenv/shims:/usr/local/rbenv/bin:$PATH'
}

set :application, "omnibooru"
set :repository, "git://github.com/kxz/omnibooru.git"
set :scm, :git

set :deploy_to, "/srv/danbooru2"
set :deploy_via, :remote_cache
set :use_sudo, false
set :rake, defer {"#{sudo :as => unicorn_user} #{bundle_cmd} exec rake"}
set :asset_env, "RAILS_RELATIVE_URL_ROOT=/booru RAILS_GROUPS=assets"
set :shared_children, %w(public/system log tmp/pids tmp/sockets)

set :whenever_command, defer {"#{sudo :as => unicorn_user} #{bundle_cmd} exec whenever"}
set :whenever_environment, defer {stage}
require 'whenever/capistrano'

default_run_options[:pty] = true

namespace :local_config do
  desc "Create the shared config directory"
  task :setup_shared_directory do
    run "mkdir -p #{shared_path}/config"
  end

  desc "Initialize local config files"
  task :setup_local_files do
    run "curl -s https://raw.github.com/r888888888/danbooru/master/script/install/danbooru_local_config.rb.templ > #{shared_path}/config/danbooru_local_config.rb"
    run "curl -s https://raw.github.com/r888888888/danbooru/master/script/install/database.yml.templ > #{shared_path}/config/database.yml"
  end

  desc "Link the local config files"
  task :link_local_files do
    %w(danbooru_local_config.rb database.yml secret_token session_secret_key).map do |file|
      run "ln -s #{shared_path}/config/#{file} #{release_path}/config/#{file}"
    end
  end
end

namespace :data do
  task :setup_directories do
    run "mkdir -p #{shared_path}/data"
    run "mkdir #{shared_path}/data/preview"
    run "mkdir #{shared_path}/data/sample"
  end

  task :link_directories do
    run "rm -f #{release_path}/public/data"
    run "ln -s #{shared_path}/data #{release_path}/public/data"

    run "rm -f #{release_path}/public/ssd"
    run "ln -s /mnt/ssd#{deploy_to}/current/public #{release_path}/public/ssd"

    run "rm -f #{release_path}/public/images/advertisements"
    run "ln -s #{shared_path}/advertisements #{release_path}/public/images/advertisements"

    run "mkdir -p #{release_path}/public/cache"
    run "mkdir -p #{shared_path}/system/cache"
    run "touch #{shared_path}/system/cache/tags.json"
    run "ln -s #{shared_path}/system/cache/tags.json #{release_path}/public/cache/tags.json"
    run "touch #{shared_path}/system/cache/tags.json.gz"
    run "ln -s #{shared_path}/system/cache/tags.json.gz #{release_path}/public/cache/tags.json.gz"
  end
end

namespace :deploy do
  namespace :web do
    desc "Present a maintenance page to visitors."
    task :disable do
      maintenance_html_path = "#{current_path}/public/maintenance.html.bak"
      run "if [ -e #{maintenance_html_path} ] ; then mv #{maintenance_html_path} #{current_path}/public/maintenance.html ; fi"
    end

    desc "Makes the application web-accessible again."
    task :enable do
      maintenance_html_path = "#{current_path}/public/maintenance.html"
      run "if [ -e #{maintenance_html_path} ] ; then mv #{maintenance_html_path} #{current_path}/public/maintenance.html.bak ; fi"
    end
  end

  namespace :nginx do
    desc "Shut down Nginx"
    task :stop do
      run "#{sudo} /etc/init.d/nginx stop"
    end

    desc "Start Nginx"
    task :start do
      run "#{sudo} /etc/init.d/nginx start"
    end
  end

  namespace :assets do
    desc "Sets asset permissions"
    task :set_permissions do
      run "#{sudo} chmod -R a+w #{shared_path}/#{shared_assets_prefix}"
    end
  end

  desc "Sets release directory permissions"
  task :set_permissions do
    %w(. db/structure.sql log tmp).map do |path|
      run "#{sudo} chown #{unicorn_user} #{release_path}/#{path}"
      run "#{sudo} chmod g+w #{release_path}/#{path}"
    end
  end
end

namespace :delayed_job do
  desc "Start delayed_job process"
  task :start, :roles => :app do
    run "cd #{current_path}; #{sudo :as => unicorn_user} RAILS_ENV=#{rails_env} #{bundle_cmd} exec ruby script/delayed_job --queues=default,`hostname` start"
  end

  desc "Stop delayed_job process"
  task :stop, :roles => :app do
    run "cd #{current_path}; #{sudo :as => unicorn_user} RAILS_ENV=#{rails_env} #{bundle_cmd} exec ruby script/delayed_job stop"
  end

  desc "Restart delayed_job process"
  task :restart, :roles => :app do
    find_and_execute_task("delayed_job:stop")
    find_and_execute_task("delayed_job:start")
  end

  task :kill, :roles => :app do
    procs = capture("ps -A -o pid,command").split(/\r\n|\r|\n/).grep(/delayed_job/).map(&:to_i)

    if procs.any?
      run "for i in #{procs.join(' ')} ; do #{sudo :as => unicorn_user} kill -SIGTERM $i ; done"
    end
  end
end

after "deploy:setup", "local_config:setup_shared_directory"
after "deploy:setup", "local_config:setup_local_files"
after "deploy:setup", "data:setup_directories"
after "deploy:create_symlink", "data:link_directories"
after "deploy:start", "delayed_job:start"
after "deploy:stop", "delayed_job:stop"
before "deploy:update", "deploy:web:disable"
after "deploy:update_code", "local_config:link_local_files"
after "deploy:update_code", "deploy:set_permissions"
after "deploy:assets:precompile", "deploy:assets:set_permissions"
after "deploy:update", "deploy:migrate"
after "deploy:update", "delayed_job:restart"
after "deploy:update", "unicorn:reload"
after "deploy:update", "unicorn:restart"
after "deploy:update", "deploy:web:enable"
after "delayed_job:stop", "delayed_job:kill"
