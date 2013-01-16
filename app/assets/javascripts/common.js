$(function() {
  // Table striping
  $(".striped tbody tr:even").addClass("even");
  $(".striped tbody tr:odd").addClass("odd");

  // More link
  if ($("#site-map-link").length > 0) {
    $("#site-map-link").click(function(e) {
      $("#more-links").toggle();
      e.preventDefault();
      e.stopPropagation();
    });

    $("#more-links").show();
    $("#more-links").position({
      of: $("#site-map-link"),
      my: "left top",
      at: "left top"
    }).hide();

    $(document).click(function(e) {
      $("#more-links").hide();
    });
  }

  // Account notices
  $("#hide-sign-up-notice").click(function(e) {
    $("#sign-up-notice").hide();
    Danbooru.Cookie.put("hide_sign_up_notice", "1", 7);
    e.preventDefault();
  });

  $("#hide-upgrade-account-notice").click(function(e) {
    $("#upgrade-account-notice").hide();
    Danbooru.Cookie.put('hide_upgrade_account_notice', '1', 7);
    e.preventDefault();
  });
});

var Danbooru = {};
