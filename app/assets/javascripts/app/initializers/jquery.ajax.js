(function() {
  $(document).ajaxSend(function( event, jqxhr, settings ) {
    jqxhr.setRequestHeader('X-TZ', App.timezone);
  });
})();
