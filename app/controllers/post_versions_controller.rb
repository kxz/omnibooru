class PostVersionsController < ApplicationController
  respond_to :html, :xml, :json
  rescue_from ActiveRecord::StatementInvalid, :with => :rescue_exception

  def index
    @post_versions = PostVersion.search(params[:search]).order("updated_at desc, id desc").paginate(params[:page], :limit => params[:limit], :search_count => params[:search])
    respond_with(@post_versions) do |format|
      format.xml do
        render :xml => @post_versions.to_xml(:root => "post-versions")
      end
    end
  end

  def search
  end

  def undo
    @post_version = PostVersion.find(params[:id])

    if @post_version.post.visible?
      @post_version.undo!
    end

    respond_with(@post_version) do |format|
      format.js
    end
  end
end
