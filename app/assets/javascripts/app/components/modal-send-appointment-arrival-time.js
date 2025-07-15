(function() {
  Vue.component('modal-send-appointment-arrival-time', {
    template: '#modal-send-appointment-arrival-time-tmpl',
    mixins: [bootstrapModal],
    data: function() {
      return {
        show: false,
        loading: false,
        appointment: null
      }
    },

    mounted: function() {
      var self = this;

      CalendarEventBus.$on('appointment-send-arrival-time', function(appointment) {
        self.refreshAndShow(appointment);
      });
    },

    computed: {
      isPatientReminderNotEnabled: function() {
        if (this.appointment) {
          return !this.appointment.patient.reminder_enable;
        }

        return false;
      }
    },

    methods: {
      onModalClosed: function() {
        this.show = false;
      },

      close: function() {
        this.show = false;
        this.appointment = null;
      },

      refreshAndShow: function(appointment) {
        this.appointment = appointment;
        this.show = true;
      },

      onClickSend: function() {
        const vm = this;
        vm.loading = true;

        $.ajax({
          method: 'POST',
          url: '/api/appointments/' + vm.appointment.id + '/send_arrival_time',
          dataType: 'json',
          success: function (res) {
            vm.$notify("The arrival time has been sent", 'success');
            vm.close();
            vm.loading = false;
          },
          error: function (xhr) {
            vm.loading = false;
            if (xhr.responseJSON && xhr.responseJSON.message) {
              vm.$notify(xhr.responseJSON.message, 'error');
            } else {
              vm.$notify("An error has occurred. Please try again!", 'error');
            }
          }
        });
      }
    }

  });
})();