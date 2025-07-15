(function() {
  Vue.component('modal-create-wait-list', {
    template: '#modal-create-wait-list-tmpl',
    mixins: [bootstrapModal],
    data: function() {
      return {
        show: false,
        loading: false,
        selectedPatient: null,
        selectedAppointmentType: null,
        patientOptions: [],
        isSearchingPatients: false,
        formErrors: [],
        waitListData: this.defaultWaitListData(),
        waitListEntryDatePickerConfig: {
          altFormat: 'd M Y',
          altInput: true,
          dateFormat: 'Y-m-d',
          minDate: 'today',
          allowInput: true,
          disableMobile: true
        }
      };
    },
    props: {
      business: {
        type: Object,
        required: true
      }
    },
    computed: {
      practitioners: function() {
        return this.business.practitioners;
      },
      appointmentTypeOptions: function() {
        var ats = this.business.appointment_types.slice(0);

        ats.unshift({
          name: 'Any',
          id: 0
        });

        return ats;
      }
    },
    mounted: function() {
      var self = this;
      CalendarEventBus.$on('patient-created', function(patient) {
        if (self.show) {
          self.selectedPatient = patient;
          self.onPatientChanged(patient);
        }
      });
    },
    methods: {
      defaultWaitListData: function() {
        return {
          patient_id: null,
          practitioner_id: '',
          date: null,
          profession: '',
          appointment_type_id: '',
          repeat_type: '',
          repeat_frequency: 1,
          repeats_total: null,
          notes: null
        };
      },
      onModalClosed: function() {
        this.show = false;
      },
      showModal: function() {
        this.show = true;
      },
      showModalWithPatient: function(patientId, extraOptions) {
        this.show = true;
        var self = this;
        $.ajax({
          method: 'GET',
          url: '/api/patients/' + patientId + '.json',
          contentType: 'application/json',
          beforeSend: function() {
            self.loading = true;
          },
          success: function(res) {
            self.selectedPatient = res.patient;
            self.waitListData.patient_id = res.patient.id;

            if (extraOptions) {
              if (extraOptions.profession) {
                self.waitListData.profession = extraOptions.profession;
              }

              if (extraOptions.practitionerId) {
                self.waitListData.practitioner_id = extraOptions.practitionerId;
              }
            }
          },
          complete: function() {
            self.loading = false;
          }
        });
      },
      addPatient: function() {
        CalendarEventBus.$emit('patient-add');
      },
      close: function() {
        this.show = false;
        this.reset();
      },
      reset: function() {
        this.waitListData = this.defaultWaitListData();
        this.selectedPatient = null;
        this.selectedAppointmentType = null;
      },
      cancel: function() {
        this.show = false;
        this.reset();
      },
      onSearchPatientChanged: debounce(function(query) {
        var that = this;

        if (query.trim().length > 0) {
          that.isSearchingPatients = true;
          $.ajax({
            method: 'GET',
            url: '/api/patients/search?s=' + query,
            success: function(res) {
              that.patientOptions = res.patients;
            },
            complete: function() {
              that.isSearchingPatients = false;
            }
          });
        }
      }, 300),
      onPatientChanged: function(patient) {
        if (patient == null) {
          this.waitListData.patient_id = null;
        } else {
          this.waitListData.patient_id = patient.id;
        }
      },
      onAppointmentTypeChanged: function(at) {
        if (at && at.id === 0) {
          this.selectedAppointmentType = null;
          this.waitListData.appointment_type_id = null;
        } else if (at) {
          this.waitListData.appointment_type_id = at.id;
        }
      },
      buildFormData: function() {
        var sanitizedWaitListData = {};
        for (var prop in this.waitListData) {
          if (!!this.waitListData[prop]) {
            sanitizedWaitListData[prop] = this.waitListData[prop];
          } else {
            sanitizedWaitListData[prop] = null;
          }
        }
        return {
          wait_list: sanitizedWaitListData
        };
      },
      submitForm: function() {
        if (this.loading) {
          return;
        }
        var that = this;
        $.ajax({
          url: '/api/wait_lists',
          method: 'POST',
          dataType: 'json',
          data: that.buildFormData(),
          beforeSend: function() {
            that.loading = true;
            that.formErrors = [];
          },
          success: function(res) {
            that.$emit('wait-list-created', res.wait_list);
            that.$notify('The client has been added to waiting list.');
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
              } else {
                errorMsg = 'Failed to add to waiting list. Please check for form errors.'
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
