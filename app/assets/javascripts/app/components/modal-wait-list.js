(function() {
  Vue.component('modal-wait-list', {
    template: '#modal-wait-list-tmpl',
    data: function() {
      return {
        show: false,
        waitLists: [],
        selectedAppointmentType: null,
        selectedPractitioner: null,
        filters: this.defaultFilters(),
        sort: 'newest',
        pagination: {
          total_entries: 0,
          page: 1,
          per_page: 10,
          paginator_options: {
            previousText: 'Prev',
            nextText: 'Next'
          }
        },
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
    mounted: function() {
      var self = this;
      CalendarEventBus.$on('waitlist-deleted', function(waitList) {
        self.pagination.page = 1;
        self.fetchWaitLists();
      });

      CalendarEventBus.$on('waitlist-scheduled', function(waitList) {
        self.pagination.page = 1;
        self.fetchWaitLists();
      });
    },
    methods: {
      defaultFilters: function() {
        return {
          patient_search: '',
          location_search: '',
          profession: '',
          appointment_type_id: null,
          practitioner_id: null,
        };
      },
      onModalClosed: function() {
        this.show = false;
        this.resetFilters();
      },
      showModal: function() {
        this.show = true;
        this.resetFilters();
        this.fetchWaitLists();
      },
      close: function() {
        this.show = false;
        this.resetFilters();
      },
      resetFilters: function() {
        this.filters = this.defaultFilters();
        this.selectedAppointmentType = null;
        this.selectedPractitioner = null;
      },
      isShow: function() {
        return this.show;
      },
      isAnyFilterSet: function() {
        for (var key in this.filters) {
          if (this.filters[key]) {
            return true;
          }
        }
        return false;
      },
      print: function() {
        var printUrl = '/app/wait_lists/print';
        var params = {};
        for (var key in this.filters) {
          if (this.filters[key]) {
            params[key] = this.filters[key];
          }
        }

        if (Object.keys(params).length > 0) {
          printUrl += '?' + $.param(params);
        }
        window.open(printUrl, '_blank');
      },
      addPatient: function() {
        console.log('Not implemented');
      },
      searchAppointments: function(waitList) {
        var url = encodeURI('/app/calendar/search-appointment?location=' + waitList.patient.full_address);
        window.open(url, '_blank');
      },
      scheduleAppointment: function(waitList) {
        CalendarEventBus.$emit('waitlist-schedule', waitList);
      },
      clearFiltersAndFetch: function() {
        this.resetFilters();
        this.pagination.page = 1;
        this.fetchWaitLists();
      },
      onFilterChanged: function(practitioner) {
        this.waitLists = [];
        this.pagination.total_entries = 0;
        this.pagination.page = 1;
      },
      onPageChanged: function(page) {
        this.pagination.page = page;
        this.fetchWaitLists();
      },
      onSearchPatientChanged: debounce(
        function() {
          this.filters.location_search = '';
          this.pagination.page = 1;
          this.fetchWaitLists();
        },
        450
      ),
      onSearchLocationChanged: debounce(
        function() {
          this.filters.patient_search = '';
          this.pagination.page = 1;
          this.fetchWaitLists();
        },
        450
      ),
      onProfessionChanged: function() {
        this.pagination.page = 1;
        this.fetchWaitLists();
      },
      onAppointmentTypeChanged: function(at) {
        this.pagination.page = 1;
        if (at && at.id === 0) {
          this.selectedAppointmentType = null;
          this.filters.appointment_type_id = null;
        } else if (at) {
          this.filters.appointment_type_id = at.id;
        }
        this.fetchWaitLists();
      },

      onPractitionerChanged: function(pract) {
        this.pagination.page = 1;

        if (pract) {
          this.filters.practitioner_id = pract.id;
        } else {
          this.filters.practitioner_id = null;
        }
        this.fetchWaitLists();
      },
      bindGoogleAutocomplete: function() {
        var that = this;

        var autocomplete = new google.maps.places.Autocomplete(
          this.$refs.inputLocation, {
            types: ['(cities)'],
            componentRestrictions: { country: that.business.country }
          }
        );

        autocomplete.addListener('place_changed', function() {
          var place = autocomplete.getPlace();
          that.filters.patient_search = '';
          if (typeof(place.geometry) === 'undefined') {
            // User pressed enter without select a suggestion
            that.filters.location_search = place.name;
          } else {
            // user selected a suggestion
            var formattedLocation = null;
            for (var i = place.address_components.length - 1; i >= 0; i--) {
              var cmp = place.address_components[i];
              // User selected a city or region
              if (cmp.types.filter(function(type) { return ['locality', 'political'].indexOf(type) == -1 }).length == 0) {
                formattedLocation = cmp.long_name;
              }
            }
            if (!formattedLocation) {
              formattedLocation = place.formatted_address;
            }
            that.filters.location_search = formattedLocation;
          }

          that.pagination.page = 1;
          that.fetchWaitLists();
        });
      },
      addEntry: function() {
        this.$emit('wait-list-add');
      },
      editEntry: function(waitList) {
        this.$emit('wait-list-edit', waitList);
      },
      markScheduledEntry: function(waitList) {
        if (confirm('This action could not be undo.\nAre you sure?')) {
          var that = this;
          $.ajax({
            method: 'PUT',
            url: '/api/wait_lists/' + waitList.id + '/mark_scheduled',
            beforeSend: function() {
              that.loading = true;
            },
            success: function(res) {
              that.$notify('An entry has been marked as scheduled.');
              that.fetchWaitLists();
            },
            error: function(xhr) {
              that.$notify('An error has occurred. Sorry for the inconvenience.');
            },
            complete: function() {
              that.loading = false;
            }
          });
        }
      },
      deleteEntry: function(waitList) {
        CalendarEventBus.$emit('waitlist-delete', waitList);
      },
      buildWaitListsQuery: function() {
        var query = {};

        for (var key in this.filters) {
          if (this.filters[key]) {
            query[key] = this.filters[key];
          }
        }

        query.page = this.pagination.page;
        return query;
      },
      fetchWaitLists: function() {
        var that = this;
        $.ajax({
          method: 'GET',
          url: '/api/wait_lists' + '?' + $.param(that.buildWaitListsQuery()),
          beforeSend: function() {
            that.loading = true;
          },
          success: function(res) {
            that.waitLists = res.wait_lists;
            that.pagination.total_entries = res.total_entries;
          },
          error: function(xhr) {

          },
          complete: function() {
            that.loading = false;
          },
        });
      },
      isOverdue: function(waitList) {
        return Date.parse(waitList.date + ' 00:00:00') <= (new Date()).setHours(0 , 0, 0, 0);
      },
      showPatientInfo: function(waitList) {
        CalendarEventBus.$emit('patient-show', waitList.patient);
      }
    }
  });
})();
