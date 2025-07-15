$(function () {
  if ($('#js-page-referrals').length) {
    var autocomplete;

    function locationSelected() {
      var place = autocomplete.getPlace();

      if (place.formatted_address) {
        var componentForm = {
          street_number: 'referral_patient_address1',
          subpremise: 'referral_patient_address1',
          locality: 'referral_patient_city',
          administrative_area_level_1: 'referral_patient_state',
          postal_code: 'referral_patient_postcode',
          postal_town: 'referral_patient_city'
        };

        if (place.address_components) {
          $.each(componentForm, function (index, element) {
            $('#' + element).val('');
          });
          $.each(place.address_components, function (index, item) {
            if (componentForm[item.types[0]]) {
              $inputElement = $('#' + componentForm[item.types[0]]);
              if (item.types[0] == 'subpremise') {
                $($inputElement).val(item.short_name + '/')
              } else {
                $($inputElement).val($inputElement.val() + item.short_name)
              }
            }

            if (item.types[0] == 'country') {
              $('#referral_patient_country').val(item.short_name);
            }

            if (item.types[0] == 'route') {
              $('#referral_patient_address1').val($('#referral_patient_address1').val() + ' ' + item.short_name);
            }
          });
        }
      }
    };

    let country = $('body').data('country');

    autocomplete = new google.maps.places.Autocomplete($('#referral_patient_address1')[0], {
      types: ['geocode'],
      componentRestrictions: {
        'country': [country]
      }
    });

    autocomplete.addListener('place_changed', locationSelected);

    $('#referral_patient_address1').on('keypress', function (e) {
      if (e.key === 'Enter') {
        return false;
      }
    });
  }
});
