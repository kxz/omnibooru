require 'test_helper'

class BulkUpdateRequestTest < ActiveSupport::TestCase
  context "creation" do
    setup do
      CurrentUser.user = FactoryGirl.create(:user)
      CurrentUser.ip_addr = "127.0.0.1"
    end

    teardown do
      CurrentUser.user = nil
      CurrentUser.ip_addr = nil
    end

    should "create a forum topic" do
      assert_difference("ForumTopic.count", 1) do
        BulkUpdateRequest.create(:title => "abc", :reason => "zzz", :script => "create alias aaa -> bbb")
      end
    end

    context "that has an invalid alias" do
      setup do
        @alias1 = FactoryGirl.create(:tag_alias)
        @req = FactoryGirl.build(:bulk_update_request, :script => "create alias bbb -> aaa")
      end

      should "not validate" do
        assert_difference("TagAlias.count", 0) do
          @req.save
        end
        assert_equal(["Error: A tag alias for aaa already exists (create alias bbb -> aaa)"], @req.errors.full_messages)
      end
    end

    context "with an associated forum topic" do
      setup do
        @admin = FactoryGirl.create(:admin_user)
        @topic = FactoryGirl.create(:forum_topic)
        @req = FactoryGirl.create(:bulk_update_request, :script => "create alias AAA -> BBB", :forum_topic => @topic)
      end

      should "handle errors gracefully" do
        @req.stubs(:update_forum_topic_for_approve).raises(RuntimeError.new("blah"))
        assert_difference("Dmail.count", 1) do
          CurrentUser.scoped(@admin, "127.0.0.1") do
            @req.approve!
          end
        end
        assert_match(/Exception: RuntimeError/, Dmail.last.body)
        assert_match(/Message: blah/, Dmail.last.body)
      end

      should "downcase the text" do
        assert_equal("create alias aaa -> bbb", @req.script)
      end

      should "update the topic when processed" do
        assert_difference("ForumPost.count") do
          CurrentUser.scoped(@admin, "127.0.0.1") do
            @req.approve!
          end
        end
      end

      should "update the topic when rejected" do
        assert_difference("ForumPost.count") do
          @req.reject!
        end
      end
    end
  end
end
