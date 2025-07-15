$(function () {
  if ($('#js-page-team').length) {
    const country = $('body').data('country');
    const $inputLoc = $('#js-input-location-search');
    const $inputProfession = $('#js-input-profession');
    const $btnGetUserLoc = $('#js-btn-get-user-location');
    const $form = $('#js-form-search');

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

    var getRememberedSelectedProfession = function () {
      try {
        return localStorage.getItem(
          'oh.user_selected_profession'
        );
      } catch (e) {
        return null;
      }
    };

    var rememberSelectedProfession = function (prof) {
      try {
        localStorage.setItem(
          'oh.user_selected_profession', prof
        );
        return true;
      } catch (e) {
        return false;
      }
    };

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

    var autocomplete = new google.maps.places.Autocomplete(
      $inputLoc.get(0),
      {
        types: ['geocode'],
        componentRestrictions: { 'country': [country] }
      }
    );

    autocomplete.addListener('place_changed', function () {
      var place = autocomplete.getPlace();
      if (place.formatted_address) {
        rememberLastLocation(place.formatted_address);
        $form.trigger('submit');
      }
    });

    /* Handle click current location */
    $btnGetUserLoc.on('click', function () {
      getUserLocation();
    });

    $inputProfession.on('change', function () {
      var selectedProf = $(this).val();
      if (selectedProf) {
        rememberSelectedProfession(selectedProf);
        if ($inputLoc.val().trim().length > 0) {
          $form.trigger('submit');
        }
      }
    });

    /* Handle button view practitioner service fees */
    $(document).on('click', '.js-btn-view-practitioner-service-fees', function (e) {
      e.preventDefault();
      const $btn = $(this);

      $.ajax({
        method: 'GET',
        url: $btn.data('url'),
        success: function (modalHtml) {
          $(modalHtml).modal('show');
        }
      });

    });

    /* Fill the remembered location */
    if ($inputLoc.val().trim().length === 0) {
      $inputLoc.val(getRememberedLastLocation());
    }

    /* Fill the remembered profession */
    if (!$inputProfession.val()) {
      $inputProfession.val(getRememberedSelectedProfession());
    }
  }
});
