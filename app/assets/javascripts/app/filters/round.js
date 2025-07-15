(function() {
  Vue.filter('round', function(value, decimal, options = {}) {
    let displayStr = '';

    if (typeof(value) === 'string') {
      displayStr = parseFloat(value).toFixed(decimal);
    } else if (typeof(value) === 'number') {
      const pow = Math.pow(10, decimal);
      displayStr = (Math.round(value * pow) / pow).toFixed(decimal);
    } else {
      displayStr = value;
    }

    if (options && options.remove_trailing_zeros) {
      displayStr = displayStr.replace(/\.0+$/,'');
    }

    return displayStr;
  });
})();
