require 'test_helper'

module Sources
  class PixivTest < ActiveSupport::TestCase
    def get_source(source)
      @site = Sources::Site.new(source)
      @site.get
      @site
    end

    context "in all cases" do
      context "A whitecube page" do
        setup do
          @site = Sources::Site.new("https://www.pixiv.net/whitecube/user/277898/illust/59182257")
          @site.get
          @image_urls = @site.image_urls
        end

        should "get all the image urls" do
          assert_equal(["http://i2.pixiv.net/img-original/img/2016/09/26/21/30/41/59182257_p0.jpg"], @image_urls)
        end
      end

      context "A touch page" do
        setup do
          @site = Sources::Site.new("http://touch.pixiv.net/member_illust.php?mode=medium&illust_id=59687915")
          @image_urls = @site.get
        end

        should "get all the image urls" do
          assert_equal("http://i4.pixiv.net/img-original/img/2016/10/29/17/13/23/59687915_p0.png", @image_urls)
        end
      end

      context "A gallery page" do
        setup do
          @site = Sources::Site.new("http://www.pixiv.net/member_illust.php?mode=medium&illust_id=49270482")
          @site.get
          @image_urls = @site.image_urls
        end

        should "get all the image urls" do
          assert_equal(["http://i3.pixiv.net/img-original/img/2015/03/14/17/53/32/49270482_p0.jpg", "http://i3.pixiv.net/img-original/img/2015/03/14/17/53/32/49270482_p1.jpg"], @image_urls)
        end
      end

      context "An ugoira source site for pixiv" do
        setup do
          @site = Sources::Site.new("http://www.pixiv.net/member_illust.php?mode=medium&illust_id=46378654")
          @site.get
        end

        should "get the file url" do
          assert_equal("http://i3.pixiv.net/img-zip-ugoira/img/2014/10/05/23/42/23/46378654_ugoira1920x1080.zip", @site.file_url)
        end

        should "capture the frame data" do
          assert_equal([{"file"=>"000000.jpg", "delay"=>200}, {"file"=>"000001.jpg", "delay"=>200}, {"file"=>"000002.jpg", "delay"=>200}, {"file"=>"000003.jpg", "delay"=>200}, {"file"=>"000004.jpg", "delay"=>250}], @site.ugoira_frame_data)
        end
      end

      context "fetching source data for a new manga image" do
        setup do
          get_source("http://www.pixiv.net/member_illust.php?mode=medium&illust_id=46324488")
        end

        should "get the profile" do
          assert_equal("http://www.pixiv.net/member.php?id=339253", @site.profile_url)
        end

        should "get the artist name" do
          assert_equal("evazion", @site.artist_name)
        end

        should "get the full size image url" do
          assert_equal("http://i1.pixiv.net/img-original/img/2014/10/03/18/10/20/46324488_p0.png", @site.image_url)
        end

        should "get the page count" do
          assert_equal(3, @site.page_count)
        end

        should "get the tags" do
          pixiv_tags  = @site.tags.map(&:first)
          pixiv_links = @site.tags.map(&:last)

          assert_equal(%w(R-18G derp tag1 tag2 オリジナル), pixiv_tags)
          assert_contains(pixiv_links, /search\.php/)
        end

        should "get the artist commentary" do
          assert_not_nil(@site.artist_commentary_title)
          assert_not_nil(@site.artist_commentary_desc)
        end

        should "convert a page into a json representation" do
          assert_nothing_raised do
            @site.to_json
          end
        end
      end

      context "fetching source data for an old manga image" do
        setup do
          get_source("http://www.pixiv.net/member_illust.php?mode=medium&illust_id=45792845")
        end

        should "get the page count" do
          assert_equal(3, @site.page_count)
        end

        should "get the full size image url" do
          assert_equal("http://i2.pixiv.net/img-original/img/2014/09/05/05/53/53/45792845_p0.jpg", @site.image_url)
        end
      end

      context "fetching source data for a new illustration" do
        setup do
          get_source("http://www.pixiv.net/member_illust.php?mode=medium&illust_id=46337015")
        end

        should "get the page count" do
          assert_equal(1, @site.page_count)
        end

        should "get the full size image url" do
          assert_equal("http://i4.pixiv.net/img-original/img/2014/10/04/03/59/52/46337015_p0.png", @site.image_url)
        end
      end

      context "fetching source data for an old illustration" do
        setup do
          get_source("http://www.pixiv.net/member_illust.php?mode=medium&illust_id=14901720")
        end

        should "get the page count" do
          assert_equal(1, @site.page_count)
        end

        should "get the full size image url" do
          assert_equal("http://i1.pixiv.net/img-original/img/2010/11/30/08/39/58/14901720_p0.png", @site.image_url)
        end

        should "get the tags" do
          pixiv_tags  = @site.tags.map(&:first)
          pixiv_links = @site.tags.map(&:last)

          assert_equal(%w(derp), pixiv_tags)
          assert_contains(pixiv_links, /search\.php/)
        end
      end
    end
  end
end
