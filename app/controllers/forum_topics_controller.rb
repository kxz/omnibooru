class ForumTopicsController < ApplicationController
  respond_to :html, :xml, :json
  before_filter :member_only, :except => [:index, :show]
  before_filter :moderator_only, :only => [:new_merge, :create_merge]
  before_filter :normalize_search, :only => :index
  before_filter :load_topic, :only => [:edit, :show, :update, :destroy, :undelete, :new_merge, :create_merge, :subscribe, :unsubscribe]
  before_filter :check_min_level, :only => [:show, :edit, :update, :new_merge, :create_merge, :destroy, :undelete, :subscribe, :unsubscribe]
  skip_before_filter :api_check

  def new
    @forum_topic = ForumTopic.new
    @forum_topic.original_post = ForumPost.new
    respond_with(@forum_topic)
  end

  def edit
    check_privilege(@forum_topic)
    respond_with(@forum_topic)
  end

  def index
    @query = ForumTopic.active.search(params[:search])
    @forum_topics = @query.includes([:creator, :updater]).order("is_sticky DESC, updated_at DESC").paginate(params[:page], :limit => per_page, :search_count => params[:search])

    respond_with(@forum_topics) do |format|
      format.json do
        render :json => @forum_topics.to_json
      end
      format.xml do
        render :xml => @forum_topics.to_xml(:root => "forum-topics")
      end
    end
  end

  def show
    unless CurrentUser.user.is_anonymous?
      @forum_topic.mark_as_read!(CurrentUser.user)
    end
    @forum_posts = ForumPost.search(:topic_id => @forum_topic.id).order("forum_posts.id").paginate(params[:page])
    @forum_posts.each # hack to force rails to eager load
    respond_with(@forum_topic)
  end

  def create
    @forum_topic = ForumTopic.create(params[:forum_topic], :as => CurrentUser.role)
    respond_with(@forum_topic)
  end

  def update
    check_privilege(@forum_topic)
    @forum_topic.update_attributes(params[:forum_topic], :as => CurrentUser.role)
    respond_with(@forum_topic)
  end

  def destroy
    check_privilege(@forum_topic)
    @forum_topic.delete!
    flash[:notice] = "Topic deleted"
    respond_with(@forum_topic)
  end

  def undelete
    check_privilege(@forum_topic)
    @forum_topic.undelete!
    flash[:notice] = "Topic undeleted"
    respond_with(@forum_topic)
  end

  def mark_all_as_read
    CurrentUser.user.update_attribute(:last_forum_read_at, Time.now)
    ForumTopicVisit.prune!(CurrentUser.user)
    redirect_to forum_topics_path, :notice => "All topics marked as read"
  end

  def new_merge
  end

  def create_merge
    @merged_topic = ForumTopic.find(params[:merged_id])
    @forum_topic.merge(@merged_topic)
    redirect_to forum_topic_path(@merged_topic)
  end

  def subscribe
    subscription = ForumSubscription.where(:forum_topic_id => @forum_topic.id, :user_id => CurrentUser.user.id).first
    unless subscription
      ForumSubscription.create(:forum_topic_id => @forum_topic.id, :user_id => CurrentUser.user.id, :last_read_at => @forum_topic.updated_at)
    end
    respond_with(@forum_topic)
  end

  def unsubscribe
    subscription = ForumSubscription.where(:forum_topic_id => @forum_topic.id, :user_id => CurrentUser.user.id).first
    if subscription
      subscription.destroy
    end
    respond_with(@forum_topic)
  end

private
  def per_page
    params[:limit] || 40
  end

  def normalize_search
    if params[:title_matches]
      params[:search] ||= {}
      params[:search][:title_matches] = params.delete(:title_matches)
    end

    if params[:title]
      params[:search] ||= {}
      params[:search][:title] = params.delete(:title)
    end
  end

  def check_privilege(forum_topic)
    if !forum_topic.editable_by?(CurrentUser.user)
      raise User::PrivilegeError
    end
  end

  def load_topic
    @forum_topic = ForumTopic.find(params[:id])
  end

  def check_min_level
    if CurrentUser.user.level < @forum_topic.min_level
      respond_with(@forum_topic) do |fmt|
        fmt.html do
          flash[:notice] = "Access denied"
          redirect_to forum_topics_path
        end

        fmt.json do
          render :nothing => true, :status => 403
        end

        fmt.xml do
          render :nothing => true, :status => 403
        end
      end

      return false
    end
  end
end
