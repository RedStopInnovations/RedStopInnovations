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
        cases: [],
        associatedContactsLoaded: false,
        associatedContacts: []
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
          if (!self.associatedContactsLoaded) {
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
        this.associatedContactsLoaded = false;
        this.associatedContacts = [];
        this.isRestricted = false;
      },

      loadCases: function () {
        var self = this;
        $.ajax({
          method: 'GET',
          url: '/api/patients/' + self.patient.id + '/patient_cases.json',
          success: function (res) {
            self.cases = res.patient_cases;
          },
          error: function(xhr) {
            self.$notify('Cannot load open cases info. An error has occured.', 'error');
          }
        });
      },
      loadContacts: function () {
        var self = this;
        $.ajax({
          method: 'GET',
          url: '/api/patients/' + self.patient.id + '/associated_contacts.json',
          success: function (res) {
            self.associatedContacts = res.associated_contacts;
            self.associatedContactsLoaded = true;
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

              self.loadCases();
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
