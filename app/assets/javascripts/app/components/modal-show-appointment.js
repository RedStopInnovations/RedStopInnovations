(function() {
  'use strict';

  Vue.component('modal-show-appointment', {
    template: '#modal-show-appointment-tmpl',
    mixins: [bootstrapModal],

    data: function () {
      return {
        appointment: null,
        show: false,
        loading: false
      };
    },

    mounted: function () {
      const vm = this;

      CalendarEventBus.$on('appointment-show', function (appointment) {
        vm.resetData();
        vm.fetchAndShow(appointment.id);
      });
    },

    methods: {
      close: function () {
        this.show = false;
      },

      onModalClosed: function () {
        this.show = false;
        this.resetData();
      },

      resetData: function() {
        this.appointment = null;
      },

      fetchAndShow: function(appointmentId) {
        const vm = this;

        $.ajax({
          method: 'GET',
          url: '/app/appointments/' + appointmentId + '.json',
          success: function (res) {
            if (res.appointment) {
              vm.appointment = res.appointment;
            } else {
              vm.$notify('Cannot load appointment info. An error has occured.', 'error');
            }
            vm.show = true;
          },
          error: function(xhr) {
            if (xhr.status == 403) {
              vm.$notify('You are not authorized to view this appointment.', 'error');
            } else if (xhr.status == 404) {
              vm.$notify('The appointment does not exist.', 'error');
            } else {
              vm.$notify('Cannot load appointment info. An error has occured', 'error');
            }
          },
          complete: function() {
            vm.show = true;
          }
        });
      }
    }
  });

})();