$(function () {
  if ($('#js-embed-team-page-form-search').length) {
    $(function() {
      const country = $('body').data('country') || 'AU';
      const $form = $('#js-embed-team-page-form-search');
      const $inputLoc = $form.find('[name="location"]');
      const $inputProfession = $form.find('[name="profession"]');
      const $btnGetUserLoc = $form.find('.js-btn-local-get-user-location');

      const autocomplete = new google.maps.places.Autocomplete(
        $inputLoc.get(0),
        {
          types: ['geocode'],
          componentRestrictions: { 'country': [country] }
        }
      );

      autocomplete.addListener('place_changed', function() {
        setTimeout(function() {
          $form.trigger('submit');
        }, 100)
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

      $btnGetUserLoc.on('click', function() {
        getUserLocation();
      });

      $inputProfession.on('change', function() {
        $form.trigger('submit');
      });

    });
  }
});
