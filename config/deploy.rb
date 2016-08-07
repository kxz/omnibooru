set :stages, %w(production)
set :default_stage, "production"
set :application, "omnibooru"
set :repo_url, "git://github.com/kxz/omnibooru.git"
set :branch, "omnibooru"
set :scm, :git
set :deploy_to, "/srv/danbooru2"
set :rbenv_ruby, "2.1.5"
set :rbenv_type, :system
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle')
set :default_env, {
  "RAILS_GROUPS" => "assets",
  "XDG_RUNTIME_DIR" => "/run/user/112",
}
