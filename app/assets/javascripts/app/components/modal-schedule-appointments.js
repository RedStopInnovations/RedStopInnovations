(function() {
  'use strict';

  var SOURCE_TYPE_NONE = 'none';
  var SOURCE_TYPE_WAITLIST = 'waitlist';
  var SOURCE_TYPE_APPOINTMENT = 'appointment';
  var SOURCE_TYPE_AVAILABILITY = 'availability';
  var SOURCE_TYPE_REFERRAL = 'referral';
  var SOURCE_TYPE_PATIENT = 'patient';

  var DEFAULT_DAYS_AHEAD = 14;

  Vue.component('modal-schedule-appointments', {
    template: '#modal-schedule-appointments-tmpl',
    mixins: [bootstrapModal],
    props: {
      business: {
        type: Object,
        required: true
      }
    },
    data: function() {
      return {
        source: null,
        sourceType: null,
        show: false,
        loading: false,
        isSearchingPatients: false,
        selectedAvailabilityTypeId: App.HOME_VISIT_AVAILABILITY_TYPE_ID, // HomeVisit ID
        selectedPatient: null,
        selectedCase: null,
        allPatientCases: [],

        patientOptions: [],
        isShowAvailabilitySearch: true,
        formErrors: [],

        selectedPractitioner: null,
        selectedAppointmentType: null,
        selectedAvailabilities: [],
        selectedProfession: '',
        distance: 50,

        availabilities: [],
        availabilityStartDate: null,
        availabilityEndDate: null,
        appointmentTypeOptions: [],
        availabilityDatePickerConfig: {
          altInput: true,
          altFormat: 'd M Y',
          disableMobile: true,
          minDate: 'today'
        },
        appointmentNotes: null,
        availabilityPagination: {
          enable: false,
          total_entries: 0,
          page: 1,
          per_page: 5,
          paginator_options: {
            previousText: 'Prev',
            nextText: 'Next'
          }
        },
      };
    },
    mounted: function() {
      var self = this;
      // TODO: better to use single event with all possible options

      CalendarEventBus.$on('waitlist-schedule', function(waitListItem) {
        self.prepareForWaitList(waitListItem);
        self.launch();
      });

      CalendarEventBus.$on('patient-schedule', function(patient) {
        self.prepareForPatient(patient);
        self.launch();
      });

      CalendarEventBus.$on('appointment-add', function(options) {
        self.prepareNone();
        self.launch();
      });

      CalendarEventBus.$on('appointment-repeat', function(appointment) {
        self.prepareRepeat(appointment);
        self.launch();
      });

      CalendarEventBus.$on('patient-created', function(patient) {
        if (self.show) {
          self.selectedPatient = patient;
          self.onPatientChanged();
        }
      });

      CalendarEventBus.$on('availability-add-appointment', function(avail) {
        self.prepareForAvailability(avail);
        self.launch();
      });

      CalendarEventBus.$on('referral-schedule', function(referral) {
        self.prepareForReferral(referral);
        self.launch();
      });
    },
    watch: {
      selectedAvailabilityTypeId: function(newVal) {
        this.updateAppointmentTypeOptions();
      },
      show: function(newVal) {
        if (newVal) {
          // Autofocus client search
          this.$nextTick(function() {
            if (!this.selectedPatient) {
              $(this.$refs.patientSelect.$el).find('.multiselect__input').focus();
            }
          });
        }
      }
    },
    filters: {
      availabilityLastAppointmentEnd: function(avail) {
        var lastAppt = avail.appointments[avail.appointments.length - 1];
        if (lastAppt) {
          if (lastAppt.arrival && lastAppt.arrival.arrival_at) {
            return moment(lastAppt.arrival.arrival_at)
              .add(lastAppt.appointment_type.duration, 'minutes');
          }
        }
      },
      availabilityRemaining: function(avail) {
        var lastAppt = avail.appointments[avail.appointments.length - 1];
        var lastApptEnd = null;
        if (lastAppt) {
          if (lastAppt.arrival && lastAppt.arrival.arrival_at) {
            lastApptEnd = moment(lastAppt.arrival.arrival_at)
              .add(lastAppt.appointment_type.duration, 'minutes');
          }
        }

        if (lastApptEnd) {
          if (lastApptEnd.isSameOrAfter(moment(avail.end_time))) {
            return 0;
          } else {
            return moment(avail.end_time)
              .diff(lastApptEnd, 'minutes', true);
          }
        } else {
          return moment(avail.end_time)
            .diff(moment(avail.start_time), 'minutes', true);
        }
      },
      humanizeAvailabilityRemaining: function(minutes) {
        if (minutes > 0) {
          var h = 0, m = 0;

          if (minutes < 60) {
            m = minutes;
          } else {
            h = parseInt(minutes / 60);
            m = minutes % 60;
          }

          var humanizedStr = '';
          if (h > 0) {
            humanizedStr += h + 'h ';
          }

          if (m > 0) {
            humanizedStr += parseInt(m.toFixed()) + 'm';
          }
          return humanizedStr;
        } else {
          return 'Full';
        }
      }
    },
    computed: {
      isAppointmentTypeRequired: function() {
        return (this.selectedAvailabilityTypeId == 1) || (this.selectedAvailabilityTypeId == 4);
      },
      isFormValid: function() {
        let valid = this.selectedPatient && (this.selectedAvailabilities.length > 0);
        if (this.isAppointmentTypeRequired) {
          valid = valid && this.selectedAppointmentType;
        }
        return valid;
      },
      practitionerOptions: function() {
        var options = this.business.practitioners.slice(0);
        // Workaround as there is no selection for "Any"
        options.unshift({
          full_name: 'Any',
          id: 0
        });
        return options;
      },
      patientOpenCases: function() {
        const openCases = [];

        for (let i = 0, l = this.allPatientCases.length; i < l; i++) {
          let kase = this.allPatientCases[i];

          if (kase.status == 'Open' && !kase.archived_at) {
            openCases.push(kase);
          }
        }

        return openCases;
      }
    },
    methods: {
      onModalClosed: function() {
        this.show = false;
      },
      cancel: function() {
        this.show = false;
      },
      buildFormData: function() {
        var data = {
          availability_ids: [],
          notes: this.appointmentNotes
        };

        if (this.selectedPatient) {
          data.patient_id = this.selectedPatient.id;
        }

        if (this.selectedAppointmentType) {
          data.appointment_type_id = this.selectedAppointmentType.id;
        }

        // If adding group appointment, just set appointment type as availability's one
        if (this.selectedAvailabilityTypeId == App.GROUP_APPOINTMENT_TYPE_ID) {
          if (this.selectedAvailabilities.length > 0) {
            var selectedAvail = this.selectedAvailabilities[0];
            data.appointment_type_id = selectedAvail.group_appointment_type_id;
          }
        } else if (this.selectedAppointmentType) {
          data.appointment_type_id = this.selectedAppointmentType.id;
        }

        if (this.selectedCase) {
          data.patient_case_id = this.selectedCase.id;
        }

        for (var i = this.selectedAvailabilities.length - 1; i >= 0; i--) {
          data.availability_ids.push(this.selectedAvailabilities[i].id);
        }

        return data;
      },
      submitForm: function() {
        var self = this;

        $.ajax({
          method: 'POST',
          url: '/api/' + '/appointments/creates.json',
          data: this.buildFormData(),
          beforeSend: function() {
            self.loading = true;
            self.formErrors = [];
          },
          success: function(res) {
            var appt = res.appointments[0];
            CalendarEventBus.$emit('appointment-created', appt);

            if ((self.sourceType == SOURCE_TYPE_WAITLIST) &&
                (self.source.patient_id === self.selectedPatient.id)) {

              // Mark the wait list item as scheduled
              $.ajax({
                method: 'PUT',
                url: '/api/wait_lists/' + self.source.id + '/mark_scheduled',
                success: function(res) {
                  CalendarEventBus.$emit('waitlist-scheduled', self.source);
                }
              });
            }

            self.$notify('The appointment has been created successfully.');
            self.show = false;
          },
          error: function(xhr) {
            var errorMsg = 'An error has occurred. Sorry for the inconvenience.';

            if (xhr.responseJSON) {
              if (xhr.status === 422 && xhr.responseJSON.errors) {
                self.formErrors = xhr.responseJSON.errors;
              }

              if (xhr.responseJSON.message) {
                errorMsg = xhr.responseJSON.message;
              }
            }

            self.$notify(errorMsg, 'error');
          },
          complete: function() {
            self.loading = false;
          }
        });
      },
      distanceToPatient: function(avail, patient) {
        var distance = Geocoding.distanceBetween(
          [avail.latitude, avail.longitude],
          [patient.latitude, patient.longitude]
        );
        var klass = '';
        if (!isNaN(distance)) {
          if (distance <= avail.service_radius) {
            klass = 'text-success';
          } else {
            klass = 'text-danger';
          }
        }
        var rounded = this.$options.filters.round(distance, 1);
        return '<span class="' + klass +'">' + rounded + '<span>';
      },
      addNewPatient: function() {
        CalendarEventBus.$emit('patient-add');
      },
      selectAvailability: function(avail, event) {
        avail.isSelected = true;
        this.selectedAvailabilities.push(avail);
        this.$nextTick(function() {
          event.target.scrollIntoView();
        });

        this.updateAppointmentTypeOptions();
      },
      deselectAvailability: function(avail) {
        avail.isSelected = false;
        this.selectedAvailabilities.splice(this.selectedAvailabilities.indexOf(avail), 1);
        this.updateAppointmentTypeOptions();
      },
      updateAppointmentTypeOptions: function() {
        var newOptions = [];

        var selectedAvailabilityPractitionerIds = this.selectedAvailabilities.map(function(avail) {
          return avail.practitioner_id;
        });

        for (var i = 0, l = this.business.appointment_types.length; i < l; i++) {
          var at = this.business.appointment_types[i];
          // Match the selected availability type
          if ((at.deleted_at === null) && at.availability_type_id === this.selectedAvailabilityTypeId) {
            // Match the allocations to selected practitioners
            const isAllocatedPractitionerMatch = selectedAvailabilityPractitionerIds.some(function(selectedPractId) {
              return at.practitioner_ids.indexOf(selectedPractId) !== -1;
            });

            if ((selectedAvailabilityPractitionerIds.length === 0) || isAllocatedPractitionerMatch) {
              newOptions.push(at);
            }
          }
        }

        this.appointmentTypeOptions = newOptions;

        // Clear the selected appointment type if not match the new available options
        if (this.selectedAppointmentType) {
          const selectedAppointmentType = this.selectedAppointmentType;
          // Clear if allocated practitioners are not match
          const isContainedInNewOptions = newOptions.some(function(at) {
            return at.id === selectedAppointmentType.id;
          });

          if (!isContainedInNewOptions) {
            this.selectedAppointmentType = null;
          }
        }

      },
      viewAvailability: function(avail) {
        CalendarEventBus.$emit('availability-show', avail);
      },
      onSelectedProfessionChanged: function() {
        this.availabilityPagination.page = 1;
        this.loadAvailability();
      },
      onDistanceChanged: function() {
        this.loadAvailability();
      },
      onAvailabilityStartDateChanged: function(value) {
        if (moment(this.availabilityStartDate).isAfter(moment(this.availabilityEndDate))) {
          this.availabilityEndDate = this.availabilityStartDate;
        }
        this.availabilityPagination.page = 1;
        this.loadAvailability();
      },
      onAvailabilityEndDateChanged: function() {
        this.availabilityPagination.page = 1;
        this.loadAvailability();
      },
      onSelectedAvailabilityTypeIdChanged: function() {
        this.availabilityPagination.page = 1;
        this.selectedAvailabilities = [];
        this.isShowAvailabilitySearch = true;
        this.loadAvailability();
      },
      onAppointmentTypeChanged: function() {
      },
      onSelectedPractitionerChanged: function() {
        this.availabilityPagination.page = 1;
        if (this.selectedPractitioner.id == 0) {
          this.selectedPractitioner = null;
        }
        this.loadAvailability();
      },
      onSelectedCaseChanged: function(kase) {
        if (kase && kase.invoice_total && kase.invoice_total <= kase.issued_invoices_amount) {
          if (!(confirm('The selected case has already exceeded maximum budget. Are you sure you still want to select it?'))) {
            this.$nextTick(function() {
              this.selectedCase = null;
            });
          }
        }
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
        this.availabilityPagination.page = 1;
        this.selectedCase = null;

        if (this.selectedPatient) {
          if (this.selectedAvailabilityTypeId == App.HOME_VISIT_AVAILABILITY_TYPE_ID) {
            if (this.sourceType != SOURCE_TYPE_AVAILABILITY) {
              this.isShowAvailabilitySearch = true;
              this.loadAvailability();
            }
          } else {
            if (this.sourceType != SOURCE_TYPE_AVAILABILITY)  {
              this.selectedAvailabilities = [];
              this.isShowAvailabilitySearch = true;
            }
          }

          this.loadPatientCases();
        } else {
          this.allPatientCases = [];
        }

        if (this.isShowAvailabilitySearch) {
          this.loadAvailability();
        }
      },
      customSelectedCaseLabel: function(kase) {
        let label = kase.case_number;

        label += ' (' + kase.status + ')';

        return label;
      },

      onAvailabilityPageChanged: function(page) {
        this.availabilityPagination.page = page;
        this.loadAvailability();
      },
      showSearch: function() {
        this.isShowAvailabilitySearch = true;
        this.loadAvailability();
      },
      hideSearch: function() {
        this.isShowAvailabilitySearch = false;
      },
      setDateRange: function(range) {
        switch(range) {
          case 'today': {
            this.availabilityStartDate =
              this.availabilityEndDate =
              moment().format('YYYY-MM-DD');
            break;
          }
          case 'tomorrow': {
            this.availabilityStartDate =
              this.availabilityEndDate
              = moment().add(1, 'days').format('YYYY-MM-DD');
            break;
          }
          case 'next_2_days': {
            this.availabilityStartDate = moment().format('YYYY-MM-DD');
            this.availabilityEndDate = moment().add(2, 'days').format('YYYY-MM-DD');
            break;
          }
          case 'next_7_days': {
            this.availabilityStartDate = moment().format('YYYY-MM-DD');
            this.availabilityEndDate = moment().add(7, 'days').format('YYYY-MM-DD');
            break;
          }
          case 'next_14_days': {
            this.availabilityStartDate = moment().format('YYYY-MM-DD');
            this.availabilityEndDate = moment().add(14, 'days').format('YYYY-MM-DD');
            break;
          }
          case 'next_30_days': {
            this.availabilityStartDate = moment().format('YYYY-MM-DD');
            this.availabilityEndDate = moment().add(30, 'days').format('YYYY-MM-DD');
            break;
          }
        }
        this.loadAvailability();
      },
      buildAvailabilityQueryParams: function() {
        var query = {
          distance: this.distance,
          profession: this.selectedProfession,
          availability_type_id: this.selectedAvailabilityTypeId,
          page: this.availabilityPagination.page,
          per_page: this.availabilityPagination.per_page
        };

        if (this.selectedPatient) {
          query.patient_id = this.selectedPatient.id;
        }

        if (this.availabilityStartDate) {
          query.start_date = this.availabilityStartDate;
        }

        if (this.availabilityEndDate) {
          query.end_date = this.availabilityEndDate;
        }

        if (this.selectedPractitioner) {
          query.practitioner_id = this.selectedPractitioner.id;
        }

        return query;
      },

      loadPatientCases: function() {
        const vm = this;

        $.ajax({
          method: 'GET',
          url: '/api/patients/' + vm.selectedPatient.id + '/patient_cases.json',
          success: function(res) {
            vm.allPatientCases = res.patient_cases;
          }
        });
      },

      loadAvailability: debounce(function() {
        var self = this;
        self.loading = true;

        $.ajax({
          url: '/api/search_appointment.json',
          data: self.buildAvailabilityQueryParams(),
          success: function(res) {
            var availabilities = res.availabilities;
            var selectedAvailIds = [];

            for (var ii = self.selectedAvailabilities.length - 1; ii >= 0; ii--) {
              selectedAvailIds.push(self.selectedAvailabilities[ii].id);
            }

            var avails = [];
            for (var ia = 0; ia < availabilities.length; ia++) {
              var avail = availabilities[ia];

              avail.isSelected = selectedAvailIds.indexOf(avail.id) != -1;
              avails.push(avail);
            }

            self.availabilities = avails;
            self.availabilityPagination.total_entries = res.pagination.total_entries;
          },
          error: function() {
            self.$notify('An error has occurred when searching for availability', 'error');
          },
          complete: function() {
            self.loading = false;
          }
        });
      }, 150),

      prepareForReferral: function(referral) {
        this.sourceType = SOURCE_TYPE_REFERRAL
        this.source = referral;

        if (referral.patient) {
          this.selectedPatient = referral.patient;
        }

        if (referral.availability_type_id) {
          this.selectedAvailabilityTypeId = referral.availability_type_id;
        }

        if (referral.practitioner) {
          this.selectedPractitioner = referral.practitioner;
        }
        if (referral.professions) {
          this.selectedProfession = referral.professions[0];
        } else {
          this.selectedProfession = '';
        }

        this.isShowAvailabilitySearch = true;
        this.availabilityStartDate = moment().format('YYYY-MM-DD');
        this.availabilityEndDate = moment().add(DEFAULT_DAYS_AHEAD, 'days').format('YYYY-MM-DD');
        this.appointmentNotes = null;
        this.selectedAvailabilities = [];
        this.selectedCase = null;
        this.allPatientCases = [];
        this.loadPatientCases();
      },

      prepareForPatient: function(patient) {
        this.sourceType = SOURCE_TYPE_PATIENT;
        this.source = patient;
        this.selectedPatient = patient;
        this.selectedProfession = '';
        this.isShowAvailabilitySearch = true;
        this.availabilityStartDate = moment().format('YYYY-MM-DD');
        this.availabilityEndDate = moment().add(DEFAULT_DAYS_AHEAD, 'days').format('YYYY-MM-DD');
        this.selectedAvailabilityTypeId = App.HOME_VISIT_AVAILABILITY_TYPE_ID;
        this.selectedAppointmentType = null;
        this.appointmentNotes = null;
        this.selectedAvailabilities = [];
        this.selectedCase = null;
        this.allPatientCases = [];
        this.loadPatientCases();
      },

      prepareForWaitList: function(waitListItem) {
        this.sourceType = SOURCE_TYPE_WAITLIST;
        this.source = waitListItem;

        this.selectedPatient = waitListItem.patient;

        if (waitListItem.profession) {
          this.selectedProfession = waitListItem.profession;
        } else {
          this.selectedProfession = '';
        }

        if (waitListItem.date) {
          // Check if start date is in the past
          if (moment(waitListItem.date).isSameOrAfter(moment())) {
            this.availabilityStartDate = waitListItem.date;
          } else {
            this.availabilityStartDate = moment().format('YYYY-MM-DD');
          }
        } else {
          this.availabilityStartDate = moment().format('YYYY-MM-DD');
        }
        this.availabilityEndDate = moment(this.availabilityStartDate).add(DEFAULT_DAYS_AHEAD, 'days').format('YYYY-MM-DD');

        if (waitListItem.appointment_type) {
          this.selectedAvailabilityTypeId = waitListItem.appointment_type.availability_type_id;
          this.selectedAppointmentType = waitListItem.appointment_type;
        } else {
          this.selectedAvailabilityTypeId = App.HOME_VISIT_AVAILABILITY_TYPE_ID;
          this.selectedAppointmentType = null;
        }

        if (waitListItem.practitioner) {
          this.selectedPractitioner = waitListItem.practitioner;
        } else {
          this.selectedPractitioner = null;
        }
        this.appointmentNotes = waitListItem.notes;
        this.selectedAvailabilities = [];

        this.selectedCase = null;
        this.allPatientCases = [];
        this.loadPatientCases();
      },
      prepareRepeat: function(appointment) {
        this.sourceType = SOURCE_TYPE_APPOINTMENT
        this.source = appointment;
        this.selectedPatient = appointment.patient;
        this.selectedAvailabilityTypeId = appointment.appointment_type.availability_type_id;
        this.selectedPractitioner = appointment.practitioner;
        this.selectedProfession = '';
        this.isShowAvailabilitySearch = true;
        this.availabilityStartDate = moment().format('YYYY-MM-DD');
        this.availabilityEndDate = moment().add(DEFAULT_DAYS_AHEAD, 'days').format('YYYY-MM-DD');
        this.appointmentNotes = null;
        this.selectedAvailabilities = [];

        this.selectedCase = null;
        this.allPatientCases = [];
        this.loadPatientCases();
      },
      prepareNone: function() {
        this.sourceType = null;
        this.source = null;
        this.selectedPatient = null;
        this.selectedAvailabilityTypeId = App.HOME_VISIT_AVAILABILITY_TYPE_ID;
        this.selectedPractitioner = null;
        this.selectedProfession = '';
        this.isShowAvailabilitySearch = false;
        this.availabilityStartDate = moment().format('YYYY-MM-DD');
        this.availabilityEndDate = moment().add(DEFAULT_DAYS_AHEAD, 'days').format('YYYY-MM-DD');
        this.appointmentNotes = null;

        this.selectedCase = null;
        this.allPatientCases = [];
        this.selectedAvailabilities = [];
      },
      prepareForAvailability: function(avail) {
        this.sourceType = SOURCE_TYPE_AVAILABILITY;
        this.source = avail;
        this.selectedPatient = null;
        this.selectedAvailabilityTypeId = avail.availability_type_id;
        this.selectedPractitioner = avail.practitioner;
        this.selectedAvailabilities = [avail];
        this.selectedProfession = '';
        this.isShowAvailabilitySearch = false;
        this.appointmentNotes = null;
        this.selectedCase = null;
        this.allPatientCases = [];
        var availStartTime = moment(avail.start_time);
        if (availStartTime.isSameOrAfter(moment())) {
          this.availabilityStartDate = availStartTime.format('YYYY-MM-DD');
          this.availabilityEndDate = availStartTime.add(DEFAULT_DAYS_AHEAD, 'days').format('YYYY-MM-DD');
        } else {
          this.availabilityStartDate = moment().format('YYYY-MM-DD');
          this.availabilityEndDate = moment().add(DEFAULT_DAYS_AHEAD, 'days').format('YYYY-MM-DD');
        }
      },
      launch: function() {
        this.patientOptions = [];
        this.availabilityPagination.page = 1;
        this.updateAppointmentTypeOptions();
        this.show = true;
        this.loadAvailability();
      }
    }
  });
})();
