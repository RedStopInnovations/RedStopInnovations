(function() {
  /* Meters to kilometers */
  Vue.filter('m2km', function(metters, precision) {
    if (!precision) {
        precision = 2;
    }
    if ((metters != null) && (metters != undefined)) {
      return parseFloat((metters / 1000).toFixed(precision));
    }
  });

})();
