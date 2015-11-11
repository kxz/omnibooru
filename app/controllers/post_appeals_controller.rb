class PostAppealsController < ApplicationController
  before_filter :member_only
  respond_to :html, :xml, :json, :js

  def new
    @post_appeal = PostAppeal.new
    respond_with(@post_appeal)
  end

  def index
    @query = PostAppeal.order("id desc").includes(:post).search(params[:search])
    @post_appeals = @query.paginate(params[:page], :limit => params[:limit])
    respond_with(@post_appeals) do |format|
      format.xml do
        render :xml => @post_appeals.to_xml(:root => "post-appeals")
      end
    end
  end

  def create
    @post_appeal = PostAppeal.create(params[:post_appeal])
    respond_with(@post_appeal)
  end

  def show
    @post_appeal = PostAppeal.find(params[:id])
    respond_with(@post_appeal)
  end

private
  def check_privilege(post_appeal)
    raise User::PrivilegeError unless (post_appeal.creator_id == CurrentUser.id || CurrentUser.is_moderator?)
  end
end
