server "vit.room208.org", :roles => %w(web app db), :primary => true, :user => "danbooru"
set :linked_files, fetch(:linked_files, []).push(".env.production")
