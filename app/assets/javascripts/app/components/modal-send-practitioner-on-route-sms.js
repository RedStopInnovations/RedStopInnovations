(function() {
  Vue.component('modal-send-practitioner-on-route-sms', {
    template: '#modal-send-practitioner-on-route-sms-tmpl',

    mixins: [bootstrapModal],

    data: function() {
      return {
        show: false,
        loading: false,
        appointment: null,
        smsContent: null
      };
    },

    props: {
      business: {
        type: Object,
        required: true
      }
    },

    computed: {
      isPatientReminderNotEnabled: function() {
        if (this.appointment) {
          return !this.appointment.patient.reminder_enable;
        }

        return false;
      }
    },

    mounted: function () {
      var self = this;

      CalendarEventBus.$on('appointment-practitioner-on-route-sms', function (appointment) {
        self.appointment = appointment;
        self.show = true;
        self.buildContent();
      });
    },

    methods: {
      onModalClosed: function() {
        this.show = false;
      },

      close: function () {
        this.smsContent = null;
        this.show = false;
      },

      buildContent: function() {
        var self = this;
        self.loading = true;

        $.ajax({
          url: '/api/communications/build_content',
          method: 'POST',
          data: {
            template_id: 'practitioner_on_route_sms',
            template_params: {
              appointment_id: self.appointment.id
            }
          },
          success: function(res) {
            self.smsContent = res.content;
          },
          error: function(xhr) {
            if (xhr.responseJSON && xhr.responseJSON.message) {
              self.$notify(xhr.responseJSON.message, 'error');
            } else {
              self.$notify('An error has occurred. Failed to prepare content of the message', 'error');
            }
          },
          complete: function() {
            self.loading = false
          }
        });

      },

      submit: function() {
        var self = this;
        self.loading = true;

        $.ajax({
          url: '/api/communications/send_patient_message',
          method: 'POST',
          data: {
            patient_id: self.appointment.patient_id,
            content: self.smsContent,
            communication_category: 'practitioner_on_route',
            source_id: self.appointment.id,
            source_type: 'Appointment'
          },
          success: function(res) {
            self.$notify(res.message, 'success');
            setTimeout(function() {
              self.close();
            }, 1000);
          },
          error: function(xhr) {
            if (xhr.responseJSON && xhr.responseJSON.message) {
              self.$notify(xhr.responseJSON.message, 'error');
            } else {
              self.$notify('An error has occurred. Failed to send the message', 'error');
            }
          },
          complete: function() {
            self.loading = false;
          }
        });
      }
    }

  });
})();