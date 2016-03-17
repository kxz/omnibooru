class PostVotesController < ApplicationController
  before_filter :voter_only

  def create
    @post = Post.find(params[:post_id])
    @post.vote!(params[:score])
  rescue PostVote::Error => x
    @error = x
  end

protected

  def voter_only
    CurrentUser.is_voter?
  end
end
