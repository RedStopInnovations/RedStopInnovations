(function() {
  'use strict';

  /* Wrapper service for Pnotify */
  Vue.prototype.$notify = function() {

    var args = arguments;
    if (args.length == 0) {
      throw new Error('Invalid argument length');
    }
    var text = args[0];
    var type = 'success'; // Default is success message

    if (args[1]) {
      type = args[1];
    }

    return new PNotify({
      text: text,
      type: type
    });
  };
})();
