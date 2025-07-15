(function() {
  'use strict';

  Vue.component('appointments-list-agenda', {
    template: '#appointments-list-agenda-tmpl',
    props: {
      appointments: {
        type: Array,
        required: true
      },
      appearanceSettings: {
        type: Object
      }
    },
    computed: {
      arrivalTime: function() {
        if (this.appointment.arrival) {
          return this.$options.filters.hour(this.appointment.arrival.arrival_at);
        } else {
          return 'N/A';
        }
      }
    },
    methods: {
      showAppointmentNote: function(appointment) {
        CalendarEventBus.$emit('appointment-note-show', appointment);
      },
      findBackgroundColorForAppointment: function(appointment) {
        var color = null;
        if (this.appearanceSettings && this.appearanceSettings.appointment_type_colors) {
          var apptTypeSetting = this.appearanceSettings.appointment_type_colors.find(function(at) {
            return at.id == appointment.appointment_type_id;
          });

          if (apptTypeSetting) {
            color = apptTypeSetting.color;
          }
        }

        return color;
      }
    }
  });
})();
