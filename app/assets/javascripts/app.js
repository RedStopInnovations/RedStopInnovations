(function () {
  /* Alway set CSRF token for JQuery AJAX calls */
  $.ajaxSetup({
    headers: { 'X-CSRF-TOKEN': $('meta[name="csrf-token"]').attr('content') }
  });

  $.fn.bindFlatpickr = function() {
    var $this = $(this);
    var options = {};
    if ($this.data('alt-format')) {
      options.altFormat = $this.data('alt-format');
      options.altInput = true;
    }

    if ($this.data('date-format')) {
      options.dateFormat = $this.data('date-format');
    }

    if ($this.data('allow-input')) {
      options.allowInput = $this.data('allow-input');
    }
    $this.flatpickr(options);
  };

  $(document).ready(function () {
    // Fix opened dropdown menu is cut off in table-responsive
    $(document).on('shown.bs.dropdown', '.table-responsive', function (e) {
      // The .dropdown container
      var $container = $(e.target);
      var $btnToggle = $container.find('.dropdown-toggle');

      // Find the actual .dropdown-menu
      var $dropdown = $container.find('.dropdown-menu');
      if ($dropdown.length) {
        // Save a reference to it, so we can find it after we've attached it to the body
        $container.data('dropdown-menu', $dropdown);
      } else {
        $dropdown = $container.data('dropdown-menu');
      }

      var width = $dropdown.width();
      var top = $btnToggle.offset().top + $container.outerHeight();
      var left = $btnToggle.offset().left - width + $btnToggle.outerWidth();

      $dropdown.css('width', width + 'px');
      $dropdown.css('top', top + 'px');
      $dropdown.css('left', left + 'px');
      $dropdown.css('position', 'absolute');
      $dropdown.css('display', 'block');
      $dropdown.appendTo('.content-wrapper');
    });

    $(document).on('hide.bs.dropdown', '.table-responsive', function (e) {
      // Hide the dropdown menu bound to this button
      $(e.target).data('dropdown-menu').css('display', 'none');
    });

    /* Save sidebar open/close state */
    if (Utils.isLocalStorageAvailable()) {
      $($.AdminLTE.options.sidebarToggleSelector).click(function () {
        setTimeout(function () {
          localStorage.setItem(
            'tracksy.app_sidebar_state',
            $('body').hasClass('sidebar-collapse') ? 0 : 1
          );
        }, 100);
      });
    }

    /* Bind selectize plugins to select has class 'selectize' */
    $('.selectize').each(function () {
      var $this = $(this);
      var options = {};
      if ($this.attr('multiple')) {
        options.plugins = ['remove_button'];
      }
      if ($this.data('max-options')) {
        options.maxOptions = parseInt($this.data('max-options'));
      }
      $this.selectize(options);
    });
    $('.selectize-patients-ajax').each(function () {
      var $this = $(this);
      var plcHolder = 'Type to search client';
      var plugins = ['no_results'];
      if ($this.attr('placeholder')) {
        plcHolder = $this.attr('placeholder');
      }
      if ($this.attr('multiple')) {
        plugins.push('remove_button');
      }
      $this.selectize({
        plugins: plugins,
        valueField: 'id',
        labelField: 'full_name',
        searchField: 'full_name',
        create: false,
        placeholder: plcHolder,
        render: {
          option: function (item, escape) {
            return '<div>' + escape(item.full_name) + '</div>';
          }
        },
        load: function (query, callback) {
          if (!query.length) return callback();
          var self = this;

          $.get(
            '/api/patients/search?business_id=' + window.session.user.business_id + '&s=' + query,
            function (res) {
              if (res.patients.length > 0) {
                callback(res.patients);
              } else {
                self.$empty_results_container.show();
              }
            }
          );
        }
      });

    });

    $('.selectize-contacts-ajax').each(function () {
      var $this = $(this);
      var plcHolder = 'Type to search contact';
      var plugins = ['no_results'];
      if ($this.attr('placeholder')) {
        plcHolder = $this.attr('placeholder');
      }
      if ($this.attr('multiple')) {
        plugins.push('remove_button');
      }
      $this.selectize({
        plugins: plugins,
        valueField: 'id',
        labelField: 'business_name',
        searchField: ['business_name', 'email', 'full_name'],
        create: false,
        placeholder: plcHolder,
        render: {
          option: function (item, escape) {
            return '<div>' + escape(item.business_name) + '</div>';
          }
        },
        load: function (query, callback) {
          if (!query.length) return callback();
          var self = this;

          $.get(
            '/api/contacts/search?business_id=' + window.session.user.business_id + '&s=' + query,
            function (res) {
              if (res.contacts.length > 0) {
                callback(res.contacts);
              } else {
                self.$empty_results_container.show();
              }
            }
          );
        }
      });
    });

    // Modal Tooltip
    $('[data-toggle="tooltip"]').tooltip();

    /**
     * Bind date pickers to inputs with flatpickr plugin.
     * Passing options as attributes:
     *   - format
     */
    $('.flatpickr-datepicker').each(function () {
      $(this).bindFlatpickr();
    });

    /* Active state for main sidebar menus */
    (function () {
      if ($('.main-sidebar').length) {
        $('.main-sidebar li a[href="' + window.location.pathname + '"]')
          .parent()
          .addClass('active')
          .closest('.treeview')
          .addClass('active');
      }
    })();

    /* Active state for patient sidebar menus */
    (function () {
      if ($('.patient-sidebar').length) {
        $('.patient-sidebar li a[href="' + window.location.pathname + '"]')
          .closest('li')
          .addClass('active');
      }
    })();

    /* Alerts for not implemented buttons */
    $('body').on('click', '.not-implemented', function (e) {
      e.preventDefault();
      alert('Not implemented yet :(');
      return false;
    });

    /* Active Bootstrap popover */
    $('[data-toggle="popover"]').popover();

    /* Default options for Pnotify */
    (function () {
      PNotify.prototype.options.width = '350px';
      PNotify.prototype.options.delay = 3500;
      PNotify.prototype.options.buttons.sticker = false;
      PNotify.prototype.options.buttons.closer_hover = false;
      PNotify.prototype.options.addclass = "stack-bottomright";
      PNotify.prototype.options.stack = { "dir1": "up", "dir2": "left", "firstpos1": 25, "firstpos2": 25 };
    })();

    /**
     * Handler buttons which acts as a inline form
     * Usage: <button data-form-url="" data-form-method="method" data-form-confirmation="Are you sure?"></button>
     */
    $('body').on('click', '.btn-form', function (e) {
      e.preventDefault();
      var $this = $(this);
      var formUrl = $this.data('form-url');
      var formMethod = $this.data('form-method') || 'POST';
      var csrfToken = $('meta[name="csrf-token"]').attr('content');
      var confirmMsg = $this.data('form-confirmation');

      // Build form inputs
      var form = $('<form>', {
        'method': 'POST',
        'action': formUrl
      });
      var csrfInput = $('<input>', {
        'type': 'hidden',
        'name': 'authenticity_token',
        'value': csrfToken
      });
      var methodInput = $('<input>', {
        'name': '_method',
        'type': 'hidden',
        'value': formMethod
      });

      if (confirmMsg != undefined) {
        if (confirm(confirmMsg)) {
          form.append(csrfInput, methodInput).hide().appendTo('body').submit();
          $this.attr('disabled', true);
        }
      } else {
        form.append(csrfInput, methodInput).hide().appendTo('body').submit();
        $this.attr('disabled', true);
      }
    });

    /**
     * Handle button print using iframe
     */
    $(document).on('click', '.btn-iframe-print', function (e) {
      e.preventDefault();
      var $btn = $(this);
      var url = $btn.data('url');
      if (url) {
        $('body').loadingOn();
        $('iframe[name="printf"]').remove();
        var ifr = $('<iframe>', {
          class: 'hide',
          name: 'printf',
          src: url
        });

        ifr.on('load', function () {
          $('body').loadingOff();
          window.frames["printf"].focus();
          window.frames["printf"].print();
          $('iframe[name="printf"]').remove();
        });
        ifr.appendTo($('body'));
      } else {
        throw ("Button iframe print: URL is not specified.")
      }
    });

    $(document).on('click', '.js-btn-trigger-sms', function(e) {
      const $btn = $(this);
      if ($btn.attr('href').startsWith('#')) {
        e.preventDefault();
        // e.stopPropagation();
        const encodedData = $btn.data('sms');
        const jsonData = JSON.parse(atob(encodedData));

        if (!jsonData.number) {
          Flash.error('The mobile number is blank.');
        } else {
          let openMessageUrl = 'sms:' + jsonData.number;

          if (jsonData.body) {

            if (navigator.userAgent.match(/Android/i)) {
              openMessageUrl += '?body=';
            } else if(navigator.userAgent.match(/iPhone/i)) {
              openMessageUrl += '&body=';
            } else {
              openMessageUrl += '&body=';
            }

            openMessageUrl += encodeURIComponent(jsonData.body);
            $btn.attr('href', openMessageUrl);

            $btn.get(0).click();
          }
        }

        $btn.addClass('link-visually-visited');
      }

    });

    /**
     * Handle button click to copy
     */
    $('[js-click-to-copy]').each(function(i, elm) {
      const $btn = $(elm);

      const clipboard = new Clipboard(elm, {
        text: function() {
          return $btn.attr('js-click-to-copy');
        }
      });

      clipboard.on('success', function(e) {
        Flash.success('Copied');
      });

    });

  });
})();
