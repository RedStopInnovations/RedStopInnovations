  $(function() {
    $(".horizontalMenu-list li a").each(function() {
      var pageUrl = window.location.href.split(/[?#]/)[0];
      if (this.href == pageUrl) {
        $(this).addClass("active");
        $(this).parent().addClass("active"); // add active to li of the current link
        $(this).parent().parent().prev().addClass("active"); // add active class to an anchor
        $(this).parent().parent().prev().click(); // click the item to make it drop
      }
    });
  });

  // ______________ Cover-image
  $(".cover-image").each(function() {
    var attr = $(this).attr('data-image-src');
    if (typeof attr !== typeof undefined && attr !== false) {
      $(this).css('background', 'url(' + attr + ') center center');
    }
  });

  // ______________ Global Loader
  // $(window).on("load", function(e) {
  //   $("#global-loader").fadeOut("slow");
  // });

  // ______________Active Class
  $(document).on('ready', function() {
    $(".horizontalMenu-list li a").each(function() {
      var pageUrl = window.location.href.split(/[?#]/)[0];
      if (this.href == pageUrl) {
        $(this).addClass("active");
        $(this).parent().addClass("active"); // add active to li of the current link
        $(this).parent().parent().prev().addClass("active"); // add active class to an anchor
        $(this).parent().parent().prev().click(); // click the item to make it drop
      }
    });
  });

  // ______________ Back to Top
  $(window).on("scroll", function(e) {
    if ($(this).scrollTop() > 0) {
      $('#back-to-top').fadeIn('slow');
    } else {
      $('#back-to-top').fadeOut('slow');
    }
  });

  $("#back-to-top").on("click", function(e) {
    $("html, body").animate({
      scrollTop: 0
    }, 600);
    return false;
  });

  // ______________Tooltip
  $('[data-toggle="tooltip"]').tooltip();

  // ______________Popover
  $('[data-toggle="popover"]').popover({
    html: true
  });


  // Horizontal menu(copied from plugins/horizontal/horizontal.js)
  document.addEventListener("touchstart", function() {}, false);

  jQuery('#horizontal-navtoggle').on('click', function() {
    jQuery('body').toggleClass('active');
  });

  jQuery('.horizontal-overlapbg').on('click', function() {
    jQuery("body").removeClass('active');
  });

  jQuery('.horizontalMenu-click').on('click', function() {
    jQuery(this).toggleClass('horizontal-activearrow').parent().siblings().children().removeClass('horizontal-activearrow');
    jQuery(".horizontalMenu > .horizontalMenu-list > li > .sub-menu").not(jQuery(this).siblings('.horizontalMenu > .horizontalMenu-list > li > .sub-menu')).slideUp('slow');
    jQuery(this).siblings('.sub-menu').slideToggle('slow');
  });

  jQuery(window).on('resize', function() {
    if (jQuery(window).outerWidth() < 992) {
      jQuery('.horizontalMenu').css('height', jQuery(this).height() + "px");
      jQuery('.horizontalMenucontainer').css('min-width', jQuery(this).width() + "px");
    } else {
      jQuery('.horizontalMenu').removeAttr("style");
      jQuery('.horizontalMenucontainer').removeAttr("style");
      jQuery('body').removeClass("active");
      jQuery('.horizontalMenu > .horizontalMenu-list > li > .horizontal-megamenu, .horizontalMenu > .horizontalMenu-list > li > ul.sub-menu, .horizontalMenu > .horizontalMenu-list > li > ul.sub-menu > li > ul.sub-menu, .horizontalMenu > .horizontalMenu-list > li > ul.sub-menu > li > ul.sub-menu > li > ul.sub-menu').removeAttr("style");
      jQuery('.horizontalMenu-click').removeClass("horizontal-activearrow");
    }
  });

  jQuery(window).trigger('resize');

  // Sticky horizontal menu
  $(".horizontal-main").sticky({topSpacing:0}); // Main menu on large screen
  $(".horizontal-header").sticky({topSpacing:0}); // Mobile screen

  $('#js-form-subscribe-footer').on('submit', function(e) {
    e.preventDefault();
    const $form = $(this);
    $form.find('[type="submit"]').attr('disabled', true);

    $.ajax({
      method: $form.attr('method'),
      url: $form.attr('action'),
      data: $form.serialize(),
      dataType: 'json',
      success: function(res) {
        if (res.message) {
          window.alert(res.message || 'Thank you for subscribing.');
        }

        $form.get(0).reset();
      },
      error: function(xhr) {
        if (xhr.responseJSON && xhr.responseJSON.message) {
          window.alert(xhr.responseJSON.message);
        } else {
          window.alert('Sorry, an error has occurred.');
        }
        $form.find('[type="submit"]').attr('disabled', false);
      }
    })
  });

  /* Button show modal practitioner profile */
  $('body').on('click', '.js-btn-modal-practitioner-profile', function(e) {
    e.preventDefault();
    const $btn = $(this);

    $.ajax({
      method: 'GET',
      url: $btn.data('url'),
      success: function(html) {
        const $modal = $(html);
        $modal.appendTo('body');
        $modal.modal('show');
      }
    });
  });

  /* Form search practitioners in local pages */

  if ($('#js-form-local-practitioners-search').length) {
    $(function() {
      const country = $('body').data('country');
      const $form = $('#js-form-local-practitioners-search');
      const $inputLoc = $form.find('[name="location"]');
      const $btnGetUserLoc = $form.find('#js-btn-local-get-user-location');
      const $practitionersListWrap = $('#js-local-practitioners-list-wrap');

      $form.on('submit', function(e) {
        e.preventDefault();
        loadPractitioners();
      });

      function loadPractitioners() {
        $.ajax({
          method: 'GET',
          url: $form.attr('action'),
          data: $form.serialize(),
          success: function(html) {
            $practitionersListWrap.html(html);
          }
        });
      };

      var rememberLastLocation = function (location) {
        try {
          localStorage.setItem(
            'oh.user_current_location', location
          );
          return true;
        } catch (e) {
          return false;
        }
      };

      var getRememberedLastLocation = function () {
        try {
          return localStorage.getItem(
            'oh.user_current_location'
          );
        } catch (e) {
          return null;
        }
      };

      const autocomplete = new google.maps.places.Autocomplete(
        $inputLoc.get(0),
        {
          types: ['geocode'],
          componentRestrictions: { 'country': [country] }
        }
      );

      autocomplete.addListener('place_changed', function() {
        var place = autocomplete.getPlace();
        if (place.formatted_address) {
          rememberLastLocation(place.formatted_address);
        }

        setTimeout(function() {
          loadPractitioners();
        }, 300)
      });

      function showGeolocationError(error) {
        $btnGetUserLoc.find('.fa').addClass('fa-crosshairs').removeClass('fa-spin fa-spinner');
        switch (error.code) {
          case error.PERMISSION_DENIED:
            alert("You have denied the request for Geolocation.");
            break;
          case error.POSITION_UNAVAILABLE:
            alert("Location information is unavailable.");
            break;
          case error.TIMEOUT:
            alert("The request to get user location timed out.");
            break;
          case error.UNKNOWN_ERROR:
            alert("An unknown error occurred.");
            break;
        }
      }

      function getUserLocation() {
        if (navigator.geolocation) {
          $btnGetUserLoc.find('.fa').removeClass('fa-crosshairs').addClass('fa-spin fa-spinner');
          navigator.geolocation.getCurrentPosition(handleUserLocation, showGeolocationError);
        } else {
          alert("Geolocation is not supported by your browser.");
        }
      }

      function handleUserLocation(position) {
        $btnGetUserLoc.find('.fa').addClass('fa-crosshairs').removeClass('fa-spin fa-spinner');

        var geocoder = new google.maps.Geocoder;
        geocoder.geocode({
          location: {
            lat: position.coords.latitude,
            lng: position.coords.longitude
          }
        },
          function (results, status) {
            if (status === 'OK') {
              if (results[0]) {
                $inputLoc.val(results[0].formatted_address);
                rememberLastLocation(results[0].formatted_address);
                loadPractitioners();
              } else {
                window.alert('No results found');
              }
            } else {
              window.alert('Geocoder failed due to: ' + status);
            }
          }
        );
      }

      $btnGetUserLoc.on('click', function() {
        getUserLocation();
      });

      loadPractitioners();

      /* Fill the remembered location */
      if ($inputLoc.val().trim().length === 0) {
        $inputLoc.val(getRememberedLastLocation());
      }

    });
  }

	// By default, Bootstrap doesn't auto close popover after appearing in the page
	// resulting other popover overlap each other. Doing this will auto dismiss a popover
	// when clicking anywhere outside of it
	$(document).on('click', function(e) {
		$('[data-toggle="popover"],[data-original-title]').each(function() {
			//the 'is' for buttons that trigger popups
			//the 'has' for icons within a button that triggers a popup
			if (!$(this).is(e.target) && $(this).has(e.target).length === 0 && $('.popover').has(e.target).length === 0) {
				(($(this).popover('hide').data('bs.popover') || {}).inState || {}).click = false // fix for BS 3.3.6
			}
		});
	});