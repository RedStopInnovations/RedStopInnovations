(function() {
  'use strict';

  Vue.component('modal-create-appointment', {
    template: '#modal-create-appointment-tmpl',
    mixins: [modalAppointment, bootstrapModal],
    data: function() {
      return {
        patientOptions: [],
        isSearchingPatients: false,
        availabilityOptions: [],
        selectedAvailability: null,
        selectedPractitioner: null,
        selectedAppointmentType: null,
        selectedPatient: null,
        selectedAppointmentSlot: null,
        appointmentSlots: [],
        appointmentTypeOptions: [],
        selectedCase: null,
        allPatientCases: [],
        appointmentData: {
          appointment_type_id: null,
          break_times: null,
          notes: null,
          start_time: null,
          end_time: null,
          availability_id: null,
          patient_id: null,
          skip_service_area_restriction: false,
          patient_case_id: null
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
    methods: {
      reset: function() {
        this.availabilityOptions = [],
        this.selectedAvailability = null;
        this.selectedPractitioner = null;
        this.selectedAppointmentType = null;
        this.selectedPatient = null;
        this.appointmentSlots = [];
        this.selectedAppointmentSlot = null;

        this.appointmentData = {
          appointment_type_id: null,
          notes: null,
          start_time: null,
          end_time: null,
          availability_id: null,
          skip_service_area_restriction: false,
          patient_case_id: null
        };

        this.formErrors = [];
        this.availabilityDate = '';
        this.isSearchingAvailability = false;
      },
      showModal: function(options) {
        if (options) {
          // Check options to prefill inputs
          if (options.practitioner_id) {
            for (var i = this.practitioners.length - 1; i >= 0; i--) {
              if (this.practitioners[i].id == options.practitioner_id) {
                this.selectedPractitioner = this.practitioners[i];
                break;
              }
            }
          }

          if (options.availability_date) {
            this.availabilityDate = options.availability_date;
          }
        }
        this.show = true;
        if (options && options.practitioner_id && options.availability_date) {
          this.searchAvailability();
        }
      },
      showWithAvailability: function(availability) {
        this.selectedPatient = null;
        this.selectedCase = null;
        this.selectedAppointmentType = null;
        this.selectedAvailability = availability;
        this.selectedPractitioner = availability.practitioner;
        this.availabilityDate = this.$options.filters.standardDate(availability.start_time);
        this.appointmentData.availability_id = availability.id;
        this.appointmentData.practitioner_id = availability.practitioner_id;
        this.selectedAppointmentSlot = null;
        this.formErrors = [];

        this.updateAppointmentTypeOptions();
        this.searchAvailability();

        this.show = true;
      },
      updateAppointmentTypeOptions: function() {
        var options = [];
        var selectedPractitionerId = null;
        if (this.selectedPractitioner) {
          selectedPractitionerId = this.selectedPractitioner.id;
        }
        // Filter app types by availability type
        for (var i = this.appointment_types.length - 1; i >= 0; i--) {
          var at = this.appointment_types[i];
          if ((at.availability_type_id == this.selectedAvailability.availability_type_id) && // Same availability type
              (at.deleted_at === null) && // Not deleted
              (at.practitioner_ids.indexOf(selectedPractitionerId) !== -1)) { // Provides by the selected practitioners
            options.push(at);
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
      addPatient: function() {
        this.$emit('patient-add');
      },
      submitForm: function() {
        if (this.loading) {
          return;
        }
        var serviceAreaError = null;
        var avail = this.selectedAvailability;
        if (avail && avail.availability_type_id == 1) {

          var error = this.serviceAreaError();
          if (error) {
            if (!confirm(error + '\nDo you still want to create the appointment?')) {
              return;
            } else {
              serviceAreaError = error;
            }
          }

          if (this.selectedAppointmentType) {
            // Check if appointments exceed allocated availability
            var allocatedMins = 0;
            var availMins = moment.parseZone(avail.end_time)
              .diff(moment.parseZone(avail.start_time), 'minutes');
            for (var i = avail.appointments.length - 1; i >= 0; i--) {
              allocatedMins += avail.appointments[i].appointment_type.duration;
            }
            if ((allocatedMins + this.selectedAppointmentType.duration) > availMins) {
              if (!confirm('This appointment might extended over the allocated availability!\nDo you still want to create?')) {
                return ;
              }
            }
          }
        }

        var that = this;
        that.formErrors = [];

        if (serviceAreaError) {
          that.appointmentData.skip_service_area_restriction = true;
        }

        $.ajax({
          method: 'POST',
          url: '/api/' + '/appointments.json',
          data: {
            appointment: that.appointmentData
          },
          beforeSend: function() {
            that.loading = true;
          },
          success: function(res) {
            that.$emit('appointment-created', res.appointment);
            that.$notify('The appointment has been created successfully.');
            that.reset();
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
      }
    }
  });
})();
