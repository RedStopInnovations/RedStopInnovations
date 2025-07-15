(function() {
  'use strict';

  Vue.component('modal-create-patient', {
    template: '#modal-create-patient-tmpl',
    mixins: [bootstrapModal],
    props: {
      business: {
        type: Object,
        required: true
      }
    },
    data: function() {
      return {
        show: false,
        patient: {
          first_name: null,
          last_name: null,
          dob: null,
          phone: null,
          mobile: null,
          email: null,
          address1: null,
          address2: null,
          city: null,
          state: null,
          postcode: null,
          country: this.business.country,
          accepted_privacy_policy: null,
          reminder_enable: true
        },
        formErrors: [],
        loading: false,
        dobDatepickerConfig: {
          clickOpens: false,
          allowInput: true,
          altFormat: 'd/m/Y',
          dateFormat: 'Y-m-d',
          altInput: true,
          disableMobile: true
        }
      };
    },
    watch: {
      show: function() {
        this.resetForm();
      }
    },
    mounted: function() {
      // Workaround for manual input dont update DOM:
      // @see: https://github.com/flatpickr/flatpickr/issues/828
      var fpInstance = this.$refs.dobDatepicker.fp;
      $(fpInstance._input).on('change', function() {
        var date = new Date($(this).val());
        var valid = moment(date).isValid();
        if (!valid) {
          fpInstance.clear();
        }
      });
      var self = this;
      CalendarEventBus.$on('patient-add', function() {
        self.show = true;
      });
    },
    methods: {
      onModalClosed: function() {
        this.show = false;
      },
      showModal: function() {
        this.show = true;
      },
      resetForm: function() {
        this.patient = {
          first_name: null,
          last_name: null,
          dob: null,
          phone: null,
          mobile: null,
          email: null,
          address1: null,
          city: null,
          state: null,
          postcode: null,
          country: this.business.country,
          accepted_privacy_policy: null,
          reminder_enable: true
        };
        this.formErrors = [];
      },
      openDatepicker: function() {
        var fpInstance = this.$refs.dobDatepicker.fp;
        fpInstance.open();
        if (!this.patient.dob) {
          fpInstance.jumpToDate(new Date('1975-01-01'));
        }
      },
      onGooglePlaceSelected: function(place) {
        var address1 = null;
        var city = null;
        var state = null;
        var postcode = null;
        var country = null;
        for (var i = 0; i < place.address_components.length; i++) {
          var component = place.address_components[i];

          if (component.types.indexOf('subpremise') !== -1) {
            address1 = component.short_name + '/';
          }

          if (component.types.indexOf('street_number') !== -1) {
            if(address1) {
              address1 += component.short_name;
            } else {
              address1 = component.short_name;
            }
          }
          if (component.types.indexOf('route') !== -1) {
            address1 = [address1, component.short_name].join(' ').trim();
          }
          if (component.types.indexOf('postal_town') !== -1) {
            city = component.short_name;
          }
          if (component.types.indexOf('locality') !== -1) {
            city = component.short_name;
          }
          if (component.types.indexOf('administrative_area_level_1') !== -1) {
            state = component.short_name;
          }
          if (component.types.indexOf('postal_code') !== -1) {
            postcode = component.long_name;
          }
          if(component.types.indexOf('country') !== -1) {
            country = component.short_name;
          }
        }

        this.patient.address1 = address1;
        this.patient.city = city;
        this.patient.state = state;
        this.patient.postcode = postcode;
        this.patient.country = country;
      },
      bindGoogleAutocomplete: function() {
        var that = this;
        var autocomplete = new google.maps.places.Autocomplete(
          this.$refs.inputAddress1, autocompleteDefaultOptions
        );

        autocomplete.addListener('place_changed', function() {
          that.onGooglePlaceSelected(autocomplete.getPlace());
        });
      },
      submitForm: function() {
        var that = this;

        that.formErrors = [];
        $.ajax({
          method: 'POST',
          url: '/api/patients',
          data: { patient: that.patient },
          success: function(res) {
            that.show = false;
            that.$notify('The client has been created successfully.');
            that.$emit('patient-created', res.patient);
            CalendarEventBus.$emit('patient-created', res.patient);
          },
          beforeSend: function() {
            that.loading = true;
          },
          error: function(xhr) {
            if (xhr.status === 422) {
              that.formErrors = xhr.responseJSON.errors;
            } else {
              var errorMsg = 'An error has occurred. Sorry for the inconvenience.';
              if (xhr.responseJSON && xhr.responseJSON.message) {
                errorMsg = xhr.responseJSON.message;
              }
              that.$notify(errorMsg, 'error');
            }
          },
          complete: function() {
            that.loading = false;
          }
        });
      }
    }
  });
})();
