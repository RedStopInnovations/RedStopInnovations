$(function() {
  if ($('#js-page-home').length) {

    //=== Hero search
    const $btnGetUserLoc = $('#js-btn-get-user-location');
    const $form = $('#js-form-hero-search');
    const $inputLoc = $('#js-input-location');
    const $inputProfession = $('#js-input-profession');

    $('.js-button-select-profession').on('click', function(e) {
      e.preventDefault();

      var $btn = $(this);

      if ($btn.hasClass('active')) {
        $inputProfession.val('');
        $btn.removeClass('active');
      } else {
        var prof = $btn.data('profession');
        $inputProfession.val(prof);
        $btn.addClass('active');
        $('.js-button-select-profession').not($btn).removeClass('active');
      }
    });

    $inputProfession.on('change', function() {
      var selectedProf = $(this).val();
      $('.js-button-select-profession[data-profession="' + selectedProf + '"]').addClass('active');
      $('.js-button-select-profession[data-profession!="' + selectedProf + '"]').removeClass('active');
      if (selectedProf) {
        rememberSelectedProfession(selectedProf);
      }
      if (selectedProf && $inputLoc.val().trim().length > 0) {
        $form.trigger('submit');
      }
    });

    var rememberLastLocation = function(location) {
      try {
        localStorage.setItem(
          'oh.user_current_location', location
        );
        return true;
      } catch(e) {
        return false;
      }
    };

    var rememberSelectedProfession = function(prof) {
      try {
        localStorage.setItem(
          'oh.user_selected_profession', prof
        );
        return true;
      } catch(e) {
        return false;
      }
    };

    var clearRememberedLastLocation = function() {
      try {
        localStorage.removeItem(
          'oh.user_current_location'
        );
        return true;
      } catch(e) {
        return false;
      }
    };

    var getRememberedLastLocation = function() {
      try {
        return localStorage.getItem(
          'oh.user_current_location'
        );
      } catch(e) {
        return null;
      }
    };

    var getRememberedSelectedProfession = function () {
      try {
        return localStorage.getItem(
          'oh.user_selected_profession'
        );
      } catch (e) {
        return null;
      }
    };

    $inputLoc.on('keypress', function (e) {
      if (e.key === 'Enter') {
        return false;
      }
    });

    function showGeolocationError(error) {
      $btnGetUserLoc.find('.fa').addClass('fa-crosshairs').removeClass('fa-spin fa-spinner');
      switch(error.code) {
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
      $btnGetUserLoc.find('.fa').removeClass('fa-crosshairs').addClass('fa-spin fa-spinner');
      if (navigator.geolocation) {
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
        }},
        function(results, status) {
          if (status === 'OK') {
            if (results[0]) {
              $inputLoc.val(results[0].formatted_address);
              rememberLastLocation(results[0].formatted_address);
              $form.trigger('submit');
            } else {
              window.alert('No results found');
            }
          } else {
            window.alert('Geocoder failed due to: ' + status);
          }
        }
      );
    }

    // Autocomplete location input
      var autocomplete;

    function locationSelected() {
      var place = autocomplete.getPlace();

      if (place.formatted_address) {
        rememberLastLocation(place.formatted_address);
        $form.trigger('submit');
      } else if (place.name) {
        rememberLastLocation(place.name);
        $form.trigger('submit');
      } else {
        clearRememberedLastLocation();
      }
    }

    autocomplete = new google.maps.places.Autocomplete(
      $inputLoc.get(0),
      {
        types: ['geocode'],
        componentRestrictions: { 'country': $('body').data('country') }
      }
    );

    autocomplete.addListener('place_changed', locationSelected);


    /* Handle click current location */
    $('#js-btn-get-user-location').on('click', function() {
      getUserLocation();
    });

    // Fill the address
    var rememberedLocation = getRememberedLastLocation();
    if (rememberedLocation) {
      $inputLoc.val(rememberedLocation);
    }

    /* Fill the remembered profession */
    if (!$inputProfession.val()) {
      $inputProfession.val(getRememberedSelectedProfession());
    }

    // <Top practitioners section>
    if ($('#js-home-top-practitioners-wrap').length) {
      const $wrap = $('#js-home-top-practitioners-wrap');
      $.ajax({
        method: 'GET',
        url: $wrap.data('url'),
        success: function(html) {
          $wrap.html(html);
        }
      });
    }
    // </Top practitioners section>
  }
});
