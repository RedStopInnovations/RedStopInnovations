(function() {
  'use strict';

  Vue.component('modal-edit-availability', {
    template: '#modal-edit-availability-tmpl',
    mixins: [bootstrapModal],
    props: {
      business: {
        type: Object,
        required: true
      }
    },
    data: function() {
      return {
        show: false,
        availability: null,
        selectedContact: null,
        selectedGroupAppointmentType: null,
        isSearchingContacts: false,
        contactOptions: [],
        availabilityTypeOptions: [],
        editAvailabilityData: {
          start_time: null,
          end_time: null,
          service_radius: 10,
          max_appointment: 3,
          address1: null,
          address2: null,
          city: null,
          state: null,
          postcode: null,
          country: null,
          apply_to_future_repeats: false,
          availability_type_id: null,
          contact_id: null,
          name: null,
          description: null,
          availability_subtype_id: null,
          group_appointment_type_id: null
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
        formErrors: []
      };
    },
    watch: {
      show: function() {
        this.reset();
      }
    },

    created: function() {
      this.availabilityTypeOptions = [
        {
          id: App.HOME_VISIT_AVAILABILITY_TYPE_ID, // 1
          name: 'Home visit'
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

      this.updateGroupAppointmentTypeOptions();
    },

    computed: {
      hasAppointments: function() {
        return this.availability.appointments.length > 0;
      },
      currentPractitioner: function() {
        return this.availability.practitioner;
      },
      availabilitySubtypeOptions: function() {
        const vm = this;
        return vm.business.availability_subtypes.filter(function(ast) {
          return !ast.deleted_at || ast.id == vm.availability.availability_subtype_id;
        });
      }
    },
    methods: {
      onModalClosed: function() {
        this.show = false;
      },
      closeModal: function() {
        this.show = false;
      },
      showModal: function() {
        this.show = true;
      },
      setAvailability: function(availability) {
        this.availability = availability;

        if (availability.contact) {
          this.selectedContact = availability.contact;
        }

        this.selectedGroupAppointmentType = availability.group_appointment_type;

        this.updateGroupAppointmentTypeOptions();
      },
      reset: function() {
        this.editAvailabilityData = {
          start_time: moment.parseZone(this.availability.start_time).tz(App.timezone).format('YYYY-MM-DD HH:mm'),
          end_time: moment.parseZone(this.availability.end_time).tz(App.timezone).format('YYYY-MM-DD HH:mm'),
          service_radius: this.availability.service_radius,
          max_appointment: this.availability.max_appointment,
          address1: this.availability.address1,
          address2: this.availability.address2,
          city: this.availability.city,
          state: this.availability.state,
          postcode: this.availability.postcode,
          country: this.availability.country,
          allow_online_bookings: this.availability.allow_online_bookings,
          availability_type_id: this.availability.availability_type_id,
          contact_id: this.availability.contact_id,
          name: this.availability.name,
          description: this.availability.description,
          availability_subtype_id: this.availability.availability_subtype_id,
          group_appointment_type_id: this.availability.group_appointment_type_id
        };
        this.selectedContact = this.availability.contact;
        this.selectedGroupAppointmentType = this.availability.group_appointment_type;
        this.formErrors = [];
        this.updateGroupAppointmentTypeOptions();
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
          this.editAvailabilityData.contact_id = contact.id;
          // Fill address fields by contact's address
          var addressFields = ['address1', 'city', 'state', 'postcode', 'country'];
          for (var i = addressFields.length - 1; i >= 0; i--) {
            var fieldName = addressFields[i];
            if (contact[fieldName]) {
              this.editAvailabilityData[fieldName] = contact[fieldName];
            } else {
              this.editAvailabilityData[fieldName] = null;
            }
          }
        } else {
          this.editAvailabilityData.contact_id = null;
        }
      },

      onGroupAppointmentTypeChanged: function(appointmentType) {
        if (appointmentType) {
          this.editAvailabilityData.group_appointment_type_id = appointmentType.id;
        } else {
          this.editAvailabilityData.group_appointment_type_id = null;
        }
      },

      submitForm: function() {
        var that = this;
        $.ajax({
          url: '/api/availabilities/' + that.availability.id,
          method: 'PUT',
          data: {
            availability: that.editAvailabilityData
          },
          success: function(res) {
            that.show = false;
            that.$notify('The availability has been updated successfully.');
            that.$emit('availability-updated', res.availability);
          },
          error: function(xhr) {
            if (xhr.status == 422) {
              that.formErrors = xhr.responseJSON.errors;
            } else {
              that.$notify('An error has occurred. Sorry for the inconvenience.', 'error');
            }
          }
        });
      },
      changePractitioner: function() {
        this.$emit('availability-change-practitioner', this.availability);
      },

      updateGroupAppointmentTypeOptions: function() {
        var options = [];
        var selectedPractitionerId = null;

        if (this.availability) {
          selectedPractitionerId = this.availability.practitioner_id;
          var selectedAvailabilityTypeID = this.editAvailabilityData.availability_type_id;

          for (var i = 0, l = this.business.appointment_types.length; i < l; i++) {
            var at = this.business.appointment_types[i];
            if ((at.availability_type_id == selectedAvailabilityTypeID) &&
              (at.deleted_at == null) &&
              (at.practitioner_ids.indexOf(selectedPractitionerId) !== -1)) {

              options.push(at);
            }

          }
          this.groupAppointmentTypeOptions = options;
        } else {
          this.groupAppointmentTypeOptions = [];
        }
      },
    }
  });
})();
