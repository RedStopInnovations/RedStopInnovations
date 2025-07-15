(function() {
  'use strict';

  Vue.component('modal-confirm-change-availability', {
    template: '#modal-confirm-change-availability-tmpl',
    mixins: [bootstrapModal],
    data: function() {
      return {
        show: false,
        availability: null,
        apply_to_future_repeats: false,
        changes: {
          start_time: moment(),
          end_time: moment(),
        },
        loading: false
      };
    },
    watch: {
      show: function() {
        this.apply_to_future_repeats = false;
      }
    },
    computed: {
      oldStartTime: function() {
        return this.availability.start_time;
      },
      oldEndTime: function() {
        return this.availability.end_time;
      },
      newStartTime: function() {
        return this.changes.start_time;
      },
      newEndTime: function() {
        return this.changes.end_time;
      }
    },
    methods: {
      setAvailability: function(availability) {
        this.availability = availability;
      },
      setAvailabilityChanges: function(availability, event) {
        this.availability = availability;
        this.changes.start_time = event.start;
        this.changes.end_time = event.end;
      },
      onModalClosed: function() {
        this.show = false;
        this.$emit('availability-time-change-cancelled', this.availability);
      },
      showModal: function() {
        this.show = true;
      },
      submit: function() {
        var that = this;
        if (this.loading) {
          return;
        }

        $.ajax({
          url: '/api/availabilities/' + that.availability.id + '/update_time',
          method: 'PUT',
          data: {
            availability: {
              start_time: that.changes.start_time.format('DD MMM YYYY hh:mma'),
              end_time: that.changes.end_time.format('DD MMM YYYY hh:mma'),
              apply_to_future_repeats: that.apply_to_future_repeats,
            }
          },
          beforeSend: function() {
            that.loading = true;
          },
          success: function(res) {
            that.show = false;
            that.$emit('availability-time-change-updated', res.availability);
            that.$notify('The availability has been updated successfully.');
          },
          error: function(xhr) {
            var errorMsg = 'An error has occurred. Sorry for the inconvenience.';
            if (xhr.responseJSON && xhr.responseJSON.message) {
              errorMsg = xhr.responseJSON.message;
            }
            that.$notify(errorMsg, 'error');
          },
          complete: function() {
            that.loading = false;
          }
        });
      },
      cancel: function() {
        this.show = false;
        this.$emit('availability-time-change-cancelled', this.availability);
      }
    }
  });
})();
