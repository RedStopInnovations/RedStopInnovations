(function() {
  'use strict';
  var DEFAULT_DISTANCE = 20;
  var DEFAULT_DAYS_AHEAD = 30;

  var COLOR_PALETE = [
    '#ec3250',
    '#377eb8',
    '#66a61e',
    '#984ea3',
    '#00d2d5',
    '#ff7f00',
    '#b3e900',
    '#c42e60',
    '#f781bf',
    '#fccde5',
    '#ffed6f'
  ];

  var APPT_MARKER_ICON_OPTIONS = {
    path: 'M16 0c-5.523 0-10 4.477-10 10 0 10 10 22 10 22s10-12 10-22c0-5.523-4.477-10-10-10zM16 16c-3.314 0-6-2.686-6-6s2.686-6 6-6 6 2.686 6 6-2.686 6-6 6z',
    fillOpacity: 1,
    scale: 0.8,
    strokeWeight: 1,
    anchor: {x: 12, y: 10}
  };

  var PRACTITIONER_LOCATION_MARKER_ICON_OPTIONS = {
    url: '/assets/user-location-marker.svg',
    scaledSize: {
      width: 48,
      height: 48
    },
    size: {
      width: 48,
      height: 48
    },
    anchor: {x: 25, y: 15}
  };

  var FACILITY_AVAIL_MARKER_ICON_OPTIONS = {
    path: 'M1 22h2v-22h18v22h2v2h-22v-2zm7-3v4h3v-4h-3zm5 0v4h3v-4h-3zm-6-5h-2v2h2v-2zm8 0h-2v2h2v-2zm-4 0h-2v2h2v-2zm8 0h-2v2h2v-2zm-12-4h-2v2h2v-2zm8 0h-2v2h2v-2zm-4 0h-2v2h2v-2zm8 0h-2v2h2v-2zm-12-4h-2v2h2v-2zm8 0h-2v2h2v-2zm-4 0h-2v2h2v-2zm8 0h-2v2h2v-2zm-12-4h-2v2h2v-2zm8 0h-2v2h2v-2zm-4 0h-2v2h2v-2zm8 0h-2v2h2v-2z',
    fillOpacity: 1,
    scale: 1,
    strokeWeight: 1,
    anchor: {x: 10, y: 10}
  };

  var HOME_VISIT_AVAIL_MARKER_ICON_OPTIONS = {
    path: 'M17.659,9.597h-1.224c-0.199-3.235-2.797-5.833-6.032-6.033V2.341c0-0.222-0.182-0.403-0.403-0.403S9.597,2.119,9.597,2.341v1.223c-3.235,0.2-5.833,2.798-6.033,6.033H2.341c-0.222,0-0.403,0.182-0.403,0.403s0.182,0.403,0.403,0.403h1.223c0.2,3.235,2.798,5.833,6.033,6.032v1.224c0,0.222,0.182,0.403,0.403,0.403s0.403-0.182,0.403-0.403v-1.224c3.235-0.199,5.833-2.797,6.032-6.032h1.224c0.222,0,0.403-0.182,0.403-0.403S17.881,9.597,17.659,9.597 M14.435,10.403h1.193c-0.198,2.791-2.434,5.026-5.225,5.225v-1.193c0-0.222-0.182-0.403-0.403-0.403s-0.403,0.182-0.403,0.403v1.193c-2.792-0.198-5.027-2.434-5.224-5.225h1.193c0.222,0,0.403-0.182,0.403-0.403S5.787,9.597,5.565,9.597H4.373C4.57,6.805,6.805,4.57,9.597,4.373v1.193c0,0.222,0.182,0.403,0.403,0.403s0.403-0.182,0.403-0.403V4.373c2.791,0.197,5.026,2.433,5.225,5.224h-1.193c-0.222,0-0.403,0.182-0.403,0.403S14.213,10.403,14.435,10.403',
    fillOpacity: 1,
    scale: 1.5,
    strokeWeight: 1,
    anchor: {x: 10, y: 10}
  };

  var CIRCLE_OPTONS = {
    strokeOpacity: 1,
    strokeWeight: 1,
    fillOpacity: 0.07
  };

  var LOCATION_MARKER_ICON_OPTIONS = {
    path: 'M16 4.588l2.833 8.719H28l-7.416 5.387 2.832 8.719L16 22.023l-7.417 5.389 2.833-8.719L4 13.307h9.167L16 4.588z',
    fillOpacity: 1,
    fillColor: '#f5f52b',
    scale: 1,
    strokeWeight: 1,
    strokeColor: '#f5f52b',
    anchor: {x: 15, y: 15}
  };

  var MARKER_MOUSE_HOVER_DELAY = 600;

  Vue.component('search-appointment', {
    template: '#search-appointment-tmpl',
    data: function() {
      return {
        ready: false,
        business: null,
        loading: true,
        searchType: 'address',
        filters: {
          location: '',
          distance: DEFAULT_DISTANCE,
          profession: '',
          availability_type_id: 1,
          practitioner_group_id: null,
          start_date: null,
          end_date: null,
        },
        pagination: {
          enable: false,
          total_entries: 0,
          page: 1,
          per_page: 25,
          paginator_options: {
            previousText: 'Prev',
            nextText: 'Next'
          }
        },
        result: {
          nearby_practitioners: [],
          availabilities: []
        },
        patientOptions: [],
        isSearchingPatients: false,
        selectedPatient: null,
        allPractitioners: [],
        allPractitionerGroups: [],
        availablePractitioners: [], // practitioner has availability
        // Map
        mapZoom: 9,
        mapCenter: {
          lat: -33.9073417,
          lng: 151.1391135
        },
        queryLocationMarker: {
          position: null,
          icon: LOCATION_MARKER_ICON_OPTIONS,
          title: null
        },
        selectedApptMarker: null,
        showApptMarkerWindow: false,

        selectedAvailMarker: null,
        showAvailMarkerWindow: false,

        selectedPractitionerLocationMarker: null,
        showPractitionerLocationMarkerWindow: false,

        showQueryLocationMarkerWindow: false,
        mapOptions: {
          gestureHandling: 'greedy',
          streetViewControl: false,
          mapTypeId: 'roadmap'
        },
        availabilityMarkers: [],
        appointmentMarkers: [],
        availabilityCircles: [],
        practitionerLocationMarkers: [], // Markers for all practitioner locations
        options: {
          showAvailabilityArea: true,
          showBookedAppoinments: true,
          showPractitionerLocations: false
        },

        availabilityDatePickerConfig: {
          altInput: true,
          altFormat: 'd M Y',
          disableMobile: true,
          minDate: 'today'
        }
      };
    },
    computed: {
      isFiltersSufficient: function() {
        return this.filters.location.length > 0;
      }
    },

    filters: {
      estimatedNextAppointmentTime: function(avail) {
        if (avail.appointments.length > 0) {
          if (avail.last_appointment_end) {
            return avail.last_appointment_end.clone().add(15, 'minutes');
          } else {
            return avail.start_time;
          }
        } else {
          return avail.start_time;
        }
      }
    },

    created: function() {
      this.apptMarkerMouseHoverTimeout = null;
      this.availMarkerMouseHoverTimeout = null;
    },
    mounted: function() {
      var self = this;

      if (Utils.getQueryParameter('location')) {
        // Prefill location from query params.
        this.filters.location = decodeURIComponent(
          Utils.getQueryParameter('location')
        );
        this.updateQueryLocationMarker();
      } else if (Utils.getQueryParameter('patient_id')) {
        // Prefill location from query params.
        $.ajax({
          url: '/api/patients/' + Utils.getQueryParameter('patient_id'),
          success: function(res) {
            self.searchType = 'patient';
            self.selectedPatient = res.patient;
            self.filters.availability_type_id = 1;
          },
          error: function(xhr) {
            self.$notify('There was an error while retrieving the client info.', 'error');
          }
        });
      }

      this.filters.start_date = moment().format('YYYY-MM-DD');
      this.filters.end_date = moment().add(DEFAULT_DAYS_AHEAD, 'days').format('YYYY-MM-DD');

      var that = this;
      $.ajax({
        method: 'GET',
        url: '/api/businesses/info.json',
        success: function(res) {
          that.setBusiness(res.business);
          that.ready = true;
          that.$nextTick(function() {
            var $inputLoc = $('#input-location');
            var autocomplete = new google.maps.places.Autocomplete(
              $inputLoc[0], autocompleteDefaultOptions
            );
            autocomplete.addListener('place_changed', function() {
              var place = autocomplete.getPlace();
              var location = null;
              if (typeof(place.geometry) === 'undefined') {
                location = place.name;
              } else {
                location = autocomplete.getPlace().formatted_address;
              }
              if (location) {
                that.filters.location = location;
                that.updateQueryLocationMarker();
                that.loadAppointmentData();
              }
            });
          });

          that.allPractitioners = res.business.practitioners;
          that.allPractitionerGroups = res.business.groups;
          that.buildPractitionerLocationMarkers();
        }
      });
    },
    methods: {
      setBusiness: function(business) {
        this.business = business;
        this.loadAppointmentData();
      },
      updateQueryLocationMarker: function() {
        var that = this;
        var geocoder = new google.maps.Geocoder();
        geocoder.geocode({'address': that.filters.location}, function(results, status) {
          if (status == 'OK') {
            var position = results[0].geometry.location;
            that.queryLocationMarker.title = that.filters.location;
            that.queryLocationMarker.position = {
              lat: position.lat(),
              lng: position.lng()
            };
          } else {
            that.queryLocationMarker.position = null;
            that.showQueryLocationMarkerWindow = false;
            that.queryLocationMarker.title = null;
            // Flash.error('The client address is unrecognizable.');
          }
        });
      },
      onPageChanged: function(page) {
        this.pagination.page = page;
        this.showApptMarkerWindow = false;
        this.showAvailMarkerWindow = false;
        this.loadAppointmentData();
      },

      buildQueryParams: function() {
        var query = {
          distance: this.filters.distance,
          profession: this.filters.profession,
          availability_type_id: this.filters.availability_type_id,
          practitioner_group_id: this.filters.practitioner_group_id,
          page: this.pagination.page,
          per_page: this.pagination.per_page,
          start_date: this.filters.start_date,
          end_date: this.filters.end_date,
        };

        if (this.searchType == 'address') {
          query.location = this.filters.location;
        }

        if (this.searchType == 'patient' && this.selectedPatient) {
          query.patient_id = this.selectedPatient.id;
        }

        return query;
      },
      generatePractitionerColor: function(id) {
        var practIdx = 0;
        for (var i = 0, pl = this.availablePractitioners.length; i < pl; i++) {
          if (this.availablePractitioners[i].id === id) {
            practIdx = i;
            break;
          }
        }

        return COLOR_PALETE[practIdx];
      },

      addToWaitingListUrl: function(avail) {
        var params = {
          _ia: 'add_to_waiting_list',
        }

        if (this.selectedPatient) {
          params.patient_id = this.selectedPatient.id;
        }

        if (this.filters.profession) {
          params.profession = this.filters.profession;
        }

        if (avail) {
          params.practitioner_id = avail.practitioner_id;
        }

        return '/app/calendar?' + $.param(params);
      },
      onQueryLocationChange: function() {
        this.updateQueryLocationMarker();
      },
      onApptMarkerClick: function(apptMarker) {
        this.selectedApptMarker = apptMarker;
        this.showApptMarkerWindow = true;
      },
      onApptMarkerMouseOver: function(apptMarker) {
        var that = this;
        this.apptMarkerMouseHoverTimeout = window.setTimeout(function() {
          that.selectedApptMarker = apptMarker;
          that.showApptMarkerWindow = true;
        }, MARKER_MOUSE_HOVER_DELAY);
      },
      onApptMarkerMouseOut: function(apptMarker) {
        window.clearTimeout(this.apptMarkerMouseHoverTimeout);
      },
      onAvailMarkerClick: function(availMarker) {
        this.selectedAvailMarker = availMarker;
        this.showAvailMarkerWindow = true;
      },
      onAvailMarkerMouseOver: function(availMarker) {
        var that = this;
        this.availMarkerMouseHoverTimeout = window.setTimeout(function() {
          that.selectedAvailMarker = availMarker;
          that.showAvailMarkerWindow = true;
        }, MARKER_MOUSE_HOVER_DELAY);
      },
      onAvailMarkerMouseOut: function(availMarker) {
        window.clearTimeout(this.availMarkerMouseHoverTimeout);
      },
      onShowAvailabilityAreaChange: function() {
        if (this.options.showAvailabilityArea) {
          this.loadAppointmentData();
        } else {
          this.availabilityCircles = [];
          this.availabilityMarkers = [];
          this.selectedAvailMarker = null;
        }
      },
      onshowBookedAppoinmentsChange: function() {
        if (!this.options.showBookedAppoinments) {
          this.showApptMarkerWindow = false;
        }
        this.loadAppointmentData();
      },
      onShowPractitionerLocationsChange: function() {
        if (!this.options.showPractitionerLocations) {
          this.showPractitionerLocationMarkerWindow = false;
        }
      },
      onPractitionerLocationMarkerClick: function(marker) {
        this.selectedPractitionerLocationMarker = marker;
        this.showPractitionerLocationMarkerWindow = true;
      },

      onClickViewPractitionerProfile: function(practitioner) {
        CalendarEventBus.$emit('practitioner-show', practitioner);
      },

      onSearchTypeChange: function() {
        this.$nextTick(function() {
          if (this.searchType == 'address' && !this.filters.location) {
            this.$refs.inputLocation.focus();
          } else if (this.searchType == 'patient' && !this.selectedPatient) {
            this.$refs.patientSelect.$el.focus();
          } else if (this.filters.location || this.selectedPatient) {
            this.loadAppointmentData();
          }
        });
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
        if (patient && patient.latitude && patient.longitude) {
          this.queryLocationMarker.position = {
            lat: patient.latitude,
            lng: patient.longitude
          };
          this.queryLocationMarker.title = patient.short_address;
        } else {
          this.showQueryLocationMarkerWindow = false;
          this.queryLocationMarker.position = null;
          this.queryLocationMarker.title = null;
        }
        this.selectedPatient = patient;
        this.pagination.page = 1;

        this.loadAppointmentData();
      },

      onPractitionerGroupChange: function() {
        this.pagination.page = 1;
        this.loadAppointmentData();
      },

      customPatientLabel: function(patient) {
        return patient.full_name + ' (' + patient.short_address + ')';
      },

      onFilterStartDateChange: function() {
        this.pagination.page = 1;
        this.loadAppointmentData();
      },

      onFilterEndDateChange: function() {
        this.pagination.page = 1;
        this.loadAppointmentData();
      },

      onProfessionChange: function() {
        this.pagination.page = 1;
        this.loadAppointmentData();
      },

      onAvailabilityTypeChange: function() {
        this.pagination.page = 1;
        this.loadAppointmentData();
      },

      onDistanceChange: function() {
        this.pagination.page = 1;
        this.loadAppointmentData();
      },

      setDateRange: function(range) {
        switch(range) {
          case 'today': {
            this.filters.start_date =
              this.filters.end_date =
              moment().format('YYYY-MM-DD');
            break;
          }
          case 'tomorrow': {
            this.filters.start_date =
              this.filters.end_date
              = moment().add(1, 'days').format('YYYY-MM-DD');
            break;
          }
          case 'next_2_days': {
            this.filters.start_date = moment().format('YYYY-MM-DD');
            this.filters.end_date = moment().add(2, 'days').format('YYYY-MM-DD');
            break;
          }
          case 'next_7_days': {
            this.filters.start_date = moment().format('YYYY-MM-DD');
            this.filters.end_date = moment().add(7, 'days').format('YYYY-MM-DD');
            break;
          }
          case 'next_14_days': {
            this.filters.start_date = moment().format('YYYY-MM-DD');
            this.filters.end_date = moment().add(14, 'days').format('YYYY-MM-DD');
            break;
          }
          case 'next_30_days': {
            this.filters.start_date = moment().format('YYYY-MM-DD');
            this.filters.end_date = moment().add(30, 'days').format('YYYY-MM-DD');
            break;
          }
        }

        this.pagination.page = 1;
        this.loadAppointmentData();
      },

      buildPractitionerLocationMarkers: function() {
        var markers = [];
        for (var i = 0, l = this.allPractitioners.length; i < l; i++) {
          var pract = this.allPractitioners[i];
          if (pract.latitude && pract.longitude) {
            var marker = {
              icon: PRACTITIONER_LOCATION_MARKER_ICON_OPTIONS,
              practitioner: pract,
              position: {
                lat: pract.latitude,
                lng: pract.longitude
              }
            };

            markers.push(marker);
          }
        }

        this.practitionerLocationMarkers = markers;
      },
      loadAppointmentData: function() {
        var that = this;
        that.loading = true;
        $.ajax({
          url: '/api/search_appointment.json',
          data: that.buildQueryParams(),
          success: function(res) {
            var availabilities = res.availabilities;
            that.result.nearby_practitioners = res.nearby_practitioners;
            that.pagination.total_entries = res.pagination.total_entries;

            // Collect available practitioners
            var availPracts = [];
            var availPractIds = [];
            var avails = [];
            for (var ia = 0; ia < availabilities.length; ia ++) {
              var avail = availabilities[ia];
              if (availPractIds.indexOf(avail.practitioner.id) === -1) {
                availPractIds.push(avail.practitioner.id);
                availPracts.push(avail.practitioner);
              }

              var lastAppt = avail.appointments[avail.appointments.length - 1];
              if (lastAppt) {
                avail.last_patient = lastAppt.patient;

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
              avails.push(avail);
            }

            that.result.availabilities = avails;
            that.availablePractitioners = availPracts;

            // Map data
            var apptMarkers = [];
            var availMarkers = [];

            var circles = [];
            for (var i = 0; i < availabilities.length; i++) {
              var avail = availabilities[i];

              var practColor = that.generatePractitionerColor(avail.practitioner.id);
              // Build appointment marker
              if (that.options.showBookedAppoinments) {
                for (var j = avail.appointments.length - 1; j >= 0; j--) {
                  var appt = avail.appointments[j];
                  var apptMarkerIcon = Object.assign(
                    {
                      fillColor: practColor,
                      strokeColor: practColor
                    },
                    APPT_MARKER_ICON_OPTIONS
                  );

                  var apptMarker = {
                    icon: apptMarkerIcon,
                    appointment_id: appt.id,
                    appointment: appt,
                    position: {
                      lat: appt.patient.latitude,
                      lng: appt.patient.longitude
                    }
                  };

                  apptMarkers.push(apptMarker);
                }
              }

              if (that.options.showAvailabilityArea) {
                if (avail.availability_type_id === 1) { // HomeVisitID
                  // Build availability circle
                  var circleOptions = Object.assign(
                    {
                      strokeColor: practColor,
                      fillColor: practColor
                    },
                    CIRCLE_OPTONS
                  );

                  var circle = {
                    radius: avail.service_radius * 1000,
                    availability_id: avail.id,
                    options: circleOptions
                  };

                  circle.center = {
                    lat: avail.latitude,
                    lng: avail.longitude
                  };

                  circles.push(circle);
                }

                var availMarkerIcon = null;
                // Build availability marker
                if (avail.availability_type_id === 1) { // HomeVisitID
                  availMarkerIcon = Object.assign(
                    {
                      strokeColor: practColor,
                      fillColor: practColor
                    },
                    HOME_VISIT_AVAIL_MARKER_ICON_OPTIONS
                  );
                } else if (avail.availability_type_id === 4) { // FacilityID
                  availMarkerIcon = Object.assign(
                    {
                      strokeColor: practColor,
                      fillColor: practColor
                    },
                    FACILITY_AVAIL_MARKER_ICON_OPTIONS
                  );
                }

                var availMarker = {
                  icon: availMarkerIcon,
                  availability_id: avail.id,
                  availability: avail,
                  position: {
                    lat: avail.latitude,
                    lng: avail.longitude
                  }
                };

                availMarkers.push(availMarker);
              }
            }
            that.availabilityCircles = circles;
            that.availabilityMarkers = availMarkers;
            that.appointmentMarkers = apptMarkers;

            var mapCenter = {};

            // Calculate map center
            if (that.queryLocationMarker.position) {
              mapCenter = that.queryLocationMarker.position;
            } else {
              mapCenter.lat = that.business.latitude;
              mapCenter.lng = that.business.longitude;
            }
            that.mapCenter = mapCenter;
            that.$refs.gmap.$mapObject.setCenter(mapCenter);
            // End map data
          },
          error: function(xhr) {
            Flash.error('Could not load data. Sorry for the inconvenience.');
          },
          complete: function() {
            that.loading = false;
          }
        });
      }
    }
  });
})();
