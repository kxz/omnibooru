namespace :symlink do
  desc "Link the local config files"
  task :local_files do
    on roles(:app) do
      %w(danbooru_local_config.rb database.yml secret_token session_secret_key).each do |file|
        execute :ln, "-s", "#{deploy_to}/shared/config/#{file}", "#{release_path}/config/#{file}"
      end
    end
  end

  desc "Link the local directories"
  task :directories do
    on roles(:app) do
      execute :rm, "-f", "#{release_path}/public/data"
      execute :ln, "-s", "#{deploy_to}/shared/data", "#{release_path}/public/data"

      execute :mkdir, "-p", "#{release_path}/public/cache"
      execute :mkdir, "-p", "#{deploy_to}/shared/system/cache"
      execute :touch, "#{deploy_to}/shared/system/cache/tags.json"
      execute :ln, "-s", "#{deploy_to}/shared/system/cache/tags.json", "#{release_path}/public/cache/tags.json"
      execute :touch, "#{deploy_to}/shared/system/cache/tags.json.gz"
      execute :ln, "-s", "#{deploy_to}/shared/system/cache/tags.json.gz", "#{release_path}/public/cache/tags.json.gz"
    end
  end
end
