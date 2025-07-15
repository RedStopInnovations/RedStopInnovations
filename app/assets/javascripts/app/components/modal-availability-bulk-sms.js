
(function () {
  'use strict';

  Vue.component('modal-availability-bulk-sms', {
    template: '#modal-availability-bulk-sms-tmpl',
    mixins: [bootstrapModal],
    data: function () {
      return {
        show: false,
        loading: false,
        availability: null,
        sendOption: 'SKIP_REMINDER_DISABLED',
        communication_category: 'general',
        content: '',
        formErrors: [],
        templates: [
          {
            label: 'Sick leave',
            communication_category: 'practitioner_sick_leave',
            content: 'To {{ Patient.FullName }},\nUnfortunately, {{ Practitioner.FullName }} cannot attend your scheduled appointment on {{ Appointment.Date }}; I apologise for any trouble. They will provide more information on return to work. They will reach out to you soon to schedule additional appointments if needed.\nThis is a no-reply SMS number. If you have any questions, please call {{ Business.Phone }}.'
          }
        ]
      };
    },

    mounted: function () {
      var vm = this;

      CalendarEventBus.$on('availability-bulk-sms', function (availability) {
        vm.availability = availability;
        vm.showModal();
      });
    },

    computed: {
      hasPatientReminderNotEnabledOrNoMobile: function () {
        if (this.availability) {
          for (let i = 0; i < this.availability.appointments.length; i++) {
            const appt = this.availability.appointments[i];
            if (!appt.patient.mobile_formated || !appt.patient.reminder_enable) {
              return true;
            }
          }
        }

        return false;
      }
    },

    methods: {
      showModal: function () {
        this.show = true;
      },

      onModalClosed: function () {
        this.show = false;
        this.reset();
      },

      reset: function () {
        this.availability = null;
        this.content = '';
        this.sendOption = 'SKIP_REMINDER_DISABLED';
        this.communication_category = 'general';
        this.formErrors = [];
      },

      close: function () {
        this.show = false;
      },

      setTemplate: function (template) {
        this.content = template.content;
        this.communication_category = template.communication_category;
      },

      onClickSubmit: function () {
        this.submit();
      },

      buildSubmitData: function () {
        return {
          communication_category: this.communication_category,
          send_option: this.sendOption,
          content: this.content
        };
      },

      submit: function () {
        var vm = this;
        vm.loading = true;
        vm.formErrors = [];

        $.ajax({
          method: 'POST',
          url: '/api/availabilities/' + vm.availability.id + '/send_bulk_sms',
          dataType: 'json',
          contentType: 'application/json',
          data: JSON.stringify(vm.buildSubmitData()),
          success: function (res) {
            vm.$notify("The messages has been sent", 'success');
            vm.close();
            vm.loading = false;
          },
          error: function (xhr) {
            vm.loading = false;

            if (xhr.responseJSON && xhr.responseJSON.message) {
              vm.$notify(xhr.responseJSON.message, 'error');
            } else {
              vm.$notify("An error has occurred. Sorry for the inconvenience.", 'error');
            }

            if (xhr.status === 422 && xhr.responseJSON.errors) {
              vm.formErrors = xhr.responseJSON.errors;
            }

          },
          complete: function () {
            vm.loading = false;
          }
        });
      }
    }
  })
})();