$(function() {
  // Table striping
  $(".striped tbody tr:even").addClass("even");
  $(".striped tbody tr:odd").addClass("odd");

  // Account notices
  $("#hide-dmail-notice").click(function(e) {
    var $dmail_notice = $("#dmail-notice");
    $dmail_notice.hide();
    var dmail_id = $dmail_notice.data("id");
    Danbooru.Cookie.put("hide_dmail_notice", dmail_id);
    e.preventDefault();
  });

  $("#close-notice-link").click(function(e) {
    $('#notice').fadeOut("fast");
    e.preventDefault();
  });
});

var Danbooru = {};
