(function() {
  Vue.component('modal-edit-wait-list', {
    template: '#modal-edit-wait-list-tmpl',
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
        waitListData: {
          patient_id: null,
          practitioner_id: '',
          date: null,
          profession: '',
          apply_to_repeats: false,
          appointment_type_id: '',
          notes: null
        },
        currentWaitList: null,
        waitListEntryDatePickerConfig: {
          altFormat: 'd M Y',
          altInput: true,
          dateFormat: 'Y-m-d',
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
    methods: {
      onModalClosed: function() {
        this.show = false;
      },
      showModalWith: function(waitList) {
        this.currentWaitList = waitList;
        if (waitList) {
          this.waitListData.date = waitList.date;
          this.waitListData.patient_id = waitList.patient_id;
          this.waitListData.notes = waitList.notes;

          // Set values to blank string to set selected state for 'Any'
          if (waitList.practitioner_id) {
            this.waitListData.practitioner_id = waitList.practitioner_id;
          } else {
            this.waitListData.practitioner_id = '';
          }

          if (waitList.profession) {
            this.waitListData.profession = waitList.profession;
          } else {
            this.waitListData.profession = '';
          }

          if (waitList.appointment_type) {
            this.selectedAppointmentType = waitList.appointment_type;
          }
          if (waitList.appointment_type_id) {
            this.waitListData.appointment_type_id = waitList.appointment_type_id;
          } else {
            this.waitListData.appointment_type_id = '';
          }

          this.selectedPatient = waitList.patient;
        }

        this.show = true;
      },
      close: function() {
        this.show = false;
        this.reset();
      },
      reset: function() {
        this.waitListData = {
          patient_id: null,
          practitioner_id: '',
          date: null,
          profession: '',
          appointment_type_id: '',
          notes: null
        };
        this.selectedPatient = null;
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
          url: '/api/wait_lists/' + that.currentWaitList.id,
          method: 'PUT',
          dataType: 'json',
          data: that.buildFormData(),
          beforeSend: function() {
            that.loading = true;
            that.formErrors = [];
          },
          success: function(res) {
            that.$emit('wait-list-updated', res.wait_list);
            that.$notify('The waiting list been successfully updated.');
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
