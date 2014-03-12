Danbooru::Application.routes.draw do
  namespace :admin do
    resources :users, :only => [:edit, :update]
    resource  :alias_and_implication_import, :only => [:new, :create]
  end
  namespace :mobile do
    resources :posts, :only => [:index, :show]
  end
  namespace :moderator do
    resource :dashboard, :only => [:show]
    resources :ip_addrs, :only => [:index] do
      collection do
        get :search
      end
    end
    resources :invitations, :only => [:new, :create, :index]
    resource :tag, :only => [:edit, :update]
    namespace :post do
      resource :queue, :only => [:show]
      resource :approval, :only => [:create]
      resource :disapproval, :only => [:create]
      resources :posts, :only => [:delete, :undelete, :expunge, :confirm_delete] do
        member do
          get :confirm_delete
          post :expunge
          post :delete
          post :undelete
          get :confirm_ban
          post :ban
          post :unban
        end
      end
    end
    resources :invitations, :only => [:new, :create, :index, :show]
    resources :ip_addrs, :only => [:index, :search] do
      collection do
        get :search
      end
    end
  end
  namespace :explore do
    resources :posts, :only => [:popular, :hot] do
      collection do
        get :popular
        get :hot
        get :intro
      end
    end
  end
  namespace :maintenance do
    namespace :user do
      resource :password_reset, :only => [:new, :create, :edit, :update]
      resource :login_reminder, :only => [:new, :create]
      resource :deletion, :only => [:show, :destroy]
      resource :email_change, :only => [:new, :create]
    end
  end

  resources :advertisements do
    resources :hits, :controller => "advertisement_hits", :only => [:create]
  end
  resources :artists do
    member do
      put :revert
      put :ban
      put :unban
      post :undelete
    end
    collection do
      get :show_or_new
      get :banned
      get :finder
    end
  end
  resources :artist_versions, :only => [:index] do
    collection do
      get :search
    end
  end
  resources :bans
  resources :comments do
    resources :votes, :controller => "comment_votes", :only => [:create, :destroy]
    collection do
      get :search
      get :index_all
    end
    member do
      put :unvote
    end
  end
  resources :counts do
    collection do
      get :posts
    end
  end
  resources :delayed_jobs, :only => [:index]
  resources :dmails do
    collection do
      get :search
      post :mark_all_as_read
    end
  end
  resource  :dtext_preview, :only => [:create]
  resources :favorites
  resources :forum_posts do
    member do
      post :undelete
    end
    collection do
      get :search
    end
  end
  resources :forum_topics do
    member do
      post :undelete
    end
    collection do
      post :mark_all_as_read
    end
  end
  resources :ip_bans
  resources :janitor_trials do
    collection do
      get :test
    end
    member do
      put :promote
      put :demote
    end
  end
  resources :jobs
  resource :landing
  resources :mod_actions
  resources :news_updates
  resources :notes do
    collection do
      get :search
    end
    member do
      put :revert
    end
  end
  resources :note_versions, :only => [:index]
  resource :note_previews, :only => [:show]
  resources :pools do
    member do
      put :revert
      post :undelete
    end
    resource :order, :only => [:edit, :update], :controller => "PoolOrders"
  end
  resource  :pool_element, :only => [:create, :destroy] do
    collection do
      get :all_select
    end
  end
  resources :pool_versions, :only => [:index]
  resources :posts do
    resources :votes, :controller => "post_votes", :only => [:create, :destroy]
    collection do
      get :home
      get :random
    end
    member do
      put :revert
      put :copy_notes
      get :show_seq
      put :unvote
    end
  end
  resources :post_appeals
  resources :post_flags
  resources :post_versions, :only => [:index, :search] do
    member do
      put :undo
    end
    collection do
      get :search
    end
  end
  resources :artist_commentaries do
    collection do
      put :create_or_update
      get :search
    end
    member do
      put :revert
    end
  end
  resources :artist_commentary_versions, :only => [:index]
  resource :related_tag, :only => [:show]
  match "reports/user_promotions" => "reports#user_promotions"
  resource :session do
    collection do
      get :sign_out
    end
  end
  resource :source, :only => [:show]
  resources :tags do
    resource :correction, :only => [:new, :create, :show], :controller => "TagCorrections"
  end
  resources :tag_aliases do
    resource :correction, :only => [:create, :new, :show], :controller => "TagAliasCorrections"
    member do
      post :approve
    end
  end
  resource :tag_alias_request, :only => [:new, :create]
  resources :tag_implications do
    member do
      post :approve
    end
  end
  resource :tag_implication_request, :only => [:new, :create]
  resources :tag_subscriptions do
    member do
      get :posts
    end
  end
  resources :uploads
  resources :users do
    collection do
      get :upgrade_information
      get :search
      get :custom_style
    end

    member do
      delete :cache
      post :upgrade
    end
  end
  resources :user_feedbacks do
    collection do
      get :search
    end
  end
  resources :user_name_change_requests do
    member do
      post :approve
      post :reject
    end
  end
  resources :wiki_pages do
    member do
      put :revert
    end
    collection do
      get :search
      get :show_or_new
    end
  end
  resources :wiki_page_versions, :only => [:index, :show, :diff] do
    collection do
      get :diff
    end
  end

  # aliases
  resources :wpages, :controller => "wiki_pages"
  resources :ftopics, :controller => "forum_topics"
  resources :fposts, :controller => "forum_posts"
  match "/m/posts", :controller => "mobile/posts", :action => "index"
  match "/m/posts/:id", :controller => "mobile/posts", :action => "show"

  # legacy aliases
  match "/artist" => redirect {|params, req| "/booru/artists?page=#{req.params[:page]}&search[name]=#{CGI::escape(req.params[:name].to_s)}"}
  match "/artist/index.xml", :controller => "legacy", :action => "artists", :format => "xml"
  match "/artist/index.json", :controller => "legacy", :action => "artists", :format => "json"
  match "/artist/index" => redirect {|params, req| "/booru/artists?page=#{req.params[:page]}"}
  match "/artist/show/:id" => redirect("/booru/artists/%{id}")
  match "/artist/show" => redirect {|params, req| "/booru/artists?name=#{CGI::escape(req.params[:name].to_s)}"}
  match "/artist/history/:id" => redirect("/booru/artist_versions?search[artist_id]=%{id}")
  match "/artist/update/:id" => redirect("/booru/artists/%{id}")
  match "/artist/destroy/:id" => redirect("/booru/artists/%{id}")
  match "/artist/recent_changes" => redirect("/booru/artist_versions")
  match "/artist/create" => redirect("/booru/artists")

  match "/comment" => redirect {|params, req| "/booru/comments?page=#{req.params[:page]}"}
  match "/comment/index" => redirect {|params, req| "/booru/comments?page=#{req.params[:page]}"}
  match "/comment/show/:id" => redirect("/booru/comments/%{id}")
  match "/comment/new" => redirect("/booru/comments")
  match("/comment/search" => redirect do |params, req|
    if req.params[:query] =~ /^user:(.+)/i
      "/booru/comments?group_by=comment&search[creator_name]=#{CGI::escape($1)}"
    else
      "/booru/comments/search"
    end
  end)

  match "/favorite" => redirect {|params, req| "/booru/favorites?page=#{req.params[:page]}"}
  match "/favorite/index" => redirect {|params, req| "/booru/favorites?page=#{req.params[:page]}"}
  match "/favorite/list_users.json", :controller => "legacy", :action => "unavailable"

  match "/forum" => redirect {|params, req| "/booru/forum_topics?page=#{req.params[:page]}"}
  match "/forum/index" => redirect {|params, req| "/booru/forum_topics?page=#{req.params[:page]}"}
  match "/forum/show/:id" => redirect {|params, req| "/booru/forum_posts/#{req.params[:id]}?page=#{req.params[:page]}"}
  match "/forum/search" => redirect("/booru/forum_posts/search")
  match "/forum/new" => redirect("/booru/forum_posts/new")
  match "/forum/edit/:id" => redirect("/booru/forum_posts/%{id}/edit")

  match "/help/:title" => redirect {|params, req| ("/booru/wiki_pages?title=#{CGI::escape('help:' + req.params[:title])}")}

  match "/note" => redirect {|params, req| "/notes?page=#{req.params[:page]}"}
  match "/note/index" => redirect {|params, req| "/notes?page=#{req.params[:page]}"}
  match "/note/history" => redirect {|params, req| "/booru/note_versions?search[updater_id]=#{req.params[:user_id]}"}

  match "/pool" => redirect {|params, req| "/booru/pools?page=#{req.params[:page]}"}
  match "/pool/index" => redirect {|params, req| "/booru/pools?page=#{req.params[:page]}"}
  match "/pool/show/:id" => redirect("/booru/pools/%{id}")
  match "/pool/history/:id" => redirect("/booru/pool_versions?search[pool_id]=%{id}")
  match "/pool/recent_changes" => redirect("/booru/pool_versions")

  match "/post/index.xml", :controller => "legacy", :action => "posts", :format => "xml"
  match "/post/index.json", :controller => "legacy", :action => "posts", :format => "json"
  match "/post/create.xml", :controller => "legacy", :action => "create_post", :format => "xml"
  match "/post/piclens", :controller => "legacy", :action => "unavailable"
  match "/post/index" => redirect {|params, req| "/booru/posts?tags=#{CGI::escape(req.params[:tags].to_s)}&page=#{req.params[:page]}"}
  match "/post" => redirect {|params, req| "/booru/posts?tags=#{CGI::escape(req.params[:tags].to_s)}&page=#{req.params[:page]}"}
  match "/post/upload" => redirect("/booru/uploads/new")
  match "/post/moderate" => redirect("/booru/moderator/post/queue")
  match "/post/atom" => redirect {|params, req| "/booru/posts.atom?tags=#{CGI::escape(req.params[:tags].to_s)}"}
  match "/post/atom.feed" => redirect {|params, req| "/booru/posts.atom?tags=#{CGI::escape(req.params[:tags].to_s)}"}
  match "/post/popular_by_day" => redirect("/booru/explore/posts/popular")
  match "/post/popular_by_week" => redirect("/booru/explore/posts/popular")
  match "/post/popular_by_month" => redirect("/booru/explore/posts/popular")
  match "/post/show/:id/:tag_title" => redirect("/booru/posts/%{id}")
  match "/post/show/:id" => redirect("/booru/posts/%{id}")
  match "/post/show" => redirect {|params, req| "/booru/posts?md5=#{req.params[:md5]}"}
  match "/post/view/:id/:tag_title" => redirect("/booru/posts/%{id}")
  match "/post/view/:id" => redirect("/booru/posts/%{id}")
  match "/post/flag/:id" => redirect("/booru/posts/%{id}")

  match("/post_tag_history" => redirect do |params, req|
    page = req.params[:before_id].present? ? "b#{req.params[:before_id]}" : req.params[:page]
    "/booru/post_versions?page=#{page}&search[updater_id]=#{req.params[:user_id]}"
  end)
  match "/post_tag_history/index" => redirect {|params, req| "/booru/post_versions?page=#{req.params[:page]}&search[post_id]=#{req.params[:post_id]}"}

  match "/tag/index.xml", :controller => "legacy", :action => "tags", :format => "xml"
  match "/tag/index.json", :controller => "legacy", :action => "tags", :format => "json"
  match "/tag" => redirect {|params, req| "/booru/tags?page=#{req.params[:page]}&search[name_matches]=#{CGI::escape(req.params[:name].to_s)}&search[order]=#{req.params[:order]}&search[category]=#{req.params[:type]}"}
  match "/tag/index" => redirect {|params, req| "/booru/tags?page=#{req.params[:page]}&search[name_matches]=#{CGI::escape(req.params[:name].to_s)}&search[order]=#{req.params[:order]}"}

  match "/tag_implication" => redirect {|params, req| "/booru/tag_implications?search[name_matches]=#{CGI::escape(req.params[:query].to_s)}"}

  match "/user/index.xml", :controller => "legacy", :action => "users", :format => "xml"
  match "/user/index.json", :controller => "legacy", :action => "users", :format => "json"
  match "/user" => redirect {|params, req| "/booru/users?page=#{req.params[:page]}"}
  match "/user/index" => redirect {|params, req| "/booru/users?page=#{req.params[:page]}"}
  match "/user/show/:id" => redirect("/booru/users/%{id}")
  match "/user/login" => redirect("/booru/sessions/new")
  match "/user_record" => redirect {|params, req| "/booru/user_feedbacks?search[user_id]=#{req.params[:user_id]}"}

  match "/wiki" => redirect {|params, req| "/booru/wiki_pages?page=#{req.params[:page]}"}
  match "/wiki/index" => redirect {|params, req| "/booru/wiki_pages?page=#{req.params[:page]}"}
  match "/wiki/revert" => redirect("/booru/wiki_pages")
  match "/wiki/rename" => redirect("/booru/wiki_pages")
  match "/wiki/show" => redirect {|params, req| "/booru/wiki_pages?title=#{CGI::escape(req.params[:title].to_s)}"}
  match "/wiki/recent_changes" => redirect {|params, req| "/booru/wiki_page_versions?search[updater_id]=#{req.params[:user_id]}"}
  match "/wiki/history/:title" => redirect("/booru/wiki_page_versions?title=%{title}")

  match "/static/keyboard_shortcuts" => "static#keyboard_shortcuts", :as => "keyboard_shortcuts"
  match "/static/bookmarklet" => "static#bookmarklet", :as => "bookmarklet"
  match "/static/site_map" => "static#site_map", :as => "site_map"
  match "/static/terms_of_service" => "static#terms_of_service", :as => "terms_of_service"
  match "/static/accept_terms_of_service" => "static#accept_terms_of_service", :as => "accept_terms_of_service"
  match "/static/mrtg" => "static#mrtg", :as => "mrtg"
  match "/static/contact" => "static#contact", :as => "contact"
  match "/static/benchmark" => "static#benchmark"
  match "/static/name_change" => "static#name_change", :as => "name_change"
  match "/meta_searches/tags" => "meta_searches#tags", :as => "meta_searches_tags"

  root :to => "posts#index"
end

# SCRIPT_NAME hack for Rails < 4.0
# <https://github.com/rails/rails/issues/6933#issuecomment-7654247>
Rails.application.routes.default_url_options[:script_name] = '/booru'
