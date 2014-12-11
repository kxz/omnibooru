class SavedSearchesController < ApplicationController
  respond_to :html, :xml, :json, :js
  
  def index
    @saved_searches = saved_searches.order("tag_query")
    @categories = @saved_searches.group_by{|saved_search| saved_search.category.to_s}
    @categories = @categories.sort_by{|category, saved_searches| category.to_s}

    respond_with(@saved_searches) do |format|
      format.xml do
        render :xml => @saved_searches.to_xml(:root => "saved-searches")
      end
    end
  end

  def create
    @saved_search = saved_searches.create(:tag_query => params[:tags], :category => params[:category])
  end

  def destroy
    @saved_search = saved_searches.find(params[:id])
    @saved_search.destroy
  end

  def edit
    @saved_search = saved_searches.find(params[:id])
  end

  def update
    @saved_search = saved_searches.find(params[:id])
    @saved_search.update_attributes(params[:saved_search])
    flash[:notice] = "Saved search updated"
    respond_with(@saved_search, :location => saved_searches_path)
  end

private

  def saved_searches
    CurrentUser.user.saved_searches
  end
end
