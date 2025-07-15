(function() {
  if (window.session && window.session.user) {
    App.user = window.session.user;
    App.timezone = App.user.timezone;
  }

  document.addEventListener('app.timezone.change', function(e) {
    App.timezone = e.detail.timezone;
  });
})();
