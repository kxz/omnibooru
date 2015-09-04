module Sources
  module Strategies
    class DeviantArt < Base
      def self.url_match?(url)
        url =~ /^https?:\/\/(?:.+?\.)?deviantart\.(?:com|net)/
      end

      def referer_url
        if @referer_url =~ /deviantart\.com\/art\// && @url =~ /https?:\/\/(?:fc|th|pre|orig|img)\d{2}\.deviantart\.net\//
          @referer_url
        else
          @url
        end
      end

      def site_name
        "Deviant Art"
      end

      def unique_id
        profile_url =~ /https?:\/\/(.+?)\.deviantart\.com/
        "deviantart" + $1
      end

      def get
        agent.get(URI.parse(normalized_url)) do |page|
          @artist_name, @profile_url = get_profile_from_page(page)
          @image_url = get_image_url_from_page(page)
          @tags = get_tags_from_page(page)
          @artist_commentary_title = get_artist_commentary_title_from_page(page)
          @artist_commentary_desc = get_artist_commentary_desc_from_page(page)
        end
      end

    protected

      def get_profile_from_page(page)
        links = page.search("div.dev-title-container a.username")

        if links.any?
          profile_url = links[0]["href"]
          artist_name = links[0].text
        else
          profile_url = nil
          artist_name = nil
        end

        return [artist_name, profile_url].compact
      end

      def get_image_url_from_page(page)
        download_link = page.link_with(:class => /dev-page-download/)

        if download_link
          download_link.click.uri.to_s # need to follow the redirect now to get the full size url, following it later seems to not work.
        else
          image = page.search("div.dev-view-deviation img.dev-content-full")

          if image.any?
            image[0]["src"]
          else
            nil
          end
        end
      end

      def get_tags_from_page(page)
        links = page.search("a.discoverytag")

        links.map do |node|
          [node.attr("data-canonical-tag"), node.attr("href")]
        end
      end

      def get_artist_commentary_title_from_page(page)
        title = page.search("div.dev-title-container a").find_all do |node|
          node["data-ga_click_event"] =~ /description_title/
        end

        if title.any?
          title[0].inner_text
        end
      end

      def get_artist_commentary_desc_from_page(page)
        desc = page.search("div.dev-description div.text.block")

        if desc.any?
          desc[0].inner_text
        end
      end

      def normalized_url
        @normalized_url ||= begin
          if url =~ %r{\Ahttps?://(?:fc|th|pre|orig|img)\d{2}\.deviantart\.net/.+/[a-z0-9_]*_by_[a-z0-9_]+-d([a-z0-9]+)\.}i
            "http://fav.me/d#{$1}"
          elsif url =~ %r{\Ahttps?://(?:fc|th|pre|orig|img)\d{2}\.deviantart\.net/.+/[a-f0-9]+-d([a-z0-9]+)\.}i
            "http://fav.me/d#{$1}"
          elsif url =~ %r{deviantart\.com/art/}
            url
          else
            nil
          end
        end
      end

      def agent
        @agent ||= Mechanize.new
      end
    end
  end
end
