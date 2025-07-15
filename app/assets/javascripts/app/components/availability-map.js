(function() {
  'use strict';

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

  var MAX_PRACTITIONERS = 10;

  var APPT_MARKER_ICON_OPTIONS = {
    path: 'M16 0c-5.523 0-10 4.477-10 10 0 10 10 22 10 22s10-12 10-22c0-5.523-4.477-10-10-10zM16 16c-3.314 0-6-2.686-6-6s2.686-6 6-6 6 2.686 6 6-2.686 6-6 6z',
    fillOpacity: 1,
    scale: 0.8,
    strokeWeight: 1
  };

  var AVAIL_MARKER_ICON_OPTIONS = {
    path: 'M17.659,9.597h-1.224c-0.199-3.235-2.797-5.833-6.032-6.033V2.341c0-0.222-0.182-0.403-0.403-0.403S9.597,2.119,9.597,2.341v1.223c-3.235,0.2-5.833,2.798-6.033,6.033H2.341c-0.222,0-0.403,0.182-0.403,0.403s0.182,0.403,0.403,0.403h1.223c0.2,3.235,2.798,5.833,6.033,6.032v1.224c0,0.222,0.182,0.403,0.403,0.403s0.403-0.182,0.403-0.403v-1.224c3.235-0.199,5.833-2.797,6.032-6.032h1.224c0.222,0,0.403-0.182,0.403-0.403S17.881,9.597,17.659,9.597 M14.435,10.403h1.193c-0.198,2.791-2.434,5.026-5.225,5.225v-1.193c0-0.222-0.182-0.403-0.403-0.403s-0.403,0.182-0.403,0.403v1.193c-2.792-0.198-5.027-2.434-5.224-5.225h1.193c0.222,0,0.403-0.182,0.403-0.403S5.787,9.597,5.565,9.597H4.373C4.57,6.805,6.805,4.57,9.597,4.373v1.193c0,0.222,0.182,0.403,0.403,0.403s0.403-0.182,0.403-0.403V4.373c2.791,0.197,5.026,2.433,5.225,5.224h-1.193c-0.222,0-0.403,0.182-0.403,0.403S14.213,10.403,14.435,10.403',
    fillOpacity: 1,
    scale: 1.5,
    strokeWeight: 1
  };

  var CIRCLE_OPTONS = {
    strokeOpacity: 1,
    strokeWeight: 1,
    fillOpacity: 0.1
  };

  var MOUSE_HOVER_DELAY = 700;

  Vue.component('availability-map', {
    template: '#availability-map-tmpl',
    data: function() {
      return {
        mapZoom: 11,
        mapCenter: {
          lat: -33.9073417,
          lng: 151.1391135
        },
        business: null,
        loading: true,
        selectedApptMarker: null,
        selectedAvailMarker: null,
        showApptMarkerWindow: false,
        showAvailMarkerWindow: false,
        lastDateRange: this.initalDateRange(),
        practitionerFilterOptions: [],
        selectedPractitioners: [],
        filters: {
          dateRange: this.initalDateRange()
        },
        options: {
          showAvailabilityArea: true,
          showCompletedAppoinments: true,
        },
        datepickerConfig: {
          mode: 'range',
          enableTime: false,
          altInput: true,
          altFormat: 'd M Y',
          dateFormat: 'Y-m-d',
          firstDayOfWeek: 1,
          altInputClass: 'form-control'
        },
        mapOptions: {
          gestureHandling: 'greedy',
          streetViewControl: false,
          mapTypeId: 'roadmap'
        },
        availabilityMarkers: [],
        appointmentMarkers: [],
        availabilityCircles: []
      };
    },
    created: function() {
      this.apptMarkerMouseHoverTimeout = null;
      this.availMarkerMouseHoverTimeout = null;
    },
    computed: {
      selectedPractitionersCount: function() {
        return this.selectedPractitioners.length;
      },
      practitionersCount: function() {
        return this.business.practitioners.length;
      },
      selectedPractitionerIds: function() {
        return this.selectedPractitioners.map(function(pract) {
          return pract.id;
        });
      }
    },
    mounted: function() {
      var that = this;
      $(document).keyup(function(e) {
        if (e.keyCode == 27) {
          that.showApptMarkerWindow = false;
          that.showAvailMarkerWindow = false;
        }
      });
    },
    methods: {
      setBusiness: function(business, practitionerIds) {
        var previousBusiness = this.business;
        this.business = business;
        this.selectedPractitioners = [];

        var preSelectedPractitionerIds = [];

        if (practitionerIds && practitionerIds.length) {
          preSelectedPractitionerIds = practitionerIds;
        }

        this.selectedPractitioners = [];
        for (var i = business.practitioners.length - 1; i >= 0; i--) {
          var pract = business.practitioners[i];
          if (preSelectedPractitionerIds.indexOf(pract.id) !== -1) {
            this.selectedPractitioners.push(pract);
          }
        }
        this.updatePractitionerFilterOptions();
        this.loadMapData();
      },
      generatePractitionerColor: function(id) {
        var key = '' + id + '';
        var practIdx = 0;
        for (var i = 0, pl = this.selectedPractitioners.length; i < pl; i++) {
          if (this.selectedPractitioners[i].id === id) {
            practIdx = i;
            break;
          }
        }

        return COLOR_PALETE[practIdx];
      },
      initalDateRange: function() {
        return [new Date(), moment().day(7).toDate()];
      },
      onDateRangeChange: function(selectedDates, dateStr, instance) {
        if (selectedDates && selectedDates.length === 2) {
          this.lastDateRange = selectedDates;
          this.loadMapData();
        }
      },
      onDateRangePickerClose: function(selectedDates, dateStr, instance) {
        // Check to revert last date range if user only select start date and close the picker
        if (!selectedDates || selectedDates.length == 1) {
          this.filters.dateRange = this.lastDateRange;
        }
      },
      onSelectPractitionerOption: function(option) {
        if (option.type === 'Practitioner') {
          if (this.selectedPractitioners.length >= MAX_PRACTITIONERS) {
            Flash.error('Sorry. Cant display more than ' + MAX_PRACTITIONERS +' practitioners simultaneously.');
          } else {
            this.selectedPractitioners.push(option.value);
            this.updatePractitionerFilterOptions();
            this.onChangedPractitioners();
          }

        } else if (option.type === 'Group') {
          var group = option.value;
          var groupPractitioners = [];
          for (var i = 0; i < this.business.practitioners.length; i++) {
            var pract = this.business.practitioners[i];
            if (group.practitioner_ids.indexOf(pract.id) !== -1) {
              groupPractitioners.push(pract);
            }

            if (groupPractitioners.length === MAX_PRACTITIONERS) {
              break;
            }
          }

          this.selectedPractitioners = groupPractitioners;
          this.updatePractitionerFilterOptions();
          this.onChangedPractitioners();
        }

      },
      removePractitioner: function(practitioner) {
        for (var i = this.selectedPractitioners.length - 1; i >= 0; i--) {
          if (this.selectedPractitioners[i].id == practitioner.id) {
            this.selectedPractitioners.splice(i, 1);
            break;
          }
        }

        this.updatePractitionerFilterOptions();
        this.onChangedPractitioners();
      },
      updatePractitionerFilterOptions: function() {
        var selectedPractIds = this.getSelectedPractitionerIds();
        this.practitionerFilterOptions = this.buildSelectPractitionerOptions(
          this.business,
          selectedPractIds
        );
      },
      getSelectedPractitionerIds: function() {
        var selectedPractIds = [];
        for (var i = this.selectedPractitioners.length - 1; i >= 0; i--) {
          selectedPractIds.push(this.selectedPractitioners[i].id);
        }
        return selectedPractIds;
      },
      buildSelectPractitionerOptions: function(business, excludePractitionerIds) {
        var options = [];

        for (var i = business.groups.length - 1; i >= 0; i--) {
          var group = business.groups[i];
          var groupOption = {
            id: 'group-' + business.groups[i].id,
            type: 'Group',
            value: group,
            label: group.name
          };
          options.push(groupOption);
        }

        for (var j = business.practitioners.length - 1; j >= 0; j--) {
          var pract = business.practitioners[j];
          if (excludePractitionerIds.indexOf(pract.id) == -1) {
            var practOption = {
              id: 'practitioner-' + pract.id,
              type: 'Practitioner',
              value: pract,
              label: pract.full_name
            };
            options.push(practOption);
          }
        }

        return options;
      },
      onChangedPractitioners: function() {
        if (this.selectedPractitionerIds.length === 0) {
          this.appointmentMarkers = [];
          this.availabilityCircles = [];
          this.availabilityMarkers = [];
        } else {
          this.loadMapData();
        }
      },
      buildQueryParams: function() {
        var startDate = moment(this.lastDateRange[0]).format('YYYY-MM-DD');
        var endDate = moment(this.lastDateRange[1]).format('YYYY-MM-DD');
        var query = {
          from_date: startDate,
          to_date: endDate,
          _: (new Date().getTime())
        };

        query.practitioner_ids = this.selectedPractitionerIds;

        return query;
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
        }, MOUSE_HOVER_DELAY);
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
        }, MOUSE_HOVER_DELAY);
      },
      onAvailMarkerMouseOut: function(availMarker) {
        window.clearTimeout(this.availMarkerMouseHoverTimeout);
      },
      onShowAvailabilityAreaChange: function() {
        if (this.options.showAvailabilityArea) {
          this.loadMapData();
        } else {
          this.availabilityCircles = [];
          this.availabilityMarkers = [];
          this.selectedAvailMarker = null;
        }
      },
      onshowCompletedAppoinmentsChange: function() {
        this.loadMapData();
      },
      loadMapData: function() {
        var that = this;
        that.loading = true;

        $.ajax({
          url: '/api/availabilities.json',
          data: that.buildQueryParams(),
          success: function(res) {
            var availabilities = res.availabilities;
            var apptMarkers = [];
            var availMarkers = [];
            var mapBounds = new google.maps.LatLngBounds();

            var circles = [];
            for (var i = 0; i < availabilities.length; i++) {
              var avail = availabilities[i];

              var practColor = that.generatePractitionerColor(avail.practitioner.id);
              // Build appointment marker
              for (var j = avail.appointments.length - 1; j >= 0; j--) {
                var appt = avail.appointments[j];
                if (appt.status == 'completed' && !that.options.showCompletedAppoinments) {
                  continue;
                }
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
                mapBounds.extend(apptMarker.position);
              }

              if (that.options.showAvailabilityArea) {
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

                // Build availability marker(the central dot)
                var availMarkerIcon = Object.assign(
                  {
                    strokeColor: practColor,
                    fillColor: practColor
                  },
                  AVAIL_MARKER_ICON_OPTIONS
                );

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

            var boundsCenter = mapBounds.getCenter();
            var mapCenter = {};

            // Calculate map center
            if (mapBounds.isEmpty()) {
              if (that.selectedPractitioners.length === 0) {
                mapCenter.lat = that.business.latitude;
                mapCenter.lng = that.business.longitude;
              } else {
                // Incase business location is not persite(rare)
                for (var p = that.selectedPractitioners.length - 1; p >= 0; p--) {
                  var pract = that.selectedPractitioners[p];
                  if (pract.latitude && pract.longitude) {
                    mapBounds.extend({
                      lat: pract.latitude,
                      lng: pract.longitude
                    });
                  }
                }
                mapCenter.lat = mapBounds.getCenter().lat();
                mapCenter.lng = mapBounds.getCenter().lng();
              }

            } else {
              mapCenter.lat = boundsCenter.lat();
              mapCenter.lng = boundsCenter.lng();
            }

            that.mapCenter = mapCenter;
          },
          complete: function() {
            that.loading = false;
          },
          error: function() {
            that.$nextTick(function() {
              that.loading = false;
            });
          }
        });
      }
    }
  });

})();
