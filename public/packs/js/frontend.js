(self["webpackChunkapp"] = self["webpackChunkapp"] || []).push([["frontend"],{

/***/ "./app/javascript/frontend/functions/events_tracking.js":
/*!**************************************************************!*\
  !*** ./app/javascript/frontend/functions/events_tracking.js ***!
  \**************************************************************/
/***/ (function() {

(function () {
  var csrfToken = function () {
    var meta = document.querySelector("meta[name=csrf-token]");
    return meta && meta.content;
  };
  var csrfParam = function () {
    var meta = document.querySelector("meta[name=csrf-param]");
    return meta && meta.content;
  };
  $(document).on('click', '.js-rci', function (e) {
    var $link = $(this);
    e.preventDefault();
    if (!$link.data('revealed')) {
      var buildRevealedLink = function () {
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
          text: realValue
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

/***/ }),

/***/ "./app/javascript/frontend/functions/utils.js":
/*!****************************************************!*\
  !*** ./app/javascript/frontend/functions/utils.js ***!
  \****************************************************/
/***/ (function() {

window.Utils = {};
Utils.getQueryParameter = function (key, queryString) {
  var query = queryString || window.location.search.substring(1);
  if (typeof window.URLSearchParams === 'function') {
    return new URLSearchParams(query).get(key);
  } else {
    var sURLVariables = query.split(/[&||?]/),
      res;
    for (var i = 0; i < sURLVariables.length; i++) {
      var paramName = sURLVariables[i],
        sParameterName = (paramName || '').split('=');
      if (sParameterName[0] === key) {
        res = sParameterName[1];
      }
    }
    return res;
  }
};

/**
 * Get all query parameters from url
 * If query string is not specified, it parse current location
 * Note: not support nested parameter likes `users[]`
 *
 * @return String
 */
Utils.getQueryParameters = function (queryString) {
  var sPageURL = queryString || window.location.search.substring(1),
    sURLVariables = sPageURL.split(/[&||?]/),
    res;
  var parameters = {};
  for (var i = 0; i < sURLVariables.length; i++) {
    var paramName = sURLVariables[i],
      sParameterName = (paramName || '').split('=');
    parameters[sParameterName[0]] = sParameterName[1];
  }
  return parameters;
};

/**
 * Check if Local Storage is available
 */
Utils.isLocalStorageAvailable = function () {
  var test = new Date().getTime().toString();
  try {
    localStorage.setItem(test, test);
    localStorage.removeItem(test);
    return true;
  } catch (e) {
    return false;
  }
};
Utils.truncateWords = function (str, maxLength) {
  var trimmable = '\u0009\u000A\u000B\u000C\u000D\u0020\u00A0\u1680\u180E\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200A\u202F\u205F\u2028\u2029\u3000\uFEFF';
  var reg = new RegExp('(?=[' + trimmable + '])');
  var words = str.split(reg);
  var count = 0;
  var truncated = words.filter(function (word) {
    count += word.length;
    return count <= maxLength;
  }).join('');
  if (truncated.length < str.length) {
    truncated += '...';
  }
  return truncated;
};
Utils.base64toBlob = function (dataURI) {
  var byteString;
  if (dataURI.split(',')[0].indexOf('base64') >= 0) {
    byteString = atob(dataURI.split(',')[1]);
  } else {
    byteString = unescape(dataURI.split(',')[1]);
  }
  var mimeString = dataURI.split(',')[0].split(':')[1].split(';')[0];
  var ia = new Uint8Array(byteString.length);
  for (var i = 0; i < byteString.length; i++) {
    ia[i] = byteString.charCodeAt(i);
  }
  return new Blob([ia], {
    type: mimeString
  });
};

/**
 * Return date in yyyy-mm-dd format
 *
 * @param {Date} dateObj
 */
Utils.dateToStandardFormat = function (dateObj) {
  var mm = dateObj.getMonth() + 1;
  var dd = dateObj.getDate();
  return [dateObj.getFullYear(), (mm > 9 ? '' : '0') + mm, (dd > 9 ? '' : '0') + dd].join('-');
};
/**
 * Simple sanitize html
 *
 * @param {String} string
 * @returns
 */
Utils.sanitizeHtml = function (string) {
  const map = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#x27;',
    "/": '&#x2F;'
  };
  const reg = /[&<>"'/]/ig;
  return string.replace(reg, match => map[match]);
};

/***/ }),

/***/ "./app/javascript/frontend/images sync \\.(png%7Cjpe?g)$":
/*!****************************************************************************!*\
  !*** ./app/javascript/frontend/images/ sync nonrecursive \.(png%7Cjpe?g)$ ***!
  \****************************************************************************/
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var map = {
	"./hero-search-bg.jpg": "./app/javascript/frontend/images/hero-search-bg.jpg",
	"./logo.png": "./app/javascript/frontend/images/logo.png",
	"./tracksy-logo.jpeg": "./app/javascript/frontend/images/tracksy-logo.jpeg",
	"frontend/images/hero-search-bg.jpg": "./app/javascript/frontend/images/hero-search-bg.jpg",
	"frontend/images/logo.png": "./app/javascript/frontend/images/logo.png",
	"frontend/images/tracksy-logo.jpeg": "./app/javascript/frontend/images/tracksy-logo.jpeg"
};


function webpackContext(req) {
	var id = webpackContextResolve(req);
	return __webpack_require__(id);
}
function webpackContextResolve(req) {
	if(!__webpack_require__.o(map, req)) {
		var e = new Error("Cannot find module '" + req + "'");
		e.code = 'MODULE_NOT_FOUND';
		throw e;
	}
	return map[req];
}
webpackContext.keys = function webpackContextKeys() {
	return Object.keys(map);
};
webpackContext.resolve = webpackContextResolve;
module.exports = webpackContext;
webpackContext.id = "./app/javascript/frontend/images sync \\.(png%7Cjpe?g)$";

/***/ }),

/***/ "./app/javascript/frontend/images/hero-search-bg.jpg":
/*!***********************************************************!*\
  !*** ./app/javascript/frontend/images/hero-search-bg.jpg ***!
  \***********************************************************/
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

"use strict";
module.exports = __webpack_require__.p + "static/images/hero-search-bg-4e7ca503b6b8398577d3.jpg";

/***/ }),

/***/ "./app/javascript/frontend/images/logo.png":
/*!*************************************************!*\
  !*** ./app/javascript/frontend/images/logo.png ***!
  \*************************************************/
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

"use strict";
module.exports = __webpack_require__.p + "static/images/logo-10a363278b0b072a66f6.png";

/***/ }),

/***/ "./app/javascript/frontend/images/tracksy-logo.jpeg":
/*!**********************************************************!*\
  !*** ./app/javascript/frontend/images/tracksy-logo.jpeg ***!
  \**********************************************************/
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

"use strict";
module.exports = __webpack_require__.p + "static/images/tracksy-logo-5e860abaf83aa3c09ea7.jpeg";

/***/ }),

/***/ "./app/javascript/frontend/pages/booking_form.js":
/*!*******************************************************!*\
  !*** ./app/javascript/frontend/pages/booking_form.js ***!
  \*******************************************************/
/***/ (function() {

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
          labels: 'floating'
        }
      });
      stripeCard = stripeElements.create("card", {
        hidePostalCode: true
      });
      stripeCard.mount('#js-stripe-card-element');
      $cardErrors = $('#js-card-errors');
      $inputCardToken = $('#js-input-stripe-token');
      stripeCard.on('change', function (e) {
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
        localStorage.setItem('oh.user_current_location', location);
        return true;
      } catch (e) {
        return false;
      }
    };
    function validateAddress() {
      return new Promise(function (resolve, reject) {
        var allComponentTypes = [];
        var requiredComponentTypes = ['street_number', 'route', 'postal_code'];
        geocoder.geocode({
          'address': $inputLoc.val()
        }, function (results, status) {
          if (status == 'OK') {
            for (var i = results[0].address_components.length - 1; i >= 0; i--) {
              var addrComponent = results[0].address_components[i];
              allComponentTypes = allComponentTypes.concat(addrComponent.types);
            }
            var ok = requiredComponentTypes.every(function (type) {
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
    }
    ;
    function prepareCardToken() {
      return new Promise(function (resolve, reject) {
        if (paymentAvailable && isPrepaymentRequire()) {
          stripe.createToken(stripeCard).then(function (result) {
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
    }
    ;
    var getRememberedLastLocation = function () {
      try {
        return localStorage.getItem('oh.user_current_location');
      } catch (e) {
        return null;
      }
    };

    // Init the client location as entered in other pages
    if ($inputLoc.val().trim().length === 0) {
      $inputLoc.val(getRememberedLastLocation);
    }
    var isPrepaymentRequire = function () {
      return $inputApptType.find('option:selected').data('prepayment') === true;
    };
    $inputApptType.on('change', function () {
      var selectedOption = $inputApptType.find('option:selected');
      if (selectedOption && selectedOption.data('prepayment') === true) {
        showPaymentUI();
      } else {
        hidePaymentUI();
      }
    });
    var showPaymentUI = function () {
      $('#js-prepayment-info').empty();
      $.ajax({
        method: 'GET',
        url: '/bookings/prepayment_info',
        data: {
          appointment_type_id: $inputApptType.val()
        },
        success: function (html) {
          $('#js-prepayment-info').html(html);
        }
      });
      $paymentWrap.removeClass('d-none');
      $prepaymentNote.removeClass('d-none');
    };
    var hidePaymentUI = function () {
      $paymentWrap.addClass('d-none');
      $prepaymentNote.addClass('d-none');
    };

    /* Handle submit form */
    $form.on('submit', function (e) {
      var $btnSubmit = $form.find('.js-btn-submit');
      e.preventDefault();
      if ($form.hasClass('busy')) {
        return;
      }
      $form.addClass('busy');
      $btnSubmit.attr('disabled', true).text('Processing ...');
      $formErrorsWrap.addClass('d-none').find('.alert ul').empty();
      prepareCardToken().then(function () {
        validateAddress().then(function () {
          $.ajax({
            url: $form.attr('action'),
            method: $form.attr('method'),
            data: JSON.stringify($form.serializeJSON({
              useIntKeysAsArrayIndex: true
            })),
            contentType: 'application/json',
            dataType: 'json',
            success: function (res) {
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
            error: function (xhr) {
              var errorMsg;
              if (xhr.status == 500) {
                errorMsg = 'An error has occurred. Sorry for the inconvenience.';
              }
              if (xhr.responseJSON) {
                var jsonRes = xhr.responseJSON;
                if (jsonRes.message) {
                  errorMsg = jsonRes.message;
                }
                if (xhr.status === 422 && jsonRes.errors) {
                  $formErrorsWrap.removeClass('d-none');
                  for (var i = 0; i < jsonRes.errors.length; i++) {
                    $formErrorsWrap.find('.alert ul').append($('<li>', {
                      text: jsonRes.errors[i]
                    }));
                  }
                  bootbox.alert('Please check for validation errors.');
                  window.scrollTo({
                    top: 0,
                    behavior: 'smooth'
                  });
                }
              }
              if (errorMsg) {
                bootbox.alert(errorMsg);
              }
              $form.removeClass('busy');
              $btnSubmit.removeAttr('disabled').text('Proceed booking');
            }
          });
        }, function (e) {
          bootbox.alert(e.message);
          $form.removeClass('busy');
          $btnSubmit.removeAttr('disabled').text('Proceed booking');
        });
      }).catch(function (err) {
        bootbox.alert('Payment info error: ' + err.message);
        $form.removeClass('busy');
        $btnSubmit.removeAttr('disabled').text('Proceed booking');
      });
    });

    // Autocomplete address input
    (function () {
      var autocomplete;
      function locationSelected() {
        var place = autocomplete.getPlace();
        if (place.formatted_address) {
          rememberLastLocation(place.formatted_address);
        }
      }
      ;
      autocomplete = new google.maps.places.Autocomplete($inputLoc.get(0), {
        types: ['geocode'],
        componentRestrictions: {
          'country': [$('body').data('country')]
        }
      });
      autocomplete.addListener('place_changed', locationSelected);
    })();
  }
});

/***/ }),

/***/ "./app/javascript/frontend/pages/bookings.js":
/*!***************************************************!*\
  !*** ./app/javascript/frontend/pages/bookings.js ***!
  \***************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var ahoy_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ahoy.js */ "./node_modules/ahoy.js/dist/ahoy.esm.js");
const {
  default: flatpickr
} = __webpack_require__(/*! flatpickr */ "./node_modules/flatpickr/dist/esm/index.js");

$(function () {
  if ($('#js-page-bookings').length) {
    var $inputDatepickerCalendar = $('#input-datepicker-calendar');
    var $resultsFilterWrap = $('#results-filter-wrap');
    var $formSearch = $('#form-search');
    var $selectDateRange = $('#select-date-range');
    var $selectProfession = $('#select-profession');
    var $inputLoc = $('#input-location');
    var $cbOnlineBookingsEnable = $formSearch.find('[name="online_bookings_enable"]');
    var $nearPractitionersWrap = $('#near-practitioners-wrap');
    var rememberLastLocation = function (location) {
      try {
        localStorage.setItem('oh.user_current_location', location);
        return true;
      } catch (e) {
        return false;
      }
    };
    var getRememberedLastLocation = function () {
      try {
        return localStorage.getItem('oh.user_current_location');
      } catch (e) {
        return null;
      }
    };
    var rememberSelectedProfession = function (prof) {
      try {
        localStorage.setItem('oh.user_selected_profession', prof);
        return true;
      } catch (e) {
        return false;
      }
    };
    var getRememberedSelectedProfession = function () {
      try {
        return localStorage.getItem('oh.user_selected_profession');
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
        navigator.geolocation.getCurrentPosition(handleUserLocation, showGeolocationError);
      } else {
        alert("Geolocation is not supported by your browser.");
      }
    }
    function handleUserLocation(position) {
      var geocoder = new google.maps.Geocoder();
      geocoder.geocode({
        location: {
          lat: position.coords.latitude,
          lng: position.coords.longitude
        }
      }, function (results, status) {
        if (status === 'OK') {
          if (results[0]) {
            $inputLoc.val(results[0].formatted_address);
            rememberLastLocation(results[0].formatted_address);
            $formSearch.trigger('submit');
          } else {
            window.alert('No results found');
          }
        } else {
          window.alert('Geocoder failed due to: ' + status);
        }
      });
    }

    // Autocomplete location input
    (function () {
      var autocomplete;
      function locationSelected() {
        var place = autocomplete.getPlace();
        if (place.formatted_address) {
          rememberLastLocation(place.formatted_address);
          $formSearch.trigger('submit');
        }
      }
      autocomplete = new google.maps.places.Autocomplete($inputLoc.get(0), {
        types: ['geocode'],
        componentRestrictions: {
          'country': $('body').data('country')
        }
      });
      autocomplete.addListener('place_changed', locationSelected);
    })();

    /* Handle click current location */
    $('.btn-set-current-location').on('click', function () {
      getUserLocation();
    });
    $('.input-custom-date').on('change', function (e) {
      var $this = $(this);
      var date = $this.val();
      if (date) {
        var standardDate = new Date(date).toISOString('YYYY-MM-DD').split('T')[0];
        $('.date-option input[type=radio]').attr('disabled', true);
        $this.attr('disabled', true);
        $('<input>', {
          type: 'hidden',
          name: 'date',
          value: standardDate
        }).appendTo($formSearch);
        $formSearch.trigger('submit');
      } else {
        $('.date-option input[type=radio]').removeAttr('disabled');
      }
    });
    $selectDateRange.on('change', function () {
      $('.input-custom-date').attr('disabled', true);
      $('.date-option input[type=radio]').attr('disabled', true);
      $formSearch.trigger('submit');
    });
    $formSearch.on('submit', function () {
      // Disable empty inputs to shorten urls
      if ($inputLoc.val() === '') {
        $inputLoc.attr('disabled', true);
      }
      if ($selectProfession.val() === '') {
        $selectProfession.attr('disabled', true);
      }
    });
    $('[name="date"][type=radio]').on('click', function () {
      $('.input-custom-date').attr('disabled', true);
      $('#select-date-range').attr('disabled', true);
      $formSearch.trigger('submit');
    });
    $selectProfession.on('change', function () {
      rememberSelectedProfession($selectProfession.val());
      $formSearch.trigger('submit');
    });

    /* Handle change appointment type to update available appointments */
    $cbOnlineBookingsEnable.on('change', function () {
      $formSearch.trigger('submit');
    });

    /* Handle click time icons to navigate to next step */
    $(document).on('click', '.btn-time', function () {
      var $this = $(this);
      if ($this.hasClass('not-allowed-book-online')) {
        const contactEncodedData = $this.data('rci');
        if (contactEncodedData) {
          const contactDetails = JSON.parse(atob(contactEncodedData));
          const $message = $('<div>').append($('<h4>', {
            class: 'text-warning mb-3',
            text: 'Online booking disabled'
          })).append('<p>Online booking have been disabled for this practitioner by their business admin. To make an appointment with this practitioner, contact their business directly via the details below. Rest assured they are available to help; you need to contact them directly.</p>').append($('<strong>').text(contactDetails.business_name)).append('<br>');
          if (contactDetails.phone) {
            $message.append($('<a>', {
              class: 'text-primary'
            }).text(contactDetails.phone).attr('href', 'tel:' + contactDetails.phone)).append('<br>');
          }
          if (contactDetails.email) {
            $message.append($('<a>', {
              class: 'text-primary'
            }).text(contactDetails.email).attr('href', 'mailto:' + contactDetails.email));
          }
          bootbox.dialog({
            message: $message.html(),
            onEscape: true,
            backdrop: 'static',
            buttons: {
              close: {
                label: 'Close',
                className: 'btn btn-light'
              }
            }
          });
        } else {}
      } else {
        var params = {
          availability_id: $this.data('availability-id')
        };

        // Check to forward practitioner_id and business_id to bookings form
        var specifiedPractitionerID = Utils.getQueryParameter('practitioner_id');
        if (specifiedPractitionerID) {
          params.practitioner_id = specifiedPractitionerID;
        }
        var specifiedBusinessID = Utils.getQueryParameter('business_id');
        if (specifiedBusinessID) {
          params.business_id = specifiedBusinessID;
        }
        location.href = $this.data('booking-url') + '?' + $.param(params);
      }
    });

    /* Fill the remembered location. If location is not specified and no url query */
    if ($inputLoc.val().trim().length === 0 && window.location.search.length === 0) {
      $inputLoc.val(getRememberedLastLocation());
    }

    /* Fill the remembered profession. If location is not specified and no url query */
    if (!$selectProfession.val()) {
      $selectProfession.val(getRememberedSelectedProfession());
    }
    if ($inputDatepickerCalendar.length > 0) {
      flatpickr($inputDatepickerCalendar, {
        inline: true,
        disableMobile: true,
        minDate: new Date(),
        onDayCreate: function (selectedDates, dateStr, fpInstance, dayElem) {
          var availabilityCount = Math.floor(Math.random() * 10);
          var dateObj = dayElem.dateObj;
          var now = new Date();
          if (dateObj.getTime() > now.getTime() && availabilityCount > 3) {
            dayElem.className += ' has-availability-day';
          }
        }
      });
    }
    if ($resultsFilterWrap.length > 0) {
      $resultsFilterWrap.sticky({
        topSpacing: 70
      });
    }

    /* Track checking near practitioners */
    $nearPractitionersWrap.on('click', '.js-btn-modal-practitioner-profile', function () {
      ahoy_js__WEBPACK_IMPORTED_MODULE_0__["default"].track("View near practitioner profile", {
        tags: "Online bookings",
        referrer: window.location.pathname
      });
    });
  }
});
$(function () {
  if ($('#js-page-facility-bookings').length) {
    var $formSearch = $('#form-search');
    var $selectDateRange = $('#select-date-range');
    var $selectProfession = $('#select-profession');
    var $selectPractitioner = $('#select-practitioner');
    $('.input-custom-date').on('change', function (e) {
      var $this = $(this);
      var date = $this.val();
      if (date) {
        var standardDate = new Date(date).toISOString('YYYY-MM-DD').split('T')[0];
        $selectDateRange.attr('disabled', true);
        $this.attr('disabled', true);
        $('<input>', {
          type: 'hidden',
          name: 'date',
          value: standardDate
        }).appendTo($formSearch);
        $formSearch.trigger('submit');
      } else {
        $('.date-option input[type=radio]').removeAttr('disabled');
      }
    });
    $selectDateRange.on('change', function () {
      $('.input-custom-date').attr('disabled', true);
      $formSearch.trigger('submit');
    });
    $selectProfession.on('change', function () {
      $selectPractitioner.val('');
      $formSearch.trigger('submit');
    });
    $selectPractitioner.on('change', function () {
      $formSearch.trigger('submit');
    });
    $formSearch.on('submit', function () {
      // Disable empty inputs to shorten urls
      if ($selectPractitioner.val() === '') {
        $selectPractitioner.attr('disabled', true);
      }
      if ($selectProfession.val() === '') {
        $selectProfession.attr('disabled', true);
      }
    });

    /* Handle click time icons to navigate to next step */
    $(document).on('click', '.btn-time', function () {
      var $this = $(this);
      var nextStepPath = $this.data('booking-url');
      var params = {
        availability_id: $this.data('availability-id')
      };
      if ($this.data('start-time')) {
        params.start_time = $this.data('start-time');
      }
      params.appointment_type_id = $this.closest('.box-practitioner').find('.input-appointment-type').val();

      // Check to forward practitioner_id and business_id to bookings form
      var specifiedPractitionerID = Utils.getQueryParameter('practitioner_id');
      if (specifiedPractitionerID) {
        params.practitioner_id = specifiedPractitionerID;
      }
      var specifiedBusinessID = Utils.getQueryParameter('business_id');
      if (specifiedBusinessID) {
        params.business_id = specifiedBusinessID;
      }
      location.href = nextStepPath + '?' + $.param(params);
    });
  }
});

/***/ }),

/***/ "./app/javascript/frontend/pages/common.js":
/*!*************************************************!*\
  !*** ./app/javascript/frontend/pages/common.js ***!
  \*************************************************/
/***/ (function() {

$(function () {
  $(".horizontalMenu-list li a").each(function () {
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
$(".cover-image").each(function () {
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
$(document).on('ready', function () {
  $(".horizontalMenu-list li a").each(function () {
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
$(window).on("scroll", function (e) {
  if ($(this).scrollTop() > 0) {
    $('#back-to-top').fadeIn('slow');
  } else {
    $('#back-to-top').fadeOut('slow');
  }
});
$("#back-to-top").on("click", function (e) {
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
document.addEventListener("touchstart", function () {}, false);
jQuery('#horizontal-navtoggle').on('click', function () {
  jQuery('body').toggleClass('active');
});
jQuery('.horizontal-overlapbg').on('click', function () {
  jQuery("body").removeClass('active');
});
jQuery('.horizontalMenu-click').on('click', function () {
  jQuery(this).toggleClass('horizontal-activearrow').parent().siblings().children().removeClass('horizontal-activearrow');
  jQuery(".horizontalMenu > .horizontalMenu-list > li > .sub-menu").not(jQuery(this).siblings('.horizontalMenu > .horizontalMenu-list > li > .sub-menu')).slideUp('slow');
  jQuery(this).siblings('.sub-menu').slideToggle('slow');
});
jQuery(window).on('resize', function () {
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
$(".horizontal-main").sticky({
  topSpacing: 0
}); // Main menu on large screen
$(".horizontal-header").sticky({
  topSpacing: 0
}); // Mobile screen

$('#js-form-subscribe-footer').on('submit', function (e) {
  e.preventDefault();
  const $form = $(this);
  $form.find('[type="submit"]').attr('disabled', true);
  $.ajax({
    method: $form.attr('method'),
    url: $form.attr('action'),
    data: $form.serialize(),
    dataType: 'json',
    success: function (res) {
      if (res.message) {
        window.alert(res.message || 'Thank you for subscribing.');
      }
      $form.get(0).reset();
    },
    error: function (xhr) {
      if (xhr.responseJSON && xhr.responseJSON.message) {
        window.alert(xhr.responseJSON.message);
      } else {
        window.alert('Sorry, an error has occurred.');
      }
      $form.find('[type="submit"]').attr('disabled', false);
    }
  });
});

/* Button show modal practitioner profile */
$('body').on('click', '.js-btn-modal-practitioner-profile', function (e) {
  e.preventDefault();
  const $btn = $(this);
  $.ajax({
    method: 'GET',
    url: $btn.data('url'),
    success: function (html) {
      const $modal = $(html);
      $modal.appendTo('body');
      $modal.modal('show');
    }
  });
});

/* Form search practitioners in local pages */

if ($('#js-form-local-practitioners-search').length) {
  $(function () {
    const country = $('body').data('country');
    const $form = $('#js-form-local-practitioners-search');
    const $inputLoc = $form.find('[name="location"]');
    const $btnGetUserLoc = $form.find('#js-btn-local-get-user-location');
    const $practitionersListWrap = $('#js-local-practitioners-list-wrap');
    $form.on('submit', function (e) {
      e.preventDefault();
      loadPractitioners();
    });
    function loadPractitioners() {
      $.ajax({
        method: 'GET',
        url: $form.attr('action'),
        data: $form.serialize(),
        success: function (html) {
          $practitionersListWrap.html(html);
        }
      });
    }
    ;
    var rememberLastLocation = function (location) {
      try {
        localStorage.setItem('oh.user_current_location', location);
        return true;
      } catch (e) {
        return false;
      }
    };
    var getRememberedLastLocation = function () {
      try {
        return localStorage.getItem('oh.user_current_location');
      } catch (e) {
        return null;
      }
    };
    const autocomplete = new google.maps.places.Autocomplete($inputLoc.get(0), {
      types: ['geocode'],
      componentRestrictions: {
        'country': [country]
      }
    });
    autocomplete.addListener('place_changed', function () {
      var place = autocomplete.getPlace();
      if (place.formatted_address) {
        rememberLastLocation(place.formatted_address);
      }
      setTimeout(function () {
        loadPractitioners();
      }, 300);
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
      var geocoder = new google.maps.Geocoder();
      geocoder.geocode({
        location: {
          lat: position.coords.latitude,
          lng: position.coords.longitude
        }
      }, function (results, status) {
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
      });
    }
    $btnGetUserLoc.on('click', function () {
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
$(document).on('click', function (e) {
  $('[data-toggle="popover"],[data-original-title]').each(function () {
    //the 'is' for buttons that trigger popups
    //the 'has' for icons within a button that triggers a popup
    if (!$(this).is(e.target) && $(this).has(e.target).length === 0 && $('.popover').has(e.target).length === 0) {
      (($(this).popover('hide').data('bs.popover') || {}).inState || {}).click = false; // fix for BS 3.3.6
    }
  });
});

/***/ }),

/***/ "./app/javascript/frontend/pages/embed_team_page.js":
/*!**********************************************************!*\
  !*** ./app/javascript/frontend/pages/embed_team_page.js ***!
  \**********************************************************/
/***/ (function() {

$(function () {
  if ($('#js-embed-team-page-form-search').length) {
    $(function () {
      const country = $('body').data('country') || 'AU';
      const $form = $('#js-embed-team-page-form-search');
      const $inputLoc = $form.find('[name="location"]');
      const $inputProfession = $form.find('[name="profession"]');
      const $btnGetUserLoc = $form.find('.js-btn-local-get-user-location');
      const autocomplete = new google.maps.places.Autocomplete($inputLoc.get(0), {
        types: ['geocode'],
        componentRestrictions: {
          'country': [country]
        }
      });
      autocomplete.addListener('place_changed', function () {
        setTimeout(function () {
          $form.trigger('submit');
        }, 100);
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
        var geocoder = new google.maps.Geocoder();
        geocoder.geocode({
          location: {
            lat: position.coords.latitude,
            lng: position.coords.longitude
          }
        }, function (results, status) {
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
        });
      }
      $btnGetUserLoc.on('click', function () {
        getUserLocation();
      });
      $inputProfession.on('change', function () {
        $form.trigger('submit');
      });
    });
  }
});

/***/ }),

/***/ "./app/javascript/frontend/pages/home.js":
/*!***********************************************!*\
  !*** ./app/javascript/frontend/pages/home.js ***!
  \***********************************************/
/***/ (function() {

$(function () {
  if ($('#js-page-home').length) {
    //=== Hero search
    const $btnGetUserLoc = $('#js-btn-get-user-location');
    const $form = $('#js-form-hero-search');
    const $inputLoc = $('#js-input-location');
    const $inputProfession = $('#js-input-profession');
    $('.js-button-select-profession').on('click', function (e) {
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
    $inputProfession.on('change', function () {
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
    var rememberLastLocation = function (location) {
      try {
        localStorage.setItem('oh.user_current_location', location);
        return true;
      } catch (e) {
        return false;
      }
    };
    var rememberSelectedProfession = function (prof) {
      try {
        localStorage.setItem('oh.user_selected_profession', prof);
        return true;
      } catch (e) {
        return false;
      }
    };
    var clearRememberedLastLocation = function () {
      try {
        localStorage.removeItem('oh.user_current_location');
        return true;
      } catch (e) {
        return false;
      }
    };
    var getRememberedLastLocation = function () {
      try {
        return localStorage.getItem('oh.user_current_location');
      } catch (e) {
        return null;
      }
    };
    var getRememberedSelectedProfession = function () {
      try {
        return localStorage.getItem('oh.user_selected_profession');
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
      $btnGetUserLoc.find('.fa').removeClass('fa-crosshairs').addClass('fa-spin fa-spinner');
      if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(handleUserLocation, showGeolocationError);
      } else {
        alert("Geolocation is not supported by your browser.");
      }
    }
    function handleUserLocation(position) {
      $btnGetUserLoc.find('.fa').addClass('fa-crosshairs').removeClass('fa-spin fa-spinner');
      var geocoder = new google.maps.Geocoder();
      geocoder.geocode({
        location: {
          lat: position.coords.latitude,
          lng: position.coords.longitude
        }
      }, function (results, status) {
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
      });
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
    autocomplete = new google.maps.places.Autocomplete($inputLoc.get(0), {
      types: ['geocode'],
      componentRestrictions: {
        'country': $('body').data('country')
      }
    });
    autocomplete.addListener('place_changed', locationSelected);

    /* Handle click current location */
    $('#js-btn-get-user-location').on('click', function () {
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
        success: function (html) {
          $wrap.html(html);
        }
      });
    }
    // </Top practitioners section>
  }
});

/***/ }),

/***/ "./app/javascript/frontend/pages/practitioner_profile.js":
/*!***************************************************************!*\
  !*** ./app/javascript/frontend/pages/practitioner_profile.js ***!
  \***************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var ahoy_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ahoy.js */ "./node_modules/ahoy.js/dist/ahoy.esm.js");
const {
  default: flatpickr
} = __webpack_require__(/*! flatpickr */ "./node_modules/flatpickr/dist/esm/index.js");

$(function () {
  if ($('#js-page-practitioner-profile').length) {
    const $wrap = $('#js-availability-section-wrap');
    if ($wrap.length === 0) {
      return;
    }
    const $datepickerEl = $('#js-availability-calendar-datepicker');
    const $availabilityListWrap = $('#js-availability-list-wrap');
    const today = new Date();
    const next30Date = new Date(new Date().setDate(today.getDate() + 30));
    let availableDates = [];
    let flatpickrInstance;
    let selectedDate = null;
    let userTimeZone = 'UTC';
    try {
      userTimeZone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    } catch {
      console.warn('Could not determine user time zone.');
    }

    //== Highlight dates that have availability. This has a limit of next 30 days only.
    const initAvailabilityCalendar = function () {
      $.ajax({
        url: $wrap.data('practitioner-slug') + '/available_next_30_days',
        data: {
          time_zone: userTimeZone
        },
        method: 'GET',
        success: function (res) {
          availableDates = res.available_dates;
          flatpickrInstance.redraw();
        }
      });
    };

    //== Update the availability list as the selected date
    const fetchAvailabilityList = function (dateStr) {
      $.ajax({
        url: $wrap.data('practitioner-slug') + '/availablity_list',
        data: {
          date: dateStr,
          time_zone: userTimeZone
        },
        method: 'GET',
        success: function (res) {
          $availabilityListWrap.html(res);
        }
      });
    };
    flatpickr($datepickerEl, {
      inline: true,
      disableMobile: true,
      minDate: today,
      maxDate: next30Date,
      locale: {
        firstDayOfWeek: 1
      },
      onDayCreate: function (selectedDates, selectedDateStr, fpInstance, dayElem) {
        let dayStr = Utils.dateToStandardFormat(dayElem.dateObj);
        if (availableDates.indexOf(dayStr) !== -1) {
          dayElem.className += ' has-availability-day';
        }
      },
      onReady: function (selectedDates, selectedDateStr, fpInstance) {
        flatpickrInstance = fpInstance;
        initAvailabilityCalendar();
        // Load tomorrow availability list
        setTimeout(function () {
          let tomorrow = new Date();
          tomorrow.setDate(today.getDate() + 1);
          fpInstance.setDate(tomorrow);
          fetchAvailabilityList(fpInstance.formatDate(tomorrow, 'Y-m-d'));
        });
      },
      onChange: function (selectedDates, selectedDateStr, fpInstance) {
        if (selectedDate != selectedDateStr) {
          ahoy_js__WEBPACK_IMPORTED_MODULE_0__["default"].track("View practitioner availability calendar", {
            tags: "Practitioner availability calendar",
            referrer: window.location.pathname
          });
          fetchAvailabilityList(selectedDateStr);
          selectedDate = selectedDateStr;
        }
      }
    });
    $wrap.on('click', '.js-btn-availability', function (e) {
      e.preventDefault();
      ahoy_js__WEBPACK_IMPORTED_MODULE_0__["default"].track("Press practitioner availability button", {
        tags: "Practitioner availability calendar",
        referrer: window.location.pathname
      });
      const $btn = $(this);
      if ($btn.hasClass('not-allowed-book-online')) {
        e.preventDefault();
        const $message = $('<div>').append($('<h4>', {
          class: 'text-warning mb-3',
          text: 'Online bookings disabled'
        })).append('<p>Online booking have been disabled for this practitioner by their business admin. To make an appointment with this practitioner, contact their business directly. Rest assured they are available to help.</p>');
        bootbox.dialog({
          message: $message.html(),
          onEscape: true,
          backdrop: 'static',
          buttons: {
            close: {
              label: 'Close',
              className: 'btn btn-light'
            }
          }
        });
      } else {
        window.location.href = $btn.data('booking-url');
      }
    });
    $wrap.removeClass('d-none');
  }
});

/***/ }),

/***/ "./app/javascript/frontend/pages/pricing.js":
/*!**************************************************!*\
  !*** ./app/javascript/frontend/pages/pricing.js ***!
  \**************************************************/
/***/ (function() {

$(function () {
  if ($('#js-page-pricing').length) {
    /* Submit form immediality when a select changed */
    $('#js-form-search select').on('change', function () {
      $('#js-form-search').trigger('submit');
    });
    $('#js-form-search').on('submit', function () {
      // Disable empty inputs to avoid redundant query in url
      $('#js-input-profession, #js-input-location, #js-input-service, #js-input-rate, #js-input-max-price').each(function () {
        if ($(this).val().trim().length === 0) {
          $(this).attr('disabled', 'disabled');
        }
      });
    });
  }
});

/***/ }),

/***/ "./app/javascript/frontend/pages/referrals.js":
/*!****************************************************!*\
  !*** ./app/javascript/frontend/pages/referrals.js ***!
  \****************************************************/
/***/ (function() {

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
                $($inputElement).val(item.short_name + '/');
              } else {
                $($inputElement).val($inputElement.val() + item.short_name);
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
    }
    ;
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

/***/ }),

/***/ "./app/javascript/frontend/pages/team.js":
/*!***********************************************!*\
  !*** ./app/javascript/frontend/pages/team.js ***!
  \***********************************************/
/***/ (function() {

$(function () {
  if ($('#js-page-team').length) {
    const country = $('body').data('country');
    const $inputLoc = $('#js-input-location-search');
    const $inputProfession = $('#js-input-profession');
    const $btnGetUserLoc = $('#js-btn-get-user-location');
    const $form = $('#js-form-search');
    var rememberLastLocation = function (location) {
      try {
        localStorage.setItem('oh.user_current_location', location);
        return true;
      } catch (e) {
        return false;
      }
    };
    var getRememberedLastLocation = function () {
      try {
        return localStorage.getItem('oh.user_current_location');
      } catch (e) {
        return null;
      }
    };
    var getRememberedSelectedProfession = function () {
      try {
        return localStorage.getItem('oh.user_selected_profession');
      } catch (e) {
        return null;
      }
    };
    var rememberSelectedProfession = function (prof) {
      try {
        localStorage.setItem('oh.user_selected_profession', prof);
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
      var geocoder = new google.maps.Geocoder();
      geocoder.geocode({
        location: {
          lat: position.coords.latitude,
          lng: position.coords.longitude
        }
      }, function (results, status) {
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
      });
    }
    var autocomplete = new google.maps.places.Autocomplete($inputLoc.get(0), {
      types: ['geocode'],
      componentRestrictions: {
        'country': [country]
      }
    });
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

/***/ }),

/***/ "./app/javascript/frontend/styles/custom.scss":
/*!****************************************************!*\
  !*** ./app/javascript/frontend/styles/custom.scss ***!
  \****************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
// extracted by mini-css-extract-plugin


/***/ }),

/***/ "./app/javascript/frontend/styles/custom/flatpickr.scss":
/*!**************************************************************!*\
  !*** ./app/javascript/frontend/styles/custom/flatpickr.scss ***!
  \**************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
// extracted by mini-css-extract-plugin


/***/ }),

/***/ "./app/javascript/frontend/styles/pages/bookings.scss":
/*!************************************************************!*\
  !*** ./app/javascript/frontend/styles/pages/bookings.scss ***!
  \************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
// extracted by mini-css-extract-plugin


/***/ }),

/***/ "./app/javascript/frontend/styles/theme-overrides.scss":
/*!*************************************************************!*\
  !*** ./app/javascript/frontend/styles/theme-overrides.scss ***!
  \*************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
// extracted by mini-css-extract-plugin


/***/ }),

/***/ "./app/javascript/medz/color-skins/color-custom.scss":
/*!***********************************************************!*\
  !*** ./app/javascript/medz/color-skins/color-custom.scss ***!
  \***********************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
// extracted by mini-css-extract-plugin


/***/ }),

/***/ "./app/javascript/medz/iconfonts/feather/feather.css":
/*!***********************************************************!*\
  !*** ./app/javascript/medz/iconfonts/feather/feather.css ***!
  \***********************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
// extracted by mini-css-extract-plugin


/***/ }),

/***/ "./app/javascript/medz/iconfonts/font-awesome/css/font-awesome.css":
/*!*************************************************************************!*\
  !*** ./app/javascript/medz/iconfonts/font-awesome/css/font-awesome.css ***!
  \*************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
// extracted by mini-css-extract-plugin


/***/ }),

/***/ "./app/javascript/medz/scss/style-optimized.scss":
/*!*******************************************************!*\
  !*** ./app/javascript/medz/scss/style-optimized.scss ***!
  \*******************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
// extracted by mini-css-extract-plugin


/***/ }),

/***/ "./app/javascript/packs/frontend.js":
/*!******************************************!*\
  !*** ./app/javascript/packs/frontend.js ***!
  \******************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var jquery__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! jquery */ "./node_modules/jquery/dist/jquery.js");
/* harmony import */ var jquery__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(jquery__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var medz_scss_style_optimized_scss__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! medz/scss/style-optimized.scss */ "./app/javascript/medz/scss/style-optimized.scss");
/* harmony import */ var medz_color_skins_color_custom__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! medz/color-skins/color-custom */ "./app/javascript/medz/color-skins/color-custom.scss");
/* harmony import */ var frontend_styles_theme_overrides__WEBPACK_IMPORTED_MODULE_3__ = __webpack_require__(/*! frontend/styles/theme-overrides */ "./app/javascript/frontend/styles/theme-overrides.scss");
/* harmony import */ var frontend_styles_custom__WEBPACK_IMPORTED_MODULE_4__ = __webpack_require__(/*! frontend/styles/custom */ "./app/javascript/frontend/styles/custom.scss");
/* harmony import */ var frontend_styles_pages_bookings__WEBPACK_IMPORTED_MODULE_5__ = __webpack_require__(/*! frontend/styles/pages/bookings */ "./app/javascript/frontend/styles/pages/bookings.scss");
/* harmony import */ var flatpickr_dist_flatpickr_css__WEBPACK_IMPORTED_MODULE_6__ = __webpack_require__(/*! flatpickr/dist/flatpickr.css */ "./node_modules/flatpickr/dist/flatpickr.css");
/* harmony import */ var medz_iconfonts_font_awesome_css_font_awesome_css__WEBPACK_IMPORTED_MODULE_7__ = __webpack_require__(/*! medz/iconfonts/font-awesome/css/font-awesome.css */ "./app/javascript/medz/iconfonts/font-awesome/css/font-awesome.css");
/* harmony import */ var medz_iconfonts_feather_feather_css__WEBPACK_IMPORTED_MODULE_8__ = __webpack_require__(/*! medz/iconfonts/feather/feather.css */ "./app/javascript/medz/iconfonts/feather/feather.css");
/* harmony import */ var frontend_styles_custom_flatpickr__WEBPACK_IMPORTED_MODULE_9__ = __webpack_require__(/*! frontend/styles/custom/flatpickr */ "./app/javascript/frontend/styles/custom/flatpickr.scss");
const importAll = r => r.keys().map(r);

//=== JS dependencies

window.$ = window.jQuery = (jquery__WEBPACK_IMPORTED_MODULE_0___default());

//=== Medz theme core





//== Pages CSS


//=== Medz theme dependencies
__webpack_require__(/*! jquery-sticky */ "./node_modules/jquery-sticky/jquery.sticky.js");


//=== Webfont icons



//== Custom style

__webpack_require__(/*! bootstrap */ "./node_modules/bootstrap/dist/js/bootstrap.js");
window.bootbox = __webpack_require__(/*! bootbox */ "./node_modules/bootbox/bootbox.js");
__webpack_require__(/*! jquery-serializejson */ "./node_modules/jquery-serializejson/jquery.serializejson.js");

//=== Images
// TODO: remove unused images imports
importAll(__webpack_require__("./app/javascript/frontend/images sync \\.(png%7Cjpe?g)$"));

//==s Functions
__webpack_require__(/*! frontend/functions/events_tracking.js */ "./app/javascript/frontend/functions/events_tracking.js");
__webpack_require__(/*! frontend/functions/utils.js */ "./app/javascript/frontend/functions/utils.js");

//=== Pages js
__webpack_require__(/*! frontend/pages/common.js */ "./app/javascript/frontend/pages/common.js");
__webpack_require__(/*! frontend/pages/home.js */ "./app/javascript/frontend/pages/home.js");
__webpack_require__(/*! frontend/pages/referrals.js */ "./app/javascript/frontend/pages/referrals.js");
__webpack_require__(/*! frontend/pages/pricing.js */ "./app/javascript/frontend/pages/pricing.js");
__webpack_require__(/*! frontend/pages/team.js */ "./app/javascript/frontend/pages/team.js");
__webpack_require__(/*! frontend/pages/bookings.js */ "./app/javascript/frontend/pages/bookings.js");
__webpack_require__(/*! frontend/pages/booking_form.js */ "./app/javascript/frontend/pages/booking_form.js");
__webpack_require__(/*! frontend/pages/embed_team_page.js */ "./app/javascript/frontend/pages/embed_team_page.js");
__webpack_require__(/*! frontend/pages/practitioner_profile.js */ "./app/javascript/frontend/pages/practitioner_profile.js");

/***/ })

},
/******/ function(__webpack_require__) { // webpackRuntimeModules
/******/ var __webpack_exec__ = function(moduleId) { return __webpack_require__(__webpack_require__.s = moduleId); }
/******/ __webpack_require__.O(0, ["vendors-node_modules_bootbox_bootbox_js-node_modules_bootstrap_dist_js_bootstrap_js-node_modu-986106"], function() { return __webpack_exec__("./app/javascript/packs/frontend.js"); });
/******/ var __webpack_exports__ = __webpack_require__.O();
/******/ }
]);
//# sourceMappingURL=frontend.js.map