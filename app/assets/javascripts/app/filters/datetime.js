(function() {
  // @see http://momentjs.com/docs/#/displaying/format/
  Vue.filter('standardDate', function(value, tz) {
    if (value) {
      var timezone = tz || App.timezone;
      return moment.parseZone(value).tz(timezone).format('YYYY-MM-DD');
    }
  });

  Vue.filter('availabilityDate', function(value, tz) {
    if (value) {
      var timezone = tz || App.timezone;
      return moment.parseZone(value).tz(timezone).format('ddd, DD MMM');
    }
  });

  Vue.filter('shortDate', function(value, tz) {
    if (value) {
      var timezone = tz || App.timezone;
      return moment.parseZone(value).tz(timezone).format('DD MMM, YYYY');
    }
  });

  Vue.filter('shortDateTime', function(value, tz) {
    if (value) {
      var timezone = tz || App.timezone;
      return moment.parseZone(value).tz(timezone).format('DD MMM, YYYY hh:mma');
    }
  });

  Vue.filter('hour', function(value, tz) {
    if (value) {
      var timezone = tz || App.timezone;
      return moment.parseZone(value).tz(timezone).format('hh:mma');
    }
  });

  /* 'm' == Moment object */
  Vue.filter('mhour', function(value) {
    if (value) {
      return value.format('hh:mma');
    }
  });

  Vue.filter('hour24', function(value, tz) {
    if (value) {
      var timezone = tz || App.timezone;
      return moment.parseZone(value).tz(timezone).format('HH:mm');
    }
  });

  /* 12-hour with zone */
  Vue.filter('hourz', function(value, tz) {
    if (value) {
      var timezone = tz || App.timezone;
      return moment.parseZone(value).tz(timezone).format('hh:mma \(z\)');
    }
  });

  Vue.filter('tz', function(value, tz) {
    if (value) {
      var timezone = tz || App.timezone;
      return moment(value).tz(timezone).format('z');
    }
  });

  Vue.filter('humanizeMinutes', function(duration) {
    if (duration === 0) {
      return '0';
    }

    if ((duration != null) && (duration != undefined)) {
      var h = 0, m = 0;

      if (duration < 60) {
        m = duration;
      } else {
        h = parseInt(duration / 60);
        m = duration % 60;
      }

      humanizedStr = '';
      if (h > 0) {
        humanizedStr += h + 'hr ';
      }

      if (m > 0) {
        humanizedStr += parseInt(m.toFixed()) + 'min';
      }
      return humanizedStr;
    }
  });

  Vue.filter('dob', function(dateStr) {
    if (dateStr) {
      // TODO: localize
      return moment(dateStr).format('DD/MM/YYYY');
    }
  });

  Vue.filter('moment', function(dateStr, format) {
    if (dateStr) {
      return moment(dateStr).format(format);
    }
  });
})();
