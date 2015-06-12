class SourcesController < ApplicationController
  # before_filter :member_only
  respond_to :json

  def show
    @source = Sources::Site.new(params[:url], :referer_url => params[:ref])
    @source.get

    respond_with(@source) do |format|
      format.json do
        render :json => @source.to_json
      end
    end
  end

private

  def rescue_exception(exception)
    respond_with do |format|
      format.json do
        render :json => {:message => exception.to_s, :backtrace => exception.backtrace}, :status => :error
      end
    end
  end
end
