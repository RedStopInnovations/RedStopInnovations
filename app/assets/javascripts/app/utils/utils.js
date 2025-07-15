var Utils = Utils || {};

(function() {
  Utils.getQueryParameter = function(key, queryString) {
    var query = queryString || window.location.search.substring(1);

    if (typeof window.URLSearchParams === 'function') {
      return (new URLSearchParams(query)).get(key);
    } else {
      var sURLVariables = query.split(/[&||?]/),
        res;

      for (var i = 0; i < sURLVariables.length; i++) {
        var paramName = sURLVariables[i],
          sParameterName = (paramName || '').split('=');

        if (sParameterName[0] === key) {
          res = sParameterName[1];
        }
      }

      return res;
    }

  };

  /**
   * Get all query parameters from url
   * If query string is not specified, it parse current location
   * Note: not support nested parameter likes `users[]`
   *
   * @return String
   */
  Utils.getQueryParameters = function(queryString) {
    var sPageURL = queryString || window.location.search.substring(1),
      sURLVariables = sPageURL.split(/[&||?]/),
      res;

    var parameters = {};
    for (var i = 0; i < sURLVariables.length; i++) {
      var paramName = sURLVariables[i],
        sParameterName = (paramName || '').split('=');

      parameters[sParameterName[0]] = sParameterName[1];
    }

    return parameters;
  };


  /**
   * Check if Local Storage is available
   */
  Utils.isLocalStorageAvailable = function() {
    var test = (new Date).getTime().toString();
    try {
      localStorage.setItem(test, test);
      localStorage.removeItem(test);
      return true;
    } catch(e) {
      return false;
    }
  };

  Utils.truncateWords = function(str, maxLength) {
    var trimmable = '\u0009\u000A\u000B\u000C\u000D\u0020\u00A0\u1680\u180E\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200A\u202F\u205F\u2028\u2029\u3000\uFEFF';
    var reg = new RegExp('(?=[' + trimmable + '])');
    var words = str.split(reg);
    var count = 0;

    var truncated = words.filter(function(word) {
      count += word.length;
      return count <= maxLength;
    }).join('');

    if (truncated.length < str.length) {
      truncated += '...';
    }

    return truncated;
  };

  Utils.isValidEmail = function(email) {
    return App.EMAIL_REGEX.test(email);
  };

  Utils.simpleSanitizeHtmlString = function(html) {
    const map = {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#x27;',
      "/": '&#x2F;',
    };
    const reg = /[&<>"'/]/ig;
    return html.replace(reg, (match)=>(map[match]));
  }
})();
