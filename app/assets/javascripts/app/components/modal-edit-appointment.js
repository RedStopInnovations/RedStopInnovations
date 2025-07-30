(function() {
  'use strict';

  Vue.component('modal-edit-appointment', {
    template: '#modal-edit-appointment-tmpl',
    mixins: [modalAppointment, bootstrapModal],
    data: function() {
      return {
        patientOptions: [],
        isSearchingPatients: false,
        originalAppointment: null,
        availabilityOptions: [],
        selectedAvailability: null,
        selectedPractitioner: null,
        selectedAppointmentType: null,
        selectedPatient: null,
        selectedCase: null,
        allPatientCases: [],
        selectedAppointmentSlot: null,
        appointmentSlots: [],
        appointmentTypeOptions: [],
        appointmentData: {
          appointment_type_id: null,
          notes: null,
          start_time: null,
          end_time: null,
          availability_id: null,
          patient_id: null,
          skip_service_area_restriction: false
        },
        formErrors: [],
        availabilityDate: null,
        isSearchingAvailability: false,
        show: false,
        loading: false,
        availabilityDatePickerConfig: {
          altFormat: 'd M Y',
          altInput: true,
          dateFormat: 'Y-m-d',
        }
      };
    },
    mounted: function() {
      var self = this;
      CalendarEventBus.$on('appointment-edit', function(appointment) {
        self.setAppointment(appointment);
        self.show = true;
      });
    },

    computed: {
      isGroupAppointment: function() {
        return this.originalAppointment && this.originalAppointment.appointment_type.availability_type_id == App.GROUP_APPOINTMENT_TYPE_ID;
      }
    },

    methods: {
      showWithAvailability: function() {
        this.show = true;
      },
      buildOriginalAppointmentSlot: function() {
        if (this.originalAppointment != null) {
          var originalStartTime = moment.parseZone(this.originalAppointment.start_time);
          var originalEndTime = moment.parseZone(this.originalAppointment.end_time);
          var originalSlot = {
            id: originalStartTime.unix() + '-' + originalEndTime.unix(),
            label: originalStartTime.format('hh:mma') + ' - ' + originalEndTime.format('hh:mma'),
            start_time: originalStartTime.format('hh:mma'),
            end_time: originalEndTime.format('hh:mma')
          };
          return originalSlot;
        }
      },
      setAppointment: function(appointment) {
        var that = this;

        $.ajax({
          method: 'GET',
          url: '/api/appointments/' + appointment.id,
          beforeSend: function() {
            that.loading = true;
          },
          success: function(res) {
            var appointment = res.appointment;
            if (appointment) {
              that.originalAppointment = appointment;
              that.appointmentData.notes = appointment.notes;
              that.appointmentData.break_times = appointment.break_times;
              that.appointmentData.availability_id = appointment.availability_id;
              that.appointmentData.practitioner_id = appointment.practitioner_id;
              that.appointmentData.appointment_type_id = appointment.appointment_type_id;
              that.appointmentData.patient_id = appointment.patient_id;
              that.appointmentData.patient_case_id = appointment.patient_case_id;
              that.appointmentData.start_time = moment.parseZone(appointment.start_time).format('hh:mma');
              that.appointmentData.end_time = moment.parseZone(appointment.end_time).format('hh:mma');
              that.selectedCase = null;

              for (var i = that.practitioners.length - 1; i >= 0; i--) {
                if (that.practitioners[i].id === appointment.practitioner_id) {
                  that.selectedPractitioner = that.practitioners[i];
                  break;
                }
              }

              that.selectedPatient = appointment.patient;
              that.loadPatientCases();

              for (var i = that.appointment_types.length - 1; i >= 0; i--) {
                if (that.appointment_types[i].id === appointment.appointment_type_id) {
                  that.selectedAppointmentType = that.appointment_types[i];
                  break;
                }
              }

              // Reload availability
              $.ajax({
                method: 'GET',
                url: '/api/availabilities/' + appointment.availability_id,
                success: function(res) {
                  that.selectedAvailability = res.availability;
                  that.availabilityDate = that.$options.filters.standardDate(res.availability.start_time);
                  that.selectedAppointmentSlot = that.buildOriginalAppointmentSlot();
                  that.updateAppointmentTypeOptions();
                },
                complete: function() {
                  that.loading = false;
                }
              });
            }
          },
          error: function() {
            that.loading = false;
          }
        });
      },

      customSelectedCaseLabel: function(kase) {
        let label = kase.case_number;

        label += ' (' + kase.status + ')';

        return label;
      },

      loadPatientCases: function() {
        const vm = this;

        $.ajax({
          method: 'GET',
          url: '/api/patients/' + vm.selectedPatient.id + '/patient_cases.json',
          success: function(res) {
            vm.allPatientCases = res.patient_cases;

            if (vm.originalAppointment.patient_case_id) {
              for (let i = 0; i < res.patient_cases.length; i++) {
                const kase = res.patient_cases[i];
                if (kase.id == vm.originalAppointment.patient_case_id) {
                  vm.selectedCase = kase;
                }
              }
            }
          }
        });
      },
      updateAppointmentTypeOptions: function() {
        var options = [];
        var selectedPractitionerId = null;
        if (this.selectedPractitioner) {
          selectedPractitionerId = this.selectedPractitioner.id;
        }
        for (var i = this.appointment_types.length - 1; i >= 0; i--) {
          // Appt type must same availability type and either not deleted or the current one
          var at = this.appointment_types[i];
          if ((at.availability_type_id == this.selectedAvailability.availability_type_id) &&
            (
              (this.selectedAppointmentType.id == at.id) || // Keep the current
              ((at.practitioner_ids.indexOf(selectedPractitionerId) !== -1) &&
              (at.deleted_at === null))
            )
            ) {
            options.push(this.appointment_types[i]);
          }
        }

        if (this.selectedAppointmentType &&
            this.selectedAppointmentType.availability_type_id != this.selectedAvailability.availability_type_id) {

          this.selectedAppointmentType = null;
          this.appointmentData.appointment_type_id = null;
        }
        this.appointmentTypeOptions = options;
        this.updateAppointmentSlots();
      },
      submitForm: function() {
        if (this.loading) {
          return;
        }
        var serviceAreaError = null;

        if (this.selectedAvailability && this.selectedAvailability.availability_type_id == 1) {
          var error = this.serviceAreaError();
          if (error) {
            if (!confirm(error + ' Do you still want to update the appointment?')) {
              return;
            } else {
              serviceAreaError = error;
            }
          }
        }

        var that = this;
        that.formErrors = [];

        if (serviceAreaError) {
          that.appointmentData.skip_service_area_restriction = true;
        }

        $.ajax({
          method: 'PUT',
          url: '/api/appointments/' + that.originalAppointment.id,
          data: {
            appointment: that.appointmentData
          },
          beforeSend: function() {
            that.loading = true;
          },
          success: function(res) {
            that.$emit('appointment-updated', res.appointment);
            that.$notify('The appointment has been updated successfully.');
            that.show = false;
          },
          error: function(xhr) {
            var errorMsg = 'An error has occurred. Sorry for the inconvenience.';

            if (xhr.responseJSON) {
              if (xhr.status === 422 && xhr.responseJSON.errors) {
                that.formErrors = xhr.responseJSON.errors;
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
      },
    }
  });
})();
