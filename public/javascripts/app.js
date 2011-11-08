$(document).ready(function() {
  $("input#monthly_radio").click(function() {
    $("div#class_package_select").hide();
    $("div#monthly_select").show();
  })
  $("input#class_package_radio").click(function() {
    $("div#monthly_select").hide();
    $("div#class_package_select").show();
  })
});
