module PoolVersionsHelper
  def pool_version_diff(pool_version)
    html = ""

    html << pool_version.changes[:added_posts].map do |post_id|
      '<ins><a href="' + Danbooru::Application.routes.url_helpers.post_path(post_id) + '">' + post_id.to_s + '</a></ins>'
    end.join(" ")

    html << " "

    html << pool_version.changes[:removed_posts].map do |post_id|
      '<del><a href="' + Danbooru::Application.routes.url_helpers.post_path(post_id) + '">' + post_id.to_s + '</a></del>'
    end.join(" ")

    return html.html_safe
  end
end
