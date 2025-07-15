Vue.filter('highlight', function(text, search) {
  if (search.trim().length) {
    var regSearch = new RegExp(search, "ig");
    return text.toString().replace(regSearch, function(matched, a, b) {
      return ('<span class="highlight">' + matched + '</span>');
    });
  } else {
    return text;
  }
});