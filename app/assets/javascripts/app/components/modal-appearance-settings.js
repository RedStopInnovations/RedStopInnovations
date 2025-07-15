(function() {
  'use strict';

  Vue.component('modal-calendar-appearance-settings', {
    template: '#modal-calendar-appearance-settings-tmpl',
    mixins: [bootstrapModal],
    data: function() {
      return {
        show: false,
        loading: false,
        settings: {
          appointment_type_colors: [],
          appointment_type_colors: [],
          is_show_tasks: false
        }
      }
    },

    props: {
      business: {
        type: Object,
        required: true
      }
    },

    mounted: function() {
      var self = this;
      CalendarEventBus.$on('calendar-appearance-settings.show', function() {
        self.showModal();
      });
    },

    computed: {
      allAppointmentTypes: function() {
        return this.business.appointment_types;
      },
      selectableAppointmentTypes: function() {
        var selectedIds = this.settings.appointment_type_colors.map(function(at) {
          return at.id
        });

        var ats = [];
        for (var i = 0, l = this.business.appointment_types.length; i < l; i++) {
          var at = this.business.appointment_types[i];
          if (selectedIds.indexOf(at.id) === -1) {
            ats.push(at);
          }
        }

        return ats;
      }
    },

    methods: {
      showModal: function() {
        this.show = true;
        this.loadSettings();
      },
      close: function() {
        this.show = false;
      },
      onModalClosed: function() {
        this.show = false;
      },

      availabilityTypeName: function(id) {
        return {
          [App.HOME_VISIT_AVAILABILITY_TYPE_ID]: 'Home visit',
          [App.FACILITY_AVAILABILITY_TYPE_ID]: 'Facility',
          [App.NON_BILLABLE_AVAILABILITY_TYPE_ID]: 'Non-billable',
          [App.GROUP_APPOINTMENT_TYPE_ID]: 'Group appointment'
        }[id]
      },

      appointmentTypeName: function(id) {
        var at = this.allAppointmentTypes.find(function(at) {
          return at.id == id;
        });

        if (at) {
          return at.name;
        }
      },

      onAppointmentTypeSelected: function(apptType, id) {
        this.settings.appointment_type_colors.unshift({
          id: apptType.id,
          // TODO: randomize a color ?
          color: ''
        });
      },

      onClickSetAvailabilityTypesToDefault: function() {
        this.settings.availability_type_colors = this.defaultSettings().availability_type_colors;
      },

      onClickRemoveAppointmentType: function(apptType) {
        if (confirm('Are you sure you want to remove this item?')) {
          this.settings.appointment_type_colors.splice(this.settings.appointment_type_colors.indexOf(apptType), 1);
        }
      },

      defaultSettings: function() {
        return {
          availability_type_colors: [
            {
              id: App.HOME_VISIT_AVAILABILITY_TYPE_ID,
              color: '#44b654',
            },
            {
              id: App.FACILITY_AVAILABILITY_TYPE_ID,
              color: '#3d88ad',
            },
            {
              id: App.NON_BILLABLE_AVAILABILITY_TYPE_ID,
              color: '#8d41c5',
            },
            {
              id: App.GROUP_APPOINTMENT_TYPE_ID,
              color: '#cddc39',
            }
          ],
          appointment_type_colors: [],
          is_show_tasks: false
        }
      },

      loadSettings: function() {
        var vm = this;
        vm.loading = true;

        $.ajax({
          method: 'GET',
          url: '/api/calendar/appearance_settings',
          success: function(res) {
            if (res.settings) {
              vm.settings = res.settings;
            }
          },
          error: function(xhr) {
            vm.$notify('Could not load appearance settings.', 'error');
          },
          complete: function() {
            vm.loading = false;
          }
        });
      },

      saveSettings: function() {
        var vm = this;
        vm.loading = true;

        $.ajax({
          method: 'PUT',
          url: '/api/calendar/appearance_settings',
          dataType: 'json',
          contentType: 'application/json',
          data: JSON.stringify(vm.settings),
          success: function(res) {
            CalendarEventBus.$emit('calendar-appearance-settings.updated', vm.settings);
            vm.$notify('Appearance settings updated.', 'success');
            vm.close();
          },
          error: function(xhr) {
            vm.$notify('Could not save appearance settings.', 'error');
          },
          complete: function() {
            vm.loading = false;
          }
        });
      }
    }
  });

})();
