/**
 * Wrapper for PNotify plugin
 * @see: https://sciactive.com/pnotify/
 */
var Flash = {
  success: function(msg) {
    new PNotify({
      text: msg,
      type: 'success'
    });
  },
  error: function(msg) {
    new PNotify({
      text: msg,
      type: 'error'
    });
  },
  warning: function(msg) {
    new PNotify({
      text: msg,
      type: 'warning'
    });
  },
  info: function(msg) {
    new PNotify({
      text: msg,
      type: 'info'
    });
  }
};
