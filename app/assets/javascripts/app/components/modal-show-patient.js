(function () {
  'use strict';

  Vue.component('modal-show-patient', {
    template: '#modal-show-patient-tmpl',
    mixins: [bootstrapModal],
    props: {
      business: {
        type: Object,
        required: true
      },
    },
    data: function () {
      return {
        show: false,
        isRestricted: false,
        patient: null,
        contactsLoaded: false,
        contacts: {
          doctor_contacts: [],
          specialist_contacts: [],
          referrer_contacts: [],
          invoice_to_contacts: [],
          emergency_contacts: [],
          other_contacts: []
        }
      }
    },
    mounted: function () {
      var self = this;

      CalendarEventBus.$on('patient-show', function (patient) {
        self.resetData();
        self.fetchAndShow(patient.id);
      });

      $(self.$el).on('shown.bs.tab', '.nav-tabs a', function (event) {
        if ($(event.target).attr('href') == '#patient-contacts-tab') {
          if (!self.contactsLoaded) {
            self.loadContacts();
          }
        }
      });
    },
    methods: {
      close: function () {
        this.show = false;
      },
      onModalClosed: function () {
        this.show = false;
        this.resetData();
      },
      resetData: function() {
        this.patient = null;
        this.contactsLoaded = false;
        this.isRestricted = false;
        this.contacts = {
          doctor_contacts: [],
          specialist_contacts: [],
          referrer_contacts: [],
          invoice_to_contacts: [],
          emergency_contacts: [],
          other_contacts: []
        };
      },
      loadContacts: function () {
        var self = this;
        $.ajax({
          method: 'GET',
          url: '/app/patients/' + self.patient.id + '/contacts.json',
          success: function (res) {
            self.contacts = res;
            self.contactsLoaded = true;
          },
          error: function(xhr) {
            self.$notify('Cannot load contacts info. An error has occured.', 'error');
          }
        });
      },
      fetchAndShow: function (patientId) {
        var self = this;

        $.ajax({
          method: 'GET',
          url: '/app/patients/' + patientId + '.json',
          success: function (res) {
            if (res.patient) {
              self.patient = res.patient;
              self.$nextTick(function() {
                $(self.$el).find('.nav-tabs > li > a:first')[0].click();
              });
            } else {
              self.$notify('Cannot load client info. An error has occured.', 'error');
            }
            self.show = true;
          },
          error: function(xhr) {
            if (xhr.status == 403) {
              self.isRestricted = true;
            } else if (xhr.status == 404) {
              self.$notify('The client does not exist!', 'error');
            } else {
              self.$notify('Cannot load client info. An error has occured', 'error');
            }
          },
          complete: function() {
            self.show = true;
          }
        });
      }
    }
  });
})();
