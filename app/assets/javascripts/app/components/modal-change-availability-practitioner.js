(function() {
  'use strict';

  Vue.component('modal-change-availability-practitioner', {
    template: '#modal-change-availability-practitioner-tmpl',
    mixins: [bootstrapModal],
    data: function() {
      return {
        show: false,
        loading: false,
        availability: null,
        selectedPractitioner: null,
        applyToFutureRepeats: false,
        formErrors: []
      };
    },
    props: {
      business: {
        type: Object,
        required: true
      }
    },
    computed: {
      practitioners: function() {
        var practs = [];
        for (var i = 0, l = this.business.practitioners.length; i < l; i++) {
          var pract = this.business.practitioners[i];
          if (pract.id !== this.availability.practitioner_id) {
            practs.push(pract);
          }
        }
        return practs;
      }
    },
    methods: {
      showModal: function(availability) {
        this.availability = availability;
        this.selectedPractitioner = null;
        this.applyToFutureRepeats = false;
        this.formErrors = [];
        this.show = true;
      },
      onModalClosed: function() {
        this.show = false;
        this.selectedPractitioner = null;
        this.applyToFutureRepeats = false;
      },
      cancel: function() {
        this.show = false;
      },
      buildFormData: function() {
        var data = {};
        if (this.selectedPractitioner) {
          data.practitioner_id = this.selectedPractitioner.id;
        }

        data.apply_to_future_repeats = this.applyToFutureRepeats;

        return data;
      },
      submit: function() {
        var that = this;
        $.ajax({
          method: 'PUT',
          url: '/api/availabilities/' + that.availability.id + '/change_practitioner',
          dataType: 'json',
          contentType: 'application/json',
          data: JSON.stringify(that.buildFormData()),
          beforeSend: function() {
            that.loading = true;
            that.formErrors = [];
          },
          success: function(res) {
            that.$notify('The practitioner has been successfully updated.');
            that.$emit('availability-updated-practitioner', res.availability);
            that.show = false;
          },
          error: function(xhr) {
            var errorMsg = 'An error has occurred. Sorry for the inconvenience.';

            if (xhr.responseJSON) {
              if (xhr.status === 422 && xhr.responseJSON.errors) {
                that.formErrors = xhr.responseJSON.errors;
                if (!xhr.responseJSON.message) {
                  errorMsg = 'Failed to change practitioner. Please check for form errors.'
                }
              }

              if (xhr.responseJSON.message) {
                errorMsg = xhr.responseJSON.message;
              }
            }

            that.$notify(errorMsg, 'error');
          },
          complete: function() {
            that.loading = false;
          }
        });
      }
    }
  });
})();
