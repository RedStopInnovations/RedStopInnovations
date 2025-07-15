var modalAppointment = {
  props: {
    business: {
      type: Object,
      required: true
    },
    appointment_types: {
      type: Array,
      required: true
    },
    practitioners: {
      type: Array,
      required: true
    }
  },
  computed: {
    isFormValid: function() {
      return (this.selectedPatient != null)
             && (this.selectedPractitioner !== null)
             && (this.selectedAvailability !== null)
             && (this.selectedAppointmentType !== null);
    },
    distanceToSelectedPatient: function() {
      if (this.selectedPatient) {
        return this.calDistanceToPatient(this.selectedPatient);
      } else {
        return null;
      }
    },
    selectAvailabilityEnabled: function() {
      return (this.selectedPractitioner != null)
             && this.availabilityDate;
    },
  },
  methods: {
    onModalClosed: function() {
      this.show = false;
    },
    isActive: function() {
      return this.show;
    },
    showModal: function() {
      this.show = true;
    },
    cancel: function() {
      this.show = false;
    },
    hasEnoughAvailSearchParams: function() {
      return this.selectedPractitioner && this.availabilityDate;
    },
    setPatient: function(patient) {
      this.selectedPatient = patient;
      this.appointmentData.patient_id = patient.id;
      this.selectedCase = null;
    },
    onPractitionerChanged: function(practitioner) {
      this.appointmentData.practitioner_id = practitioner.id;
      if (this.hasEnoughAvailSearchParams()) {
        this.searchAvailability();
      }
    },
    onAppointmentTypeChanged: function(appointmentType) {
      this.appointmentData.appointment_type_id = appointmentType.id;
      this.updateAppointmentSlots();
    },
    onAvailabilityDateChanged: function() {
      if (this.hasEnoughAvailSearchParams()) {
        this.searchAvailability();
      }
    },
    onAvailabilityChanged: function(availability) {
      this.appointmentData.availability_id = availability.id;
      this.updateAppointmentTypeOptions();
    },
    onPatientChanged: function(patient) {
      this.selectedCase = null;

      if (patient == null) {
        this.appointmentData.patient_id = null;
      } else {
        this.appointmentData.patient_id = patient.id;
        this.loadPatientCases();
      }
    },
    onCaseChanged: function(kase) {
      this.selectedCase = kase;
      if (kase) {
        this.appointmentData.patient_case_id = kase.id;
      } else {
        this.appointmentData.patient_case_id = null;
      }
    },
    serviceAreaError: function() {
      var msg = null;
      if (this.selectedAvailability.availability_type_id == 1) { // Home visits
        var distance = this.distanceToSelectedPatient;
        if (distance === null) {
          msg = 'The client location is not recognizable!';
        } else if (distance > this.selectedAvailability.service_radius) {
          msg = 'The client location is out of service radius!';
        }
      }
      return msg;
    },
    calDistanceToPatient: function(patient) {
      if (patient.latitude && patient.longitude) {
        return Geocoding.distanceBetween(
          [this.selectedAvailability.latitude, this.selectedAvailability.longitude],
          [patient.latitude, patient.longitude]
        );
      } else {
        return null;
      }
    },
    buildAvailabilityQuery: function() {
      var query = {
        business_id: this.business.id,
        practitioner_id: this.selectedPractitioner.id,
        date: this.availabilityDate
      };

      if (this.originalAppointment) {
        query.availability_type_id = this.originalAppointment.appointment_type.availability_type_id;
      }

      return query;
    },
    onSearchPatientChanged: debounce(function(query) {
      var that = this;

      if (query.trim().length > 0) {
        that.isSearchingPatients = true;
        $.ajax({
          method: 'GET',
          url: '/api/patients/search?business_id=' + that.business.id + '&s=' + query,
          success: function(res) {
            that.patientOptions = res.patients;
          },
          complete: function() {
            that.isSearchingPatients = false;
          }
        });
      }
    }, 300),
    searchAvailability: function(onCompleted) {
      var that = this;
      if (that.isSearchingAvailability) {
        return;
      }

      $.ajax({
        method: 'GET',
        url: '/api/availabilities/search_by_date?' + $.param(that.buildAvailabilityQuery()),
        beforeSend: function() {
          that.isSearchingAvailability = true;
        },
        success: function(res) {
          that.availabilityOptions = res.availabilities;

          if (that.selectedAvailability) {
            // Clear the current selected availability if the new list not contains it
            var keepCurrentAvail = false;
            for (var i = res.availabilities.length - 1; i >= 0; i--) {
              if (that.selectedAvailability.id === res.availabilities[i].id) {
                keepCurrentAvail = true;
              }
            }

            if (!keepCurrentAvail) {
              that.selectedAvailability = null;
              that.appointmentData.availability_id = null;
            }

          }

          if (typeof (onCompleted) === 'function') {
            onCompleted();
          }
        },
        complete: function() {
          that.isSearchingAvailability = false;
        }
      });
    },
    availabilityDisplayLabel: function(availability) {
      return this.$options.filters.hour(availability.start_time)
             + ' - '
             + this.$options.filters.hour(availability.end_time)
    },
    updateAppointmentSlots: function() {
      var slots = [];

      if (this.originalAppointment) {
        // Always show original slot on top for editing mode
        slots.push(this.buildOriginalAppointmentSlot());
      }

      if (slots.length === 0) {
        this.selectedAppointmentSlot = null;
        this.appointmentData.start_time = null;
        this.appointmentData.end_time = null;
      }
      this.appointmentSlots = slots;
    },
    onAppointmentSlotChanged: function() {
      if (this.selectedAppointmentSlot) {
        this.appointmentData.start_time = this.selectedAppointmentSlot.start_time;
        this.appointmentData.end_time = this.selectedAppointmentSlot.end_time;
      } else {
        this.appointmentData.start_time = null;
        this.appointmentData.end_time = null;
      }
    }
  }
};
