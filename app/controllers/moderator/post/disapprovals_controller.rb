module Moderator
  module Post
    class DisapprovalsController < ApplicationController
      before_filter :post_approvers_only

      def create
        @post = ::Post.find(params[:post_id])
        @post_disapproval = PostDisapproval.create(:post => @post, :user => CurrentUser.user, :reason => params[:reason] || "disinterest", :message => params[:message])
      end
    end
  end
end
