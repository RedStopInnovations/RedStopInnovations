(function() {
  'use strict';

  Vue.component('modal-create-availability', {
    template: '#modal-create-availability-tmpl',
    mixins: [bootstrapModal],
    data: function() {
      return {
        selectedContact: null,
        selectedPractitioner: null,
        isSearchingContacts: false,
        contactOptions: [],
        appointmentTypeOptions: [],
        availabilityTypeOptions: [],
        availabilityData: {
          practitioner_id: null,
          start_time: null,
          end_time: null,
          service_radius: 10,
          max_appointment: 4,
          availability_type_id: App.HOME_VISIT_AVAILABILITY_TYPE_ID,
          address1: null,
          address2: null,
          city: null,
          state: null,
          postcode: null,
          country: this.business.country,
          allow_online_bookings: true,
          contact_id: null,
          repeat_type: '',
          repeat_total: 2,
          repeat_interval: 1,
          name: null,
          description: null,
          availability_subtype_id: null
        },
        availabilityTimePickerConfig: {
          enableTime: true,
          firstDayOfWeek: 1,
          disableMobile: true,
          altFormat: 'd M Y h:iK',
          dateFormat: 'Y-m-d H:i',
          allowInput: false,
          altInput: true,
          defaultDate: null
        },
        formErrors: [],
        show: false,
        loading: false,
        patientOptions: [],
        isSearchingPatients: false,
        selectedPatient: null,
        selectedAppointmentType: null,
        selectedCase: null,
        allPatientCases: []
      };
    },
    props: {
      business: {
        type: Object,
        required: true
      },
      practitioners: {
        type: Array,
        default: []
      }
    },

    created: function() {
      this.availabilityTypeOptions = [
        {
          id: App.HOME_VISIT_AVAILABILITY_TYPE_ID, // 1
          name: 'Home visit'
        },
        {
          id: App.SINGLE_HOME_VISIT_AVAILABILITY_TYPE_ID, // 11
          name: 'Single home visit'
        },
        {
          id: App.FACILITY_AVAILABILITY_TYPE_ID, // 4
          name: 'Facility'
        },
        {
          id: App.NON_BILLABLE_AVAILABILITY_TYPE_ID, // 5
          name: 'Non-billable'
        },
        {
          id: App.GROUP_APPOINTMENT_TYPE_ID, // 6
          name: 'Group appointment'
        }
      ];
    },

    computed: {
      isRepeatable: function() {
        return [
          App.HOME_VISIT_AVAILABILITY_TYPE_ID,
          App.SINGLE_HOME_VISIT_AVAILABILITY_TYPE_ID,
          App.FACILITY_AVAILABILITY_TYPE_ID,
          App.NON_BILLABLE_AVAILABILITY_TYPE_ID,
        ].indexOf(this.availabilityData.availability_type_id) != -1;
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
      },
      availabilitySubtypeOptions: function() {
        return this.business.availability_subtypes.filter(function(ast) {
          return !ast.deleted_at;
        });
      }
    },
    methods: {
      onModalClosed: function() {
        this.show = false;
      },
      showModal: function() {
        this.show = true;
      },
      isActive: function() {
        return this.show;
      },
      onSearchContactChanged: debounce(function(query) {
        var that = this;

        if (query.trim().length > 0) {
          that.isSearchingContacts = true;
          $.ajax({
            method: 'GET',
            url: '/api/contacts/search?s=' + query,
            success: function(res) {
              that.contactOptions = [];
              that.contactOptions = res.contacts;
            },
            complete: function() {
              that.isSearchingContacts = false;
            }
          });
        }
      }, 300),
      onContactChanged: function(contact) {
        if (contact) {
          this.availabilityData.contact_id = contact.id;
          // Fill facility appointment's address by contact's address
          var addressFields = ['address1', 'city', 'state', 'postcode', 'country'];
          for (var i = addressFields.length - 1; i >= 0; i--) {
            var fieldName = addressFields[i];
            if (contact[fieldName]) {
              this.availabilityData[fieldName] = contact[fieldName];
            } else {
              this.availabilityData[fieldName] = null;
            }
          }
        } else {
          this.availabilityData.contact_id = null;
        }
      },
      addPatient: function() {
        this.$emit('patient-add');
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
      setPatient: function(patient) {
        this.selectedPatient = patient;
        if (this.availabilityData.availability_type_id == App.SINGLE_HOME_VISIT_AVAILABILITY_TYPE_ID) {
          this.onPatientChanged(patient);
        }
      },
      onPatientChanged: function(patient) {
        this.selectedCase = null;
        this.allPatientCases = [];

        if (patient) {
          this.availabilityData.address1 = patient.address1;
          this.availabilityData.address2 = patient.address2;
          this.availabilityData.city = patient.city;
          this.availabilityData.state = patient.state;
          this.availabilityData.postcode = patient.postcode;
          this.availabilityData.country = patient.country;
          this.loadPatientCases();
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

      onAvailabilityTypeChanged: function() {
        // Update default max appoinments bases on availability type
        switch(this.availabilityData.availability_type_id) {
          case App.HOME_VISIT_AVAILABILITY_TYPE_ID:
            this.availabilityData.max_appointment = 4;
            break;
          case App.FACILITY_AVAILABILITY_TYPE_ID:
            this.availabilityData.max_appointment = 5;
            break;
          case App.GROUP_APPOINTMENT_TYPE_ID:
            this.availabilityData.max_appointment = 20;
            break;
        }
        this.updateAppointmentTypeOptions();
      },

      updateAppointmentTypeOptions: function() {
        var options = [];
        var selectedPractitionerId = null;
        if (this.selectedPractitioner) {
          selectedPractitionerId = this.selectedPractitioner.id;
        }

        var selectedAvailabilityTypeID = this.availabilityData.availability_type_id;

        if (selectedAvailabilityTypeID == App.SINGLE_HOME_VISIT_AVAILABILITY_TYPE_ID) { // If single home visit, real value should be ID of home visit
          selectedAvailabilityTypeID = App.HOME_VISIT_AVAILABILITY_TYPE_ID;
        }

        for (var i = 0, l = this.business.appointment_types.length; i < l; i++) {
          var at = this.business.appointment_types[i];
          if ((at.availability_type_id == selectedAvailabilityTypeID) &&
            (at.deleted_at == null) &&
            (at.practitioner_ids.indexOf(selectedPractitionerId) !== -1)) {

            options.push(at);
          }

        }
        this.appointmentTypeOptions = options;
      },

      customSelectedCaseLabel: function(kase) {
        let label = kase.case_number;
        const apptsAllocation = kase.appointments_count + '/' + (kase.invoice_number ? kase.invoice_number : '--') + ' appointments';
        label += ' (' + kase.status + ')' + ' ' + '(Allocated ' + apptsAllocation + ')';

        return label;
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

      resetForm: function() {
        // Reset form data to default
        this.availabilityData = {
          practitioner_id: null,
          service_radius: 10,
          max_appointment: 4,
          address1: null,
          address2: null,
          city: null,
          state: null,
          postcode: null,
          country: this.business.country,
          allow_online_bookings: true,
          availability_type_id: App.HOME_VISIT_AVAILABILITY_TYPE_ID,
          contact_id: null,
          repeat_type: '',
          repeat_total: 2,
          repeat_interval: 1,
          patient_case_id: null,
          availability_subtype_id: null
        };
        this.selectedCase = null;
        this.selectedAppointmentType = null;
        this.selectedContact = null;
        this.formErrors = [];
      },
      onGooglePlaceSelected: function(place) {
        var address1 = null;
        var city = null;
        var state = null;
        var postcode = null;
        var country = null;
        for (var i = 0; i < place.address_components.length; i++) {
          var component = place.address_components[i];

          if (component.types.indexOf('subpremise') !== -1) {
            address1 = component.short_name + '/';
          }

          if (component.types.indexOf('street_number') !== -1) {
            if(address1) {
              address1 += component.short_name;
            }else {
              address1 = component.short_name;
            }
          }
          if (component.types.indexOf('route') !== -1) {
            address1 = [address1, component.short_name].join(' ').trim();
          }
          if (component.types.indexOf('postal_town') !== -1) {
            city = component.short_name;
          }
          if (component.types.indexOf('locality') !== -1) {
            city = component.short_name;
          }
          if (component.types.indexOf('administrative_area_level_1') !== -1) {
            state = component.short_name;
          }
          if (component.types.indexOf('postal_code') !== -1) {
            postcode = component.short_name;
          }
          if(component.types.indexOf('country') !== -1) {
            country = component.short_name;
          }
        }

        this.availabilityData.address1 = address1;
        this.availabilityData.city = city;
        this.availabilityData.state = state;
        this.availabilityData.postcode = postcode;
        this.availabilityData.country = country;
      },
      bindGoogleAutocomplete: function() {
        var that = this;
        var autocomplete = new google.maps.places.Autocomplete(
          this.$refs.inputAddress1, autocompleteDefaultOptions);

        autocomplete.addListener('place_changed', function() {
          that.onGooglePlaceSelected(autocomplete.getPlace());
        });
      },
      onChangePractitioner: function() {
        for (var i = this.practitioners.length - 1; i >= 0; i--) {
          var pract = this.practitioners[i];
          if (pract.id == this.availabilityData.practitioner_id) {
            this.selectedPractitioner = pract;
            this.availabilityData.address1 = pract.address1;
            this.availabilityData.city = pract.city;
            this.availabilityData.state = pract.state;
            this.availabilityData.postcode = pract.postcode;
            this.availabilityData.country = pract.country;
            if (!pract.allow_online_bookings) {
              this.availabilityData.allow_online_bookings = false;
            }
            this.selectedAppointmentType = null;
            this.updateAppointmentTypeOptions();
            break;
          }
        }
      },
      setAvailabilityTime: function(start, end) {
        this.availabilityData.start_time = start.format('YYYY-MM-DD HH:mm');
        this.availabilityData.end_time = end.format('YYYY-MM-DD HH:mm');
      },
      setPractitionerId: function(practitionerId) {
        this.availabilityData.practitioner_id = practitionerId;
        this.onChangePractitioner();
      },
      buildApiCreateAvailabilityUrl: function() {
        if (this.availabilityData.availability_type_id == App.SINGLE_HOME_VISIT_AVAILABILITY_TYPE_ID) {
          return '/api/availabilities/single_home_visit.json';
        } else if(this.availabilityData.availability_type_id == App.NON_BILLABLE_AVAILABILITY_TYPE_ID) {
          return '/api/availabilities/non_billable.json';
        } else if(this.availabilityData.availability_type_id == App.GROUP_APPOINTMENT_TYPE_ID) {
          return '/api/availabilities/group_appointment.json';
        } else {
          return '/api/availabilities.json';
        }
      },
      buildFormData: function() {
        var data = {};
        var self = this;
        var sharedAttrs = [
          'start_time',
          'end_time',
          'availability_type_id',
          'practitioner_id',
          'allow_online_bookings'
        ];

        var availTypeId = this.availabilityData.availability_type_id;

        for (var i in sharedAttrs) {
          data[sharedAttrs[i]] = this.availabilityData[sharedAttrs[i]];
        }

        var locationAttrs = [
          'address1', 'address2', 'city', 'state', 'postcode', 'country'
        ];

        if ([
          App.HOME_VISIT_AVAILABILITY_TYPE_ID,
          App.SINGLE_HOME_VISIT_AVAILABILITY_TYPE_ID,
          App.FACILITY_AVAILABILITY_TYPE_ID,
          App.NON_BILLABLE_AVAILABILITY_TYPE_ID,
          App.GROUP_APPOINTMENT_TYPE_ID,
        ].indexOf(availTypeId) != -1) {
          for (var i in locationAttrs) {
            data[locationAttrs[i]] = this.availabilityData[locationAttrs[i]];
          }
        }

        if (this.isRepeatable) {
          var repeatAttrs = [
            'repeat_type',
            'repeat_total',
            'repeat_interval',
          ];

          repeatAttrs.forEach(function (repeatAttr) {
            data[repeatAttr] = self.availabilityData[repeatAttr];
          });
        }

        if (availTypeId == App.SINGLE_HOME_VISIT_AVAILABILITY_TYPE_ID) {
          if (this.selectedPatient) {
            data.patient_id = this.selectedPatient.id;
          }
          if (this.selectedAppointmentType) {
            data.appointment_type_id = this.selectedAppointmentType.id;
          }
          if (this.selectedCase) {
            data.patient_case_id = this.selectedCase.id;
          }
        }

        if (availTypeId == App.HOME_VISIT_AVAILABILITY_TYPE_ID) {
          data.service_radius = this.availabilityData.service_radius;
          data.max_appointment = this.availabilityData.max_appointment;
        }

        if (availTypeId == App.FACILITY_AVAILABILITY_TYPE_ID) {
          data.max_appointment = this.availabilityData.max_appointment;
          if (this.selectedContact) {
            data.contact_id = this.selectedContact.id;
          }
        }

        if (availTypeId == App.NON_BILLABLE_AVAILABILITY_TYPE_ID) {
          data.name = this.availabilityData.name;
          data.description = this.availabilityData.description;
          data.availability_subtype_id = this.availabilityData.availability_subtype_id;
          if (this.selectedContact) {
            data.contact_id = this.selectedContact.id;
          }
        }

        if (availTypeId == App.GROUP_APPOINTMENT_TYPE_ID) {
          data.max_appointment = this.availabilityData.max_appointment;
          data.description = this.availabilityData.description;

          if (this.selectedAppointmentType) {
            data.appointment_type_id = this.selectedAppointmentType.id;
          }
          if (this.selectedContact) {
            data.contact_id = this.selectedContact.id;
          }
        }

        return data;
      },

      submitForm: function() {
        if (this.loading) {
          return;
        }

        var that = this;
        $.ajax({
          method: 'POST',
          url: that.buildApiCreateAvailabilityUrl(),
          data: {
            availability: that.buildFormData()
          },
          beforeSend: function() {
            that.loading = true;
          },
          success: function(res) {
            that.show = false;
            that.$emit('availability-created', res.availability);
            that.$notify('The availability has been created successfully.');
          },
          error: function(xhr) {
            if (xhr.status === 422) {
              that.formErrors = xhr.responseJSON.errors;
              that.$notify('Failed to created availability. Please check for form errors.', 'error');
            } else {
              that.$notify('An error has occurred. Sorry for the inconvenience.', 'error');
            }
          },
          complete: function() {
            that.loading = false;
          }
        });
      }
    }
  });
})();
