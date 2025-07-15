(function() {
  Vue.component('modal-send-availability-arrival-time', {
    template: '#modal-send-availability-arrival-time-tmpl',
    mixins: [bootstrapModal],
    data: function() {
      return {
        show: false,
        loading: false,
        availability: null,
        sendOption: 'FORCE_ALL'
      }
    },

    mounted: function() {
      var self = this;

      CalendarEventBus.$on('availability-send-arrival-time', function(availability) {
        self.refreshAndShow(availability);
      });
    },

    computed: {
      hasPatientReminderNotEnabledOrNoMobile: function() {
        if (this.availability) {
          for (let i = 0; i < this.availability.appointments.length; i++) {
            const appt = this.availability.appointments[i];
            if (!appt.patient.mobile_formated || !appt.patient.reminder_enable) {
              return true;
            }
          }
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
        this.availability = null;
      },

      refreshAndShow: function(availability) {
        this.availability = availability;
        this.sendOption = 'FORCE_ALL';
        this.show = true;
      },

      onClickSend: function() {
        const vm = this;
        vm.loading = true;

        $.ajax({
          method: 'POST',
          url: '/api/availabilities/' + vm.availability.id + '/send_arrival_times',
          dataType: 'json',
          contentType: 'application/json',
          data: JSON.stringify({send_option: vm.sendOption}),
          success: function (res) {
            vm.$notify("The arrival times has been sent", 'success');
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