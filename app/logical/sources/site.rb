﻿# encoding: UTF-8

module Sources
  class Site
    attr_reader :url, :strategy
    delegate :get, :get_size, :referer_url, :site_name, :artist_name, :profile_url, :image_url, :tags, :artist_record, :unique_id, :page_count, :file_url, :ugoira_frame_data, :to => :strategy

    def self.strategies
      [Strategies::Pixiv, Strategies::NicoSeiga, Strategies::DeviantArt, Strategies::Nijie, Strategies::Twitter]
    end

    def initialize(url)
      @url = url

      Site.strategies.each do |strategy|
        if strategy.url_match?(url)
          @strategy = strategy.new(url)
          break
        end
      end
    end

    def normalized_for_artist_finder?
      available? && strategy.normalized_for_artist_finder?
    end

    def normalize_for_artist_finder!
      if available? && strategy.normalizable_for_artist_finder?
        strategy.normalize_for_artist_finder!
      else
        url
      end
    rescue
      url
    end

    def translated_tags
      untranslated_tags = tags
      untranslated_tags = untranslated_tags.map(&:first)
      untranslated_tags = untranslated_tags.map do |tag|
        if tag =~ /\A(\S+?)_?\d+users入り\Z/
          $1
        else
          tag
        end
      end
      WikiPage.other_names_match(untranslated_tags).map{|wiki_page| [wiki_page.title, wiki_page.category_name]}
    end

    def to_json
      return {
        :artist_name => artist_name,
        :profile_url => profile_url,
        :image_url => image_url,
        :tags => tags,
        :translated_tags => translated_tags,
        :danbooru_name => artist_record.try(:first).try(:name),
        :danbooru_id => artist_record.try(:first).try(:id),
        :unique_id => unique_id,
        :page_count => page_count
      }.to_json
    end

    def available?
      strategy.present?
    end
  end
end
