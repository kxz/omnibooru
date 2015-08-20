module WikiPagesHelper
  def wiki_page_alias_and_implication_list(wiki_page)
    antecedent_alias = wiki_page.presenter.antecedent_tag_alias
    consequent_aliases = wiki_page.presenter.consequent_tag_aliases
    antecedent_implications = wiki_page.presenter.antecedent_tag_implications
    consequent_implications = wiki_page.presenter.consequent_tag_implications

    alias_and_implication_list(antecedent_alias, consequent_aliases, antecedent_implications, consequent_implications)
  end

  def wiki_page_post_previews(wiki_page)
    html = '<div id="wiki-page-posts">'

    if Post.fast_count(wiki_page.title) > 0
      full_link = link_to("view all", posts_path(:tags => wiki_page.title))
      html << "<h2>Posts (#{full_link})</h2>"
      html << wiki_page.post_set.presenter.post_previews_html(self)
    end
    
    html << "</div>"

    html.html_safe
  end

  def wiki_page_other_names_list(wiki_page)
    names_html = wiki_page.other_names_array.map{|name| link_to(name, "http://www.pixiv.net/search.php?s_mode=s_tag_full&word=#{u(name)}", :class => "other-name")}
    names_html.join(" ").html_safe
  end
end
