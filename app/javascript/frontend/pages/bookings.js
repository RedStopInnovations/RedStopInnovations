const { default: flatpickr } = require("flatpickr");
import ahoy from "ahoy.js";

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
                            $formSearch.trigger('submit');
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
        (function () {
            var autocomplete;

            function locationSelected() {
                var place = autocomplete.getPlace();
                if (place.formatted_address) {
                    rememberLastLocation(place.formatted_address);
                    $formSearch.trigger('submit');
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
        })();

        /* Handle click current location */
        $('.btn-set-current-location').on('click', function () {
            getUserLocation();
        });

        $('.input-custom-date').on('change', function (e) {
            var $this = $(this);
            var date = $this.val();
            if (date) {
                var standardDate = (new Date(date)).toISOString('YYYY-MM-DD').split('T')[0];
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

                    const $message = $('<div>')
                        .append(
                            $('<h4>', {
                                class:'text-warning mb-3',
                                text: 'Online booking disabled'
                            })
                        )
                        .append('<p>Online booking have been disabled for this practitioner by their business admin. To make an appointment with this practitioner, contact their business directly via the details below. Rest assured they are available to help; you need to contact them directly.</p>')
                        .append($('<strong>').text(contactDetails.business_name))
                        .append('<br>');

                    if (contactDetails.phone) {
                        $message.append($('<a>', {class: 'text-primary'}).text(contactDetails.phone).attr('href', 'tel:' + contactDetails.phone))
                            .append('<br>');
                    }

                    if (contactDetails.email) {
                        $message.append($('<a>', {class: 'text-primary'}).text(contactDetails.email).attr('href', 'mailto:' + contactDetails.email))
                    }

                    bootbox.dialog({
                        message: $message.html(),
                        onEscape: true,
                        backdrop: 'static',
                        buttons: {
                            close: {
                                label: 'Close',
                                className: 'btn btn-light'
                            },
                        }
                    });
                } else {

                }
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
                onDayCreate: function(selectedDates, dateStr, fpInstance, dayElem){
                    var availabilityCount = Math.floor(Math.random() * 10);
                    var dateObj = dayElem.dateObj;

                    var now = new Date();

                    if ((dateObj.getTime() > now.getTime()) && availabilityCount > 3) {
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
        $nearPractitionersWrap.on('click', '.js-btn-modal-practitioner-profile', function() {
            ahoy.track("View near practitioner profile", {tags: "Online bookings", referrer: window.location.pathname});
        });
    }
});

$(function() {
    if ($('#js-page-facility-bookings').length) {
        var $formSearch = $('#form-search');
        var $selectDateRange = $('#select-date-range');
        var $selectProfession = $('#select-profession');
        var $selectPractitioner = $('#select-practitioner');

        $('.input-custom-date').on('change', function(e) {
            var $this = $(this);
            var date = $this.val();
            if (date) {
                var standardDate = (new Date(date)).toISOString('YYYY-MM-DD').split('T')[0];
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

        $selectDateRange.on('change', function() {
            $('.input-custom-date').attr('disabled', true);
            $formSearch.trigger('submit');
        });

        $selectProfession.on('change', function() {
            $selectPractitioner.val('');
            $formSearch.trigger('submit');
        });

        $selectPractitioner.on('change', function() {
            $formSearch.trigger('submit');
        });

        $formSearch.on('submit', function() {
            // Disable empty inputs to shorten urls
            if ($selectPractitioner.val() === '') {
                $selectPractitioner.attr('disabled', true);
            }

            if ($selectProfession.val() === '') {
                $selectProfession.attr('disabled', true);
            }
        });

        /* Handle click time icons to navigate to next step */
        $(document).on('click', '.btn-time', function() {
            var $this = $(this);
            var nextStepPath = $this.data('booking-url');
            var params = {
                availability_id: $this.data('availability-id')
            };
            if ($this.data('start-time')) {
                params.start_time = $this.data('start-time');
            }

            params.appointment_type_id = $this.closest('.box-practitioner')
                .find('.input-appointment-type')
                .val();

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