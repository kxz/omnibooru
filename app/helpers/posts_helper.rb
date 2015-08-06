module PostsHelper
  def post_search_count_js
    return nil unless Danbooru.config.enable_post_search_counts
    
    if action_name == "index" && params[:page].nil?
      tags = Tag.scan_query(params[:tags]).sort.join(" ")

      if tags.present?
        key = "ps-#{tags}"
        value = session.id
        digest = OpenSSL::Digest.new("sha256")
        sig = OpenSSL::HMAC.hexdigest(digest, Danbooru.config.shared_remote_key, "#{key},#{value}")
        return render("posts/partials/index/search_count", key: key, value: value, sig: sig)
      end
    end

    return nil
  end

  def resize_image_links(post, user)
    links = []

    if post.has_large?
      links << link_to("L", post.large_file_url, :id => "large-file-link")
    end

    if post.has_large?
      links << link_to("O", post.file_url, :id => "original-file-link")
    end

    if links.any?
      content_tag("span", raw("Resize: " + links.join(" ")))
    else
      nil
    end
  end

  def post_source_tag(post)
    if post.source =~ %r!\Ahttp://img\d+\.pixiv\.net/img/([^\/]+)/!i
      text = "pixiv/<wbr>#{wordbreakify($1)}".html_safe
      source_search = "source:pixiv/#{$1}/"
    elsif post.source =~ %r!\Ahttp://i\d\.pixiv\.net/img\d+/img/([^\/]+)/!i
      text = "pixiv/<wbr>#{wordbreakify($1)}".html_safe
      source_search = "source:pixiv/#{$1}/"
    elsif post.source =~ %r{\Ahttps?://}i
      text = post.normalized_source.sub(/\Ahttps?:\/\/(?:www\.)?/i, "")
      text = truncate(text, length: 20)
      source_search = "source:#{post.source.sub(/[^\/]*$/, "")}"
    end

    # Only allow http:// and https:// links. Disallow javascript: links.
    if post.normalized_source =~ %r!\Ahttps?://!i
      source_link = link_to(text, post.normalized_source)
    else
      source_link = truncate(post.source, :length => 100)
    end

    if CurrentUser.is_builder? && !source_search.blank?
      source_link + "&nbsp;".html_safe + link_to("&raquo;".html_safe, posts_path(:tags => source_search))
    else
      source_link
    end
  end

  def post_favlist(post)
    post.favorited_users.reverse_each.map{|user| link_to_user(user)}.join(", ").html_safe
  end

  def has_parent_message(post, parent_post_set)
    html = ""

    html << "This post belongs to a "
    html << link_to("parent", posts_path(:tags => "parent:#{post.parent_id}"))
    html << " (deleted)" if parent_post_set.parent.first.is_deleted?

    sibling_count = parent_post_set.children.count - 1
    if sibling_count > 0
      html << " and has "
      text = sibling_count == 1 ? "a sibling" : "#{sibling_count} siblings"
      html << link_to(text, posts_path(:tags => "parent:#{post.parent_id}"))
    end

    html << " (#{link_to("learn more", wiki_pages_path(:title => "help:post_relationships"))}) "

    html << link_to("&laquo; hide".html_safe, "#", :id => "has-parent-relationship-preview-link")

    html.html_safe
  end

  def has_children_message(post, children_post_set)
    html = ""

    html << "This post has "
    text = children_post_set.children.count == 1 ? "a child" : "#{children_post_set.children.count} children"
    html << link_to(text, posts_path(:tags => "parent:#{post.id}"))

    html << " (#{link_to("learn more", wiki_pages_path(:title => "help:post_relationships"))}) "

    html << link_to("&laquo; hide".html_safe, "#", :id => "has-children-relationship-preview-link")

    html.html_safe
  end
end
