set :stages, %w(production)
set :default_stage, "production"
set :application, "omnibooru"
set :repo_url, "git://github.com/kxz/omnibooru.git"
set :scm, :git
set :deploy_to, "/srv/danbooru2"
set :rbenv_ruby, "2.1.5"
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle')
set :default_env, {
  "RAILS_RELATIVE_URL_ROOT" => "/booru",
  "RAILS_GROUPS" => "assets"
}
