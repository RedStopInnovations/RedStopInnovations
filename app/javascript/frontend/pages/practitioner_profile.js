const { default: flatpickr } = require("flatpickr");
import ahoy from "ahoy.js";

$(function () {
  if ($('#js-page-practitioner-profile').length) {
    const $wrap = $('#js-availability-section-wrap');
    if ($wrap.length === 0) {
      return;
    }
    const $datepickerEl = $('#js-availability-calendar-datepicker');
    const $availabilityListWrap = $('#js-availability-list-wrap');
    const today = new Date;
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
        setTimeout(function() {
          let tomorrow = new Date(); tomorrow.setDate(today.getDate() + 1);
          fpInstance.setDate(tomorrow);
          fetchAvailabilityList(fpInstance.formatDate(tomorrow, 'Y-m-d'));
        });
      },

      onChange: function (selectedDates, selectedDateStr, fpInstance) {
        if (selectedDate != selectedDateStr) {
          ahoy.track("View practitioner availability calendar", {tags: "Practitioner availability calendar", referrer: window.location.pathname});
          fetchAvailabilityList(selectedDateStr);
          selectedDate = selectedDateStr;
        }
      }
    });

    $wrap.on('click', '.js-btn-availability', function (e) {
      e.preventDefault();
      ahoy.track("Press practitioner availability button", {tags: "Practitioner availability calendar", referrer: window.location.pathname});

      const $btn = $(this);
      if ($btn.hasClass('not-allowed-book-online')) {
        e.preventDefault();
        const $message = $('<div>')
          .append(
            $('<h4>', {
              class: 'text-warning mb-3',
              text: 'Online bookings disabled'
            })
          )
          .append('<p>Online booking have been disabled for this practitioner by their business admin. To make an appointment with this practitioner, contact their business directly. Rest assured they are available to help.</p>');

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