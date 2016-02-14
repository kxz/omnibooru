require 'test_helper'

class ArtistTest < ActiveSupport::TestCase
  def assert_artist_found(expected_name, source_url)
    VCR.use_cassette("unit/artist/#{Digest::SHA1.hexdigest(source_url)}", :record => :none) do
      artists = Artist.url_matches(source_url).to_a

      assert_equal(1, artists.size)
      assert_equal(expected_name, artists.first.name, "Testing URL: #{source_url}")
    end
  end

  def assert_artist_not_found(source_url)
    VCR.use_cassette("unit/artist/#{Digest::SHA1.hexdigest(source_url)}", :record => :none) do
      artists = Artist.find_all_by_url(source_url)
      assert_equal(0, artists.size, "Testing URL: #{source_url}")
    end
  end

  context "An artist" do
    setup do
      user = Timecop.travel(1.month.ago) {FactoryGirl.create(:user)}
      CurrentUser.user = user
      CurrentUser.ip_addr = "127.0.0.1"
      MEMCACHE.flush_all
      Delayed::Worker.delay_jobs = false
    end

    teardown do
      CurrentUser.user = nil
      CurrentUser.ip_addr = nil
    end

    should "should have a valid name" do
      @artist = Artist.new(:name => "-blah")
      @artist.save
      assert_equal(["Name cannot begin with - or ~"], @artist.errors.full_messages)
    end

    context "with a matching tag alias" do
      setup do
        @tag_alias = FactoryGirl.create(:tag_alias, :antecedent_name => "aaa", :consequent_name => "bbb")
        @artist = FactoryGirl.create(:artist, :name => "aaa")
      end

      should "know it has an alias" do
        assert_equal(true, @artist.has_tag_alias?)
      end

      should "know its alias" do
        assert_equal("bbb", @artist.tag_alias_name)
      end
    end

    context "that has been banned" do
      setup do
        @post = FactoryGirl.create(:post, :tag_string => "aaa")
        @artist = FactoryGirl.create(:artist, :name => "aaa")
        @artist.ban!
        @post.reload
      end

      should "allow unbanning" do
        assert_difference("TagImplication.count", -1) do
          @artist.unban!
        end
        @post.reload
        @artist.reload
        assert(!@artist.is_banned?, "artist should not be banned")
        assert(!@post.is_banned?, "post should not be banned")
        assert_equal("aaa", @post.tag_string)
      end

      should "ban the post" do
        assert(@post.is_banned?)
      end

      should "not delete the post" do
        refute(@post.is_deleted?)
      end

      should "create a new tag implication" do
        assert_equal(1, TagImplication.where(:antecedent_name => "aaa", :consequent_name => "banned_artist").count)
        assert_equal("aaa banned_artist", @post.tag_string)
      end
    end

    should "create a new wiki page to store any note information" do
      artist = nil
      assert_difference("WikiPage.count") do
        artist = FactoryGirl.create(:artist, :name => "aaa", :notes => "testing")
      end
      assert_equal("testing", artist.notes)
      assert_equal("testing", artist.wiki_page.body)
      assert_equal(artist.name, artist.wiki_page.title)
    end

    should "update the wiki page when notes are assigned" do
      artist = FactoryGirl.create(:artist, :name => "aaa", :notes => "testing")
      artist.update_attribute(:notes, "kokoko")
      artist.reload
      assert_equal("kokoko", artist.notes)
      assert_equal("kokoko", artist.wiki_page.body)
    end

    should "normalize its name" do
      artist = FactoryGirl.create(:artist, :name => "  AAA BBB  ")
      assert_equal("aaa_bbb", artist.name)
    end

    should "resolve ambiguous urls" do
      bobross = FactoryGirl.create(:artist, :name => "bob_ross", :url_string => "http://artists.com/bobross/image.jpg")
      bob = FactoryGirl.create(:artist, :name => "bob", :url_string => "http://artists.com/bob/image.jpg")
      matches = Artist.find_all_by_url("http://artists.com/bob/test.jpg")
      assert_equal(1, matches.size)
      assert_equal("bob", matches.first.name)
    end

    should "parse urls" do
      artist = FactoryGirl.create(:artist, :name => "rembrandt", :url_string => "http://rembrandt.com/test.jpg http://aaa.com")
      artist.reload
      assert_equal(["http://aaa.com", "http://rembrandt.com/test.jpg"], artist.urls.map(&:to_s).sort)
    end

    should "make sure old urls are deleted" do
      artist = FactoryGirl.create(:artist, :name => "rembrandt", :url_string => "http://rembrandt.com/test.jpg")
      artist.url_string = "http://not.rembrandt.com/test.jpg"
      artist.save
      artist.reload
      assert_equal(["http://not.rembrandt.com/test.jpg"], artist.urls.map(&:to_s).sort)
    end

    should "not delete urls that have not changed" do
      artist = FactoryGirl.create(:artist, :name => "rembrandt", :url_string => "http://rembrandt.com/test.jpg")
      old_url_ids = ArtistUrl.order("id").pluck(&:id)
      artist.url_string = "http://rembrandt.com/test.jpg"
      artist.save
      assert_equal(old_url_ids, ArtistUrl.order("id").pluck(&:id))
    end

    should "ignore pixiv.net/ and pixiv.net/img/ url matches" do
      a1 = FactoryGirl.create(:artist, :name => "yomosaka", :url_string => "http://i2.pixiv.net/img100/img/yomosaka/27618292.jpg")
      a2 = FactoryGirl.create(:artist, :name => "niwatazumi_bf", :url_string => "http://i2.pixiv.net/img16/img/niwatazumi_bf/35488864_big_p6.jpg")
      assert_equal([], Artist.find_all_by_url("http://i2.pixiv.net/img28/img/kyang692/35563903.jpg"))
    end

    should "find matches by url" do
      a1 = FactoryGirl.create(:artist, :name => "rembrandt", :url_string => "http://rembrandt.com/x/test.jpg")
      a2 = FactoryGirl.create(:artist, :name => "subway", :url_string => "http://subway.com/x/test.jpg")
      a3 = FactoryGirl.create(:artist, :name => "minko", :url_string => "https://minko.com/x/test.jpg")

      assert_equal(["rembrandt"], Artist.find_all_by_url("http://rembrandt.com/x/test.jpg").map(&:name))
      assert_equal(["rembrandt"], Artist.find_all_by_url("http://rembrandt.com/x/another.jpg").map(&:name))
      assert_equal([], Artist.find_all_by_url("http://nonexistent.com/test.jpg").map(&:name))
      assert_equal(["minko"], Artist.find_all_by_url("https://minko.com/x/test.jpg").map(&:name))
      assert_equal(["minko"], Artist.find_all_by_url("http://minko.com/x/test.jpg").map(&:name))
    end

    should "not allow duplicates" do
      FactoryGirl.create(:artist, :name => "warhol", :url_string => "http://warhol.com/x/a/image.jpg\nhttp://warhol.com/x/b/image.jpg")
      assert_equal(["warhol"], Artist.find_all_by_url("http://warhol.com/x/test.jpg").map(&:name))
    end

    should "hide deleted artists" do
      FactoryGirl.create(:artist, :name => "warhol", :url_string => "http://warhol.com/a/image.jpg", :is_active => false)
      assert_equal([], Artist.find_all_by_url("http://warhol.com/a/image.jpg").map(&:name))
    end

    context "when finding deviantart artists" do
      setup do
        FactoryGirl.create(:artist, :name => "artgerm", :url_string => "http://artgerm.deviantart.com/")
        FactoryGirl.create(:artist, :name => "trixia",  :url_string => "http://trixdraws.deviantart.com/")
      end

      should "find the correct artist for page URLs" do
        assert_artist_found("artgerm", "http://artgerm.deviantart.com/art/Peachy-Princess-Ver-2-457220550")

        assert_artist_found("trixia", "http://trixdraws.deviantart.com/art/My-Queen-426745289")
        assert_artist_found("trixia", "http://trixdraws.deviantart.com/gallery/#/d722mrt")
      end

      should_eventually "find the correct artist for image URLs" do
        assert_artist_found("artgerm", "http://th05.deviantart.net/fs71/200H/f/2014/150/d/c/peachy_princess_by_artgerm-d7k7tmu.jpg")
        assert_artist_found("artgerm", "http://th05.deviantart.net/fs71/PRE/f/2014/150/d/c/peachy_princess_by_artgerm-d7k7tmu.jpg")
        assert_artist_found("artgerm", "http://fc06.deviantart.net/fs71/f/2014/150/d/c/peachy_princess_by_artgerm-d7k7tmu.jpg")

        assert_artist_found("trixia", "http://fc01.deviantart.net/fs71/i/2014/050/d/e/my_queen_by_trixdraws-d722mrt.jpg")
        assert_artist_found("trixia", "http://th01.deviantart.net/fs71/200H/i/2014/050/d/e/my_queen_by_trixdraws-d722mrt.jpg")
        assert_artist_found("trixia", "http://th09.deviantart.net/fs71/PRE/i/2014/050/d/e/my_queen_by_trixdraws-d722mrt.jpg")
      end
    end

    context "when finding pixiv artists" do
      setup do
        FactoryGirl.create(:artist, :name => "masao",:url_string => "http://i2.pixiv.net/img04/img/syounen_no_uta/")
        FactoryGirl.create(:artist, :name => "bkub", :url_string => "http://i1.pixiv.net/img01/img/bkubb/")
        FactoryGirl.create(:artist, :name => "ryuura", :url_string => "http://www.pixiv.net/member.php?id=8678371")
      end

      should "find the correct artist by looking up the profile url" do
        assert_artist_found("ryuura", "http://www.pixiv.net/member_illust.php?mode=medium&illust_id=48788677")
      end

      should "find the correct artist for old image URLs" do
        assert_artist_found("masao", "http://i2.pixiv.net/img04/img/syounen_no_uta/46170939.jpg")
        assert_artist_found("bkub",  "http://i1.pixiv.net/img01/img/bkubb/46239857_m.jpg")
      end

      should "find the correct artist for new image URLs" do
        assert_artist_found("masao", "http://i2.pixiv.net/c/1200x1200/img-master/img/2014/09/25/00/57/24/46170939_p0_master1200.jpg")
        assert_artist_found("masao", "http://i2.pixiv.net/img-original/img/2014/09/25/00/57/24/46170939_p0.jpg")

        assert_artist_found("bkub",  "http://i2.pixiv.net/c/1200x1200/img-master/img/2014/09/28/21/59/44/46239857_p0.jpg")
        assert_artist_found("bkub",  "http://i2.pixiv.net/img-original/img/2014/09/28/21/59/44/46239857_p0.jpg")
      end

      should "find the correct artist for page URLs" do
        assert_artist_found("masao", "http://www.pixiv.net/member_illust.php?mode=medium&illust_id=46170939")
        assert_artist_found("masao", "http://www.pixiv.net/member_illust.php?mode=big&illust_id=46170939")
        assert_artist_found("masao", "http://www.pixiv.net/member_illust.php?mode=manga&illust_id=46170939")
        assert_artist_found("masao", "http://www.pixiv.net/member_illust.php?mode=manga_big&illust_id=46170939&page=0")
        assert_artist_found("masao", "http://www.pixiv.net/i/46170939")

        assert_artist_found("bkub",  "http://www.pixiv.net/member_illust.php?mode=medium&illust_id=46239857")
        assert_artist_found("bkub",  "http://www.pixiv.net/member_illust.php?mode=big&illust_id=46239857")
        assert_artist_found("bkub",  "http://www.pixiv.net/i/46239857")
      end

      should "find nothing for malformed URLs" do
        assert_artist_not_found("http://www.pixiv.net/member_illust.php?mode=medium&illust_id=herpderp")
        assert_artist_not_found("http://www.pixiv.net/wharrgarbl")
      end

      should "find nothing for bad IDs" do
        assert_artist_not_found("http://www.pixiv.net/member_illust.php?mode=medium&illust_id=32049358")
      end
    end

    should "normalize its other names" do
      artist = FactoryGirl.create(:artist, :name => "a1", :other_names_comma => "aaa, bbb, ccc ddd")
      assert_equal("aaa, bbb, ccc_ddd", artist.other_names_comma)
    end

    should "search on its name should return results" do
      artist = FactoryGirl.create(:artist, :name => "artist")
      assert_not_nil(Artist.search(:name => "artist").first)
    end

    should "search on other names should return matches" do
      artist = FactoryGirl.create(:artist, :name => "artist", :other_names_comma => "aaa, ccc ddd")
      assert_nil(Artist.other_names_match("artist").first)
      assert_not_nil(Artist.other_names_match("aaa").first)
      assert_not_nil(Artist.other_names_match("ccc_ddd").first)
      assert_not_nil(Artist.search(:name => "other:aaa").first)
      assert_not_nil(Artist.search(:name => "aaa").first)
    end

    should "search on group name and return matches" do
      cat_or_fish = FactoryGirl.create(:artist, :name => "cat_or_fish")
      yuu = FactoryGirl.create(:artist, :name => "yuu", :group_name => "cat_or_fish")
      cat_or_fish.reload
      assert_equal("yuu", cat_or_fish.member_names)
      assert_not_nil(Artist.search(:name => "group:cat_or_fish").first)
    end

    should "have an associated wiki" do
      user = FactoryGirl.create(:user)
      CurrentUser.user = user
      artist = FactoryGirl.create(:artist, :name => "max", :wiki_page_attributes => {:title => "xxx", :body => "this is max"})
      assert_not_nil(artist.wiki_page)
      assert_equal("this is max", artist.wiki_page.body)

      artist.update_attributes({:wiki_page_attributes => {:id => artist.wiki_page.id, :body => "this is hoge mark ii"}})
      assert_equal("this is hoge mark ii", artist.wiki_page(true).body)
      CurrentUser.user = nil
    end

    should "revert to prior versions" do
      user = FactoryGirl.create(:user)
      reverter = FactoryGirl.create(:user)
      artist = nil
      assert_difference("ArtistVersion.count") do
        artist = FactoryGirl.create(:artist, :other_names => "yyy")
      end

      assert_difference("ArtistVersion.count") do
        artist.other_names = "xxx"
        Timecop.travel(1.day.from_now) do
          artist.save
        end
      end

      first_version = ArtistVersion.first
      assert_equal("yyy", first_version.other_names)
      artist.revert_to!(first_version)
      artist.reload
      assert_equal("yyy", artist.other_names)
    end

    should "update the category of the tag when created" do
      tag = FactoryGirl.create(:tag, :name => "abc")
      artist = FactoryGirl.create(:artist, :name => "abc")
      tag.reload
      assert_equal(Tag.categories.artist, tag.category)
    end

    should "update the category of the tag when renamed" do
      tag = FactoryGirl.create(:tag, :name => "def")
      artist = FactoryGirl.create(:artist, :name => "abc")
      artist.name = "def"
      artist.save
      tag.reload
      assert_equal(Tag.categories.artist, tag.category)
    end
  end
end
