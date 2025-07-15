(function() {
  'use strict';

  Vue.component('appointments-list-listview', {
    template: '#appointments-list-listview-tmpl',
    props: {
      business: {
        type: Object,
        required: true
      },
      availability: {
        type: Object,
        required: true
      }
    },
    computed: {
      isCanViewInvoice: function() {
        return App.user && (App.user.role != App.CONSTANTS.USER.ROLE_RESTRICTED_PRACTITIONER);
      }
    },
    mounted: function() {
      this.calculateStats(this.availability);
    },
    methods: {
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
      showPatient: function(patient) {
        CalendarEventBus.$emit('patient-show', patient);
      },
      editAppointment: function(appointment) {
        CalendarEventBus.$emit('appointment-edit', appointment);
      },
      repeatAppointment: function(appointment) {
        CalendarEventBus.$emit('appointment-repeat', appointment);
      },
      cancelAppointment: function(appointment) {
        var that = this;
        if (confirm('This action cannot be undo! Are you sure want to cancel this appointment?')) {
          $.ajax({
            method: 'PUT',
            url: '/api/appointments/' + appointment.id + '/cancel',
            success: function(res) {
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
      deleteAppointment: function(appointment) {
        var that = this;
        if (confirm('This action cannot be undo! Are you sure want to delete this appointment?')) {
          $.ajax({
            method: 'DELETE',
            url: '/api/appointments/' + appointment.id,
            success: function(res) {
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
      appointmentTreatment: function(appointment) {
        var treatmentNoteUrl = null;

        if (appointment.treatment) {
          treatmentNoteUrl = '/app/patients/' + appointment.patient_id + '/treatments/' + appointment.treatment.id;
        } else {
          treatmentNoteUrl = '/app/patients/' + appointment.patient_id + '/treatments/new?appointment_id=' + appointment.id;
        }

        window.location.href = treatmentNoteUrl;
      },
      appointmentSendReviewRequest: function(appointment) {
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
      appointmentInvoice: function(appointment) {
        var invoiceUrl = '';

        if (appointment.invoice) {
          invoiceUrl = '/app/invoices/' + appointment.invoice.id;
        } else {
          invoiceUrl = '/app/invoices/new?appointment_id=' + appointment.id;
        }
        window.location.href = invoiceUrl;
      },

      onClickSendAppointmentArrivalTime: function(appointment) {
        if (!appointment.patient.mobile_formated) {
          this.$notify('The client has not a valid mobile number', 'error');
        } else {
          CalendarEventBus.$emit('appointment-send-arrival-time', appointment);
        }
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

      updateAppointmentStatus: function(appointment, status) {
        var that = this;

        $.ajax({
          method: 'PUT',
          url: '/api/appointments/' + appointment.id + '/update_status',
          data: {
            appointment: { status: status }
          },
          beforeSend: function() {
            that.loading = true;
          },
          success: function(res) {
            appointment.status = status;
            that.$notify('The appointment status has been updated successfully.');
            CalendarEventBus.$emit('appointment-status-updated', appointment);
          },
          error: function(xhr) {
            var errorMsg = 'An error has occurred. Sorry for the inconvenience.';

            if (xhr.responseJSON && xhr.responseJSON.message) {
              errorMsg = xhr.responseJSON.message;
            }

            that.$notify(errorMsg, 'error');
          },
          complete: function() {
            that.loading = false;
          }
        });
      },

      showAppointmentNote: function(appointment) {
        CalendarEventBus.$emit('appointment-note-show', appointment);
      },

      onClickSmsPractitionerOnRoute: function(appointment) {
        if (!appointment.patient.mobile_formated) {
          this.$notify('The client mobile is blank or not valid', 'warning');
        } else {
          CalendarEventBus.$emit('appointment-practitioner-on-route-sms', appointment);
        }
      },
    }
  });
})();
