(function() {
  Danbooru.WikiPage = {};

  Danbooru.WikiPage.initialize_all = function() {
    if ($("#c-wiki-pages").length) {
      this.initialize_typeahead();
    }
  }

  Danbooru.WikiPage.initialize_typeahead = function() {
    if (Danbooru.meta("enable-auto-complete") === "true") {
      var $fields = $("#search_title,#quick_search_title");

      $fields.autocomplete({
        minLength: 1,
        source: function(req, resp) {
          $.ajax({
            url: "/wiki_pages.json",
            data: {
              "search[title]": "*" + req.term + "*",
              "limit": 10
            },
            method: "get",
            success: function(data) {
              resp($.map(data, function(wiki_page) {
                return {
                  label: wiki_page.title.replace(/_/g, " "),
                  value: wiki_page.title,
                  category: wiki_page.category_name
                };
              }));
            }
          });
        }
      });

    var render_wiki_page = function(list, wiki_page) {
      var $link = $("<a/>").addClass("tag-type-" + wiki_page.category).text(wiki_page.label);
      return $("<li/>").data("item.autocomplete", wiki_page).append($link).appendTo(list);
    }

    $fields.each(function(i, field) {
      $(field).data("uiAutocomplete")._renderItem = render_wiki_page;
    });
    }
  }
})();

$(document).ready(function() {
  Danbooru.WikiPage.initialize_all();
});
