(function() {
  'use strict';

  Vue.component('modal-show-availability', {
    template: '#modal-availability-tmpl',
    mixins: [bootstrapModal],
    data: function () {
      return {
        availability: null,
        show: false,
        loading: false
      };
    },

    props: {
      business: {
        type: Object,
        required: true
      }
    },

    computed: {
      modalAvailabilityTypeAttribute: function() {
        if (this.availability) {
          return {
            [App.HOME_VISIT_AVAILABILITY_TYPE_ID] : 'home-visit',
            [App.FACILITY_AVAILABILITY_TYPE_ID] : 'facility-visit',
            [App.NON_BILLABLE_AVAILABILITY_TYPE_ID] : 'non-billable',
            [App.GROUP_APPOINTMENT_TYPE_ID] : 'group-appointment',
          }[this.availability.availability_type_id];
        }
      },

      isNonBillable: function() {
        return this.availability && this.availability.availability_type_id == App.NON_BILLABLE_AVAILABILITY_TYPE_ID;
      },

      appointmentsCount: function () {
        return this.availability.appointments.length;
      },

      isCanViewInvoice: function() {
        return App.user && (App.user.role != App.CONSTANTS.USER.ROLE_RESTRICTED_PRACTITIONER);
      },

      orderedAppointments: function() {
        if (this.availability.availability_type_id == App.GROUP_APPOINTMENT_TYPE_ID) {
          return this.availability.appointments.slice(0).sort(function(appt1, appt2) {
            const name1 = appt1.patient.full_name.toUpperCase();
            const name2 = appt2.patient.full_name.toUpperCase();

            if (name1 < name2) {
              return -1;
            }
            if (name1 > name2) {
              return 1;
            }

            return 0;
          });
        } else {
          return this.availability.appointments;
        }
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

    mounted: function () {
      var self = this;
      CalendarEventBus.$on('availabiliy-show', function (avail) {
        self.fetchAndShow(avail.id);
      });

      CalendarEventBus.$on('appointment-created', function (appointment) {
        self.fetchAndShow(appointment.availability_id);
      });
    },

    methods: {
      onChangingOrderStart: function (evt) {
        $('.table-appointments').addClass('dragging');
      },
      onChangingOrderEnd: function (evt) {
        $('.table-appointments').removeClass('dragging');
      },
      onModalClosed: function () {
        this.show = false;
      },
      showModal: function () {
        this.show = true;
      },
      fetchAndShow: function (id) {
        var that = this;
        that.availability = null;
        that.show = true;
        $.ajax({
          url: '/api/availabilities/' + id + '.json',
          beforeSend: function () {
            that.loading = true;
          },
          success: function (res) {
            that.setAvailability(res.availability);
          },
          error: function (xhr) {
            var errorMsg = 'An error has occurred. Sorry for the inconvenience.';
            if (xhr.responseJSON && xhr.responseJSON.message) {
              errorMsg = xhr.responseJSON.message;
            }
            that.$notify(errorMsg, 'error');
          },
          complete: function () {
            that.loading = false;
          }
        });
      },
      calculateStats: function (avail) {
        var totalApptTime = 0;    // Total appts duration in mins
        var totalTravelMins = 0;  // Total travel(driving) duration in mins

        for (var idx = 0, l = avail.appointments.length; idx < l; idx++) {
          var appt = avail.appointments[idx];
          var travelDuration = 0;
          var travelDistance = 0;

          if (appt.arrival && appt.arrival.arrival_at) {
            travelDistance = appt.arrival.travel_distance;
            travelDuration = appt.arrival.travel_duration;
          }

          appt.travel_duration = travelDuration / 60;
          appt.travel_distance = travelDistance;

          totalTravelMins += (travelDuration / 60);
          totalApptTime += appt.appointment_type.duration;
        }
        avail.total_appt_time = totalApptTime;
        avail.driving_time = totalTravelMins;

        var lastAppt = avail.appointments[avail.appointments.length - 1];

        // Calculate the remaining time of the availability
        if (lastAppt) {
          if (lastAppt.arrival && lastAppt.arrival.arrival_at) {
            avail.last_appointment_end = moment(lastAppt.arrival.arrival_at)
              .add(lastAppt.appointment_type.duration, 'minutes');

            if (avail.last_appointment_end.isSameOrAfter(moment(avail.end_time))) {
              avail.remaining = 0;
            } else {
              avail.remaining = moment(avail.end_time)
                .diff(avail.last_appointment_end, 'minutes', true);
            }
          }
        } else {
          avail.remaining = moment(avail.end_time)
            .diff(moment(avail.start_time), 'minutes', true);
        }
        return avail;
      },
      setAvailability: function (avail) {
        if (avail.availability_type_id == 1 || avail.availability_type_id == 4) { // Home visit
          avail = this.calculateStats(avail);
        }
        this.availability = avail;
      },
      onOrderUpdate: function () {
        var idsInNewOrder = [];
        var that = this;

        for (var i = 0; i < this.availability.appointments.length; i++) {
          idsInNewOrder.push(this.availability.appointments[i].id);
        }
        $.ajax({
          method: 'PUT',
          url: '/api/availabilities/' + that.availability.id + '/update_appointments_order',
          data: { appointment_ids: idsInNewOrder },
          beforeSend: function () {
            that.loading = true;
          },
          success: function (res) {
            that.fetchAndShow(that.availability.id);
            that.$notify('Appointments order has been updated.', 'success');
            CalendarEventBus.$emit('availability-appointments-order-updated', that.availability);
          },
          error: function (xhr) {
            var errorMsg = 'An error has occurred. Sorry for the inconvenience.';

            if (xhr.responseJSON && xhr.responseJSON.message) {
              errorMsg = xhr.responseJSON.message;
            }

            that.$notify(errorMsg, 'error');
          },
          complete: function (xhr) {
            that.loading = false;
          }
        });

      },
      editAvailability: function () {
        this.$emit('availability-edit', this.availability);
      },
      deleteAvailability: function () {
        this.$emit('availability-delete', this.availability);
      },
      addAppointment: function () {
        CalendarEventBus.$emit('availability-add-appointment', this.availability);
        this.show = false;
      },
      editAppointment: function (appointment) {
        this.$emit('appointment-edit', appointment);
      },
      appointmentSendReviewRequest: function (appointment) {
        var self = this;
        if (confirm('Are you sure you want to send a review request to the client?')) {
          $.ajax({
            method: 'POST',
            url: '/api/appointments/' + appointment.id + '/send_review_request',
            success: function(res) {
              self.$notify("A review request has been sent to the client.", 'success');
            },
            error: function(xhr) {
              if (xhr.responseJSON && xhr.responseJSON.message) {
                self.$notify(xhr.responseJSON.message, 'error');
              } else {
                self.$notify("An error has occurred. Please try again!", 'error');
              }
            },
            complete: function() {
            }
          });
        }
      },
      repeatAppointment: function (appointment) {
        CalendarEventBus.$emit('appointment-repeat', appointment);
        this.show = false;
      },

      sendArrivalTimes: function () {

        if ([1, 4, 6].indexOf(this.availability.availability_type_id) == -1) {
          return;
        }

        if (this.availability.appointments.length > 1) {
          CalendarEventBus.$emit('availability-send-arrival-time', this.availability);
        }

        if (this.availability.appointments.length == 1) {
          const appt = this.availability.appointments[0];

          if (!appt.patient.mobile_formated) {
            this.$notify('The client mobile is blank or not valid', 'warning');
          } else {
            CalendarEventBus.$emit('appointment-send-arrival-time', appt);
          }
        }
      },
      onClickSendAppointmentArrivalTime: function(appointment) {
        if (!appointment.patient.mobile_formated) {
          this.$notify('The client has not a valid mobile number', 'error');
        } else {
          CalendarEventBus.$emit('appointment-send-arrival-time', appointment);
        }
      },

      onClickViewAvailabilityMap: function() {
        CalendarEventBus.$emit('availability-view-appointments-map', this.availability);
      },

      showRouteOnMap: function () {
        var appts = this.availability.appointments;
        var origin = this.availability.full_address;
        var dest = appts[appts.length - 1].patient.full_address;
        var waypoints = [];
        for (var i = 0; i < appts.length - 1; i++) {
          waypoints.push(appts[i].patient.full_address);
        }
        var params = {
          api: 1,
          origin: origin,
          destination: dest,
          waypoints: waypoints.join('|'),
          travelmode: 'driving'
        };
        window.open('https://www.google.com/maps/dir/?' + $.param(params), '_blank');
      },

      onClickSmsPractitionerOnRoute: function(appointment) {
        if (!appointment.patient.mobile_formated) {
          this.$notify('The client mobile is blank or not valid', 'warning');
        } else {
          CalendarEventBus.$emit('appointment-practitioner-on-route-sms', appointment);
        }
      },

      onBulkSMS: function()
      {
        CalendarEventBus.$emit('availability-bulk-sms', this.availability);
      },

      recalculateRoute: function() {
        // Check valid addresss
        for (var i = this.availability.appointments.length - 1; i >= 0; i--) {
          if (!this.availability.appointments[i].patient.latitude || !this.availability.appointments[i].patient.longitude) {
            this.$notify(
              'The address of client ' +
              this.availability.appointments[i].patient.full_name +
              ' is not recognized. Please check to correct before finding the route.',
              'error'
            );
            return;
          }
        }

        var self = this;
        $.ajax({
          method: 'PUT',
          beforeSend: function () {
            self.loading = true;
          },
          url: '/api/availabilities/' + self.availability.id + '/calculate_route',
          success: function (res) {
            self.fetchAndShow(self.availability.id);
            CalendarEventBus.$emit('availability-updated', res.availability);
            self.$notify('The route has been updated.', 'success');
          },
          error: function (xhr) {
            if (xhr.responseJSON && xhr.responseJSON.message) {
              self.$notify(xhr.responseJSON.message, 'error');
            } else {
              self.$notify('Could not find suitable route for appointments. Please check clients address.', 'error');
            }
          },
          complete: function () {
            self.loading = false;
          }
        });
      },

      optimizeRoute: function () {
        if (this.availability.order_locked) {
          this.$notify('The appointments order is locked!', 'warning');
          return;
        }
        // Check valid addresss
        for (var i = this.availability.appointments.length - 1; i >= 0; i--) {
          if (!this.availability.appointments[i].patient.latitude || !this.availability.appointments[i].patient.longitude) {
            this.$notify(
              'The address of client ' +
              this.availability.appointments[i].patient.full_name +
              ' is not recognized. Please check to correct before finding the route.',
              'error'
            );
            return;
          }
        }

        if (confirm('This will change the order of appointments as most efficient route.\nAre you sure want to continue?')) {
          var self = this;
          $.ajax({
            method: 'PUT',
            beforeSend: function () {
              self.loading = true;
            },
            url: '/api/availabilities/' + self.availability.id + '/optimize_route',
            success: function (res) {
              self.fetchAndShow(self.availability.id);
              CalendarEventBus.$emit('availability-appointments-order-updated', self.availability);
              self.$notify('Appointments order has been updated.', 'success');
            },
            error: function (xhr) {
              if (xhr.responseJSON && xhr.responseJSON.message) {
                self.$notify(xhr.responseJSON.message, 'error');
              } else {
                self.$notify('Could not find suitable route for appointments. Please check clients address.', 'error');
              }
            },
            complete: function () {
              self.loading = false;
            }
          });
        }
      },
      changePractitioner: function () {
        this.$emit('availability-change-practitioner', this.availability);
      },

      markAppointmentConfirmed: function(appointment) {
        var vm = this;

        $.ajax({
          method: 'PUT',
          url: '/api/appointments/' + appointment.id + '/mark_confirmed',
          beforeSend: function () {
            vm.loading = true;
          },
          success: function (res) {
            appointment.is_confirmed = true;
            CalendarEventBus.$emit('appointment-confirmation-status-updated', appointment);
            vm.$notify('The appointment has been marked as confirmed.');
          },
          error: function (xhr) {
            var errorMsg = 'An error has occurred. Sorry for the inconvenience.';

            if (xhr.responseJSON && xhr.responseJSON.message) {
              errorMsg = xhr.responseJSON.message;
            }

            vm.$notify(errorMsg, 'error');
          },
          complete: function () {
            vm.loading = false;
          }
        });
      },

      markAppointmentUnconfirmed: function(appointment) {
        var vm = this;

        $.ajax({
          method: 'PUT',
          url: '/api/appointments/' + appointment.id + '/mark_unconfirmed',
          beforeSend: function () {
            vm.loading = true;
          },
          success: function (res) {
            appointment.is_confirmed = false;
            CalendarEventBus.$emit('appointment-confirmation-status-updated', appointment);
            vm.$notify('The appointment has been marked as unconfirmed.');
          },
          error: function (xhr) {
            var errorMsg = 'An error has occurred. Sorry for the inconvenience.';

            if (xhr.responseJSON && xhr.responseJSON.message) {
              errorMsg = xhr.responseJSON.message;
            }

            vm.$notify(errorMsg, 'error');
          },
          complete: function () {
            vm.loading = false;
          }
        });
      },

      updateAppointmentStatus: function (appointment, status) {
        var that = this;

        $.ajax({
          method: 'PUT',
          url: '/api/appointments/' + appointment.id + '/update_status',
          data: {
            appointment: { status: status }
          },
          beforeSend: function () {
            that.loading = true;
          },
          success: function (res) {
            appointment.status = status;
            CalendarEventBus.$emit('appointment-status-updated', appointment);
            that.$notify('The appointment status has been updated successfully.');
          },
          error: function (xhr) {
            var errorMsg = 'An error has occurred. Sorry for the inconvenience.';

            if (xhr.responseJSON && xhr.responseJSON.message) {
              errorMsg = xhr.responseJSON.message;
            }

            that.$notify(errorMsg, 'error');
          },
          complete: function () {
            that.loading = false;
          }
        });
      },
      deleteAppointment: function (appointment) {
        var that = this;
        if (confirm('This action cannot be undo! Are you sure want to delete this appointment?')) {
          $.ajax({
            method: 'DELETE',
            url: '/api/appointments/' + appointment.id,
            success: function (res) {
              for (var i = 0; i < that.availability.appointments.length; i++) {
                if (that.availability.appointments[i].id === appointment.id) {
                  that.availability.appointments.splice(i, 1);
                  break;
                }
              }
              that.$emit('appointment-deleted', appointment);
              that.$notify('The appointment has been deleted successfully.');
            }
          });
        }
      },
      cancelAppointment: function (appointment) {
        var that = this;
        if (confirm('This action cannot be undo! Are you sure want to cancel this appointment?')) {
          $.ajax({
            method: 'PUT',
            url: '/api/appointments/' + appointment.id + '/cancel',
            success: function (res) {
              for (var i = 0; i < that.availability.appointments.length; i++) {
                if (that.availability.appointments[i].id === appointment.id) {
                  that.availability.appointments.splice(i, 1);
                  break;
                }
              }
              that.$emit('appointment-cancelled', appointment);
              that.$notify('The appointment has been cancelled successfully.');
            }
          });
        }
      },
      showAppointmentNote: function (appointment) {
        CalendarEventBus.$emit('appointment-note-show', appointment);
      },
      showAppointmentBookingsAnswers: function (appointment) {
        CalendarEventBus.$emit('appointment-bookings-answers-show', appointment);
      },
      lockAppointmentsOrder: function () {
        var self = this;
        self.loading = true;

        $.ajax({
          method: 'PUT',
          url: '/api/availabilities/' + self.availability.id + '/lock_order',
          success: function (res) {
            self.availability.order_locked = true;
            CalendarEventBus.$emit('availability-order-locked', self.availability);
            self.$notify('The appointments order has been locked.');
          },
          error: function (xhr) {
            var errorMsg = 'An error has occurred. Sorry for the inconvenience.';

            if (xhr.responseJSON && xhr.responseJSON.message) {
              errorMsg = xhr.responseJSON.message;
            }

            self.$notify(errorMsg, 'error');
          },
          complete: function () {
            self.loading = false;
          }
        });
      },
      unlockAppointmentsOrder: function () {
        var self = this;
        self.loading = true;

        $.ajax({
          method: 'PUT',
          url: '/api/availabilities/' + self.availability.id + '/unlock_order',
          success: function (res) {
            self.availability.order_locked = false;
            CalendarEventBus.$emit('availability-order-unlocked', self.availability);
            self.$notify('The appointments order is unlocked.');
          },
          error: function (xhr) {
            var errorMsg = 'An error has occurred. Sorry for the inconvenience.';

            if (xhr.responseJSON && xhr.responseJSON.message) {
              errorMsg = xhr.responseJSON.message;
            }

            self.$notify(errorMsg, 'error');
          },
          complete: function () {
            self.loading = false;
          }
        });
      },
      appointmentTreatmentNoteUrl: function(appointment) {
        return '/app/patients/' + appointment.patient_id + '/treatments/new?appointment_id=' + appointment.id;
      },

      addInvoiceUrl: function(appointment) {
        return '/app/invoices/new?appointment_id=' + appointment.id;
      },

      appointmentInvoiceUrl: function(appointment) {
        var invoiceUrl = null;

        if (appointment.invoice) {
          invoiceUrl = '/app/invoices/' + appointment.invoice.id;
        } else {
          invoiceUrl = '/app/invoices/new?appointment_id=' + appointment.id;
        }

        return invoiceUrl;
      },
      showPatient: function(patient) {
        CalendarEventBus.$emit('patient-show', patient);
      },
      openAttendanceProofModal: function(appt) {
        CalendarEventBus.$emit('appointment-attendance-proof', appt);
      }
    }
  });
})();
