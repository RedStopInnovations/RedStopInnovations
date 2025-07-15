(function() {
  var DEFAULT_NOT_AVAILABLE_TEXT = 'N/A';

  Vue.filter('naIfNull', function(value) {
    if (value === null) {
      return 'N/A';
    }
  });

  Vue.filter('naIfEmpty', function(value, placeholder) {
    if ((value === null) || (value === undefined) || (value.trim().length === 0) ) {
      return placeholder || DEFAULT_NOT_AVAILABLE_TEXT;
    } else {
      return value;
    }
  });
})();
