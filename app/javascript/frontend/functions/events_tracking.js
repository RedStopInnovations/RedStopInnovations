(function() {
  var csrfToken = function () {
    var meta = document.querySelector("meta[name=csrf-token]");
    return meta && meta.content;
  }

  var csrfParam = function() {
    var meta = document.querySelector("meta[name=csrf-param]");
    return meta && meta.content;
  }

  $(document).on('click', '.js-rci', function(e) {
    var $link = $(this);
    e.preventDefault();

    if (!$link.data('revealed')) {

      var buildRevealedLink = function() {
        var href = null;
        var realValue = Utils.sanitizeHtml(atob($link.data('value'), 'base64'));

        switch ($link.data('type')) {
          case 'phone':
          case 'mobile':
            href = 'tel:' + realValue;
            break;
          case 'email':
            href = 'mailto:' + realValue;
            break;
          case 'website':
            href = realValue;
          break;
        }
        return $('<a/>', {
          href: href,
          text: realValue,
        });
      };

      var popupContent = buildRevealedLink();

      $link.popover({
        template: '<div class="popover popover-reveal-contact-info" role="tooltip"><div class="arrow"></div><h3 class="popover-header"></h3><div class="popover-body"></div></div>',
        content: popupContent,
        html: true,
        trigger: 'click',
        placement: 'top'
      });

      $link.popover('show');
      $link.data('revealed', true);

      // Save the event
      var formData = {
        event: $link.data('track-event')
      };
      var _csrfParam = csrfParam();
      var _csrfToken = csrfToken();
      if (_csrfParam && _csrfToken) {
        formData[_csrfParam] = _csrfToken;
      }

      $.ajax({
        method: 'POST',
        url: '/_trk',
        data: formData
      });

    }
  });
})();
