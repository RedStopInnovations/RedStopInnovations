(function() {
  'use strict';

  Vue.component('availability-listview', {
    template: '#availability-listview-tmpl',
    props: {
      business: {
        type: Object,
        required: true
      },
      availability: {
        type: Object,
        required: true
      },
      appearanceSettings: {
        type: Object
      }
    },
    computed: {
      appointments: function() {
        return this.availability.appointments;
      },
      availabilityTypeColor: function() {
        var vm = this;
        if (this.appearanceSettings && this.appearanceSettings.availability_type_colors) {
          var atColor = this.appearanceSettings.availability_type_colors.find(function(atColorSetting) {
            return atColorSetting.id == vm.availability.availability_type_id;
          });

          if (atColor) {
            return atColor.color;
          }
        }

        return null;
      },
      estimatedNextAppointmentTime: function() {
        if (this.availability.appointments.length > 0) {
          if (this.availability.last_appointment_end) {
            return this.availability.last_appointment_end.clone().add(15, 'minutes');
          } else {
            return this.availability.start_time;
          }
        } else {
          return this.availability.start_time;
        }
      }
    },
    methods: {
      onClickHeading: function() {
        CalendarEventBus.$emit('availability-show', this.availability);
      }
    }
  });
})();
