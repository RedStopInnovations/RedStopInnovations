$(function () {
    if ($('#js-page-booking-form').length) {
      var stripe;
      var stripeElements;
      var stripeCard;
      var $cardErrors;
      var $inputCardToken;

      const $form = $('#js-form-booking');
      const paymentAvailable = $form.data('online-payment-available');
      const stripePublishableKey = $form.data('stripe-publishable-key');

      if (paymentAvailable) {
        stripe = Stripe(stripePublishableKey);

        stripeElements = stripe.elements({
          appearance: {
            theme: 'stripe',
            labels: 'floating',
          }
        });

        stripeCard = stripeElements.create("card", {
          hidePostalCode: true
        });
        stripeCard.mount('#js-stripe-card-element');

        $cardErrors = $('#js-card-errors');
        $inputCardToken = $('#js-input-stripe-token');

        stripeCard.on('change', function(e) {
          if (e.error) {
            $cardErrors.text(e.error.message);
          } else {
            $cardErrors.empty();
          }
        });
      }

      var geocoder = new google.maps.Geocoder();
      var $paymentWrap = $('#js-payment-wrap');
      var $inputApptType = $('#js-input-appointment-type');
      var $formErrorsWrap = $('#js-form-errors-wrap');
      var $prepaymentNote = $('#js-appoitment-type-prepayment-note');

      $inputLoc = $('#js-input-address');

      $inputLoc.on('keypress', function (e) {
        if (e.key === 'Enter') {
          return false;
        }
      });

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

      function validateAddress() {
        return new Promise(function(resolve, reject) {
          var allComponentTypes = [];
          var requiredComponentTypes = ['street_number', 'route', 'postal_code'];
          geocoder.geocode({ 'address': $inputLoc.val() }, function(results, status) {
            if (status == 'OK') {
              for (var i = results[0].address_components.length - 1; i >= 0; i--) {
                var addrComponent = results[0].address_components[i]
                allComponentTypes = allComponentTypes.concat(addrComponent.types);
              }
              var ok = requiredComponentTypes.every(function(type) {
                return allComponentTypes.indexOf(type) >= 0;
              });
              if (ok) {
                resolve();
              } else {
                reject(Error('Your address is not sufficient. Please enter more details.'));
              }
            } else {
              reject(Error('Your address is unrecognizable. Please enter a valid address.'));
            }
          });
        });
      };

      function prepareCardToken() {
        return new Promise(function(resolve, reject) {
          if (paymentAvailable && isPrepaymentRequire()) {
            stripe.createToken(stripeCard)
            .then(function(result) {
              if (result.error) {
                reject(Error(result.error.message));
              } else {
                $inputCardToken.val(result.token.id);
                resolve();
              }
            });
          } else {
            resolve();
          }
        });
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

      // Init the client location as entered in other pages
      if ($inputLoc.val().trim().length === 0) {
        $inputLoc.val(getRememberedLastLocation);
      }

      var isPrepaymentRequire = function() {
        return $inputApptType.find('option:selected').data('prepayment') === true;
      };

      $inputApptType.on('change', function() {
        var selectedOption = $inputApptType.find('option:selected');
        if (selectedOption && selectedOption.data('prepayment') === true) {
          showPaymentUI();
        } else {
          hidePaymentUI();
        }
      });

      var showPaymentUI = function() {
        $('#js-prepayment-info').empty()
        $.ajax({
          method: 'GET',
          url: '/bookings/prepayment_info',
          data: {
            appointment_type_id: $inputApptType.val()
          },
          success: function(html) {
            $('#js-prepayment-info').html(html);
          }
        });

        $paymentWrap.removeClass('d-none');
        $prepaymentNote.removeClass('d-none');
      };

      var hidePaymentUI = function() {
        $paymentWrap.addClass('d-none');
        $prepaymentNote.addClass('d-none');
      };

      /* Handle submit form */
      $form.on('submit', function(e) {
        var $btnSubmit = $form.find('.js-btn-submit');
        e.preventDefault();

        if ($form.hasClass('busy')) {
          return;
        }

        $form.addClass('busy');
        $btnSubmit.attr('disabled', true).text('Processing ...');
        $formErrorsWrap.addClass('d-none').find('.alert ul').empty();

        prepareCardToken()
          .then(function() {
            validateAddress()
              .then(function() {
                $.ajax({
                  url: $form.attr('action'),
                  method: $form.attr('method'),
                  data: JSON.stringify($form.serializeJSON({useIntKeysAsArrayIndex: true})),
                  contentType: 'application/json',
                  dataType: 'json',
                  success: function(res) {
                    $btnSubmit.text('Proceeded');
                    // Dispatch a message to the parent window as workaround for cross-domain tracking via Google Tag Manager
                    if (window.self !== window.top) {
                      window.parent.postMessage({
                        event: 'oh.booking.created'
                      }, '*');
                    }

                    if (res.redirect_url) {
                      location.href = res.redirect_url;
                    } else {
                      location.href = '/bookings/success';
                    }
                  },
                  error: function(xhr) {
                    var errorMsg;
                    if (xhr.status == 500) {
                      errorMsg = 'An error has occurred. Sorry for the inconvenience.';
                    }

                    if (xhr.responseJSON) {
                      var jsonRes = xhr.responseJSON;
                      if (jsonRes.message) {
                        errorMsg = jsonRes.message;
                      }

                      if ((xhr.status === 422) && jsonRes.errors) {
                        $formErrorsWrap.removeClass('d-none');
                        for (var i = 0; i < jsonRes.errors.length; i++) {
                          $formErrorsWrap.find('.alert ul').append(
                            $('<li>', { text: jsonRes.errors[i]})
                          );
                        }
                        bootbox.alert('Please check for validation errors.');
                        window.scrollTo({ top: 0, behavior: 'smooth' });
                      }
                    }

                    if (errorMsg) {
                      bootbox.alert(errorMsg);
                    }

                    $form.removeClass('busy');
                    $btnSubmit.removeAttr('disabled').text('Proceed booking');
                  }
                });
              }, function(e) {
                bootbox.alert(e.message);
                $form.removeClass('busy');
                $btnSubmit.removeAttr('disabled').text('Proceed booking');
              });
          }).catch(function(err) {
            bootbox.alert('Payment info error: ' + err.message);
            $form.removeClass('busy');
            $btnSubmit.removeAttr('disabled').text('Proceed booking');
          });
      });

      // Autocomplete address input
      (function() {
        var autocomplete;

        function locationSelected() {
          var place = autocomplete.getPlace();
          if (place.formatted_address) {
            rememberLastLocation(place.formatted_address);
          }
        };

        autocomplete = new google.maps.places.Autocomplete(
          $inputLoc.get(0),
          {
            types: ['geocode'],
            componentRestrictions: { 'country': [$('body').data('country')] }
          }
        );

        autocomplete.addListener('place_changed', locationSelected);
      })();

    }
});