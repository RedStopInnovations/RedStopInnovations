(function() {
  'use strict';

  Vue.component('modal-delete-availability', {
    template: '#modal-delete-availability-tmpl',
    mixins: [bootstrapModal],
    data: function() {
      return {
        show: false,
        availability: null,
        deletion: {
          delete_future_repeats: false,
          notify_cancel_appointment: true
        }
      }
    },
    methods: {
      setAvailability: function(availability) {
        this.availability = availability;
      },
      onModalClosed: function() {
        this.show = false;
        this.$emit('availability-delete-cancelled', this.availability);
      },
      showModal: function() {
        this.show = true;
      },
      cancel: function() {
        this.show = false;
        this.$emit('availability-delete-cancelled', this.availability);
      },
      confirm: function() {
        const vm = this;

        $.ajax({
          method: 'DELETE',
          url: '/api/availabilities/' + vm.availability.id,
          data: vm.deletion,
          success: function(res) {
            vm.show = false;
            vm.$emit('availability-deleted', vm.availability);
            vm.$notify('The availability has been deleted successfully.');
          },
          error: function(xhr) {
            let errorMsg = null;

            if (xhr.responseJSON && xhr.responseJSON.message) {
              errorMsg = xhr.responseJSON.message;
            }

            if (xhr.status === 422 && xhr.responseJSON.errors) {
              errorMsg = 'Validation errors: ' + xhr.responseJSON.errors[0];
            }

            if (!errorMsg) {
              errorMsg = 'An error has occurred. Sorry for the inconvenience.';
            }

            vm.$notify(errorMsg, 'error');
          }
        });
      }
    }
  });
})();
