(function () {
  'use strict';

  Vue.component('modal-appointments-map', {
    template: '#modal-appointments-map-tmpl',

    mixins: [bootstrapModal],

    data: function () {
      return {
        show: false,
        loading: false,
        availability: null,

        selectedApptMarker: null,
        showApptMarkerWindow: false,
        appointmentMarkers: [],

        mapZoom: 11,

        mapCenter: {
          lat: -33.9073417,
          lng: 151.1391135
        },

        mapOptions: {
          gestureHandling: 'greedy',
          streetViewControl: false,
          mapTypeId: 'roadmap',
          maxZoom: 18
        },
      }
    },

    mounted: function () {
      var vm = this;

      CalendarEventBus.$on('availability-view-appointments-map', function (availability) {
        vm.availability = availability;
        vm.appointmentMarkers = [];
        vm.showApptMarkerWindow = false;
        vm.selectedApptMarker = null;

        vm.show = true;

        vm.$nextTick(function () {
          vm.refreshMapComponents();
        });
      });
    },

    methods: {
      onModalClosed: function () {
        this.show = false;
      },

      close: function () {
        this.show = false;
      },

      onApptMarkerClick: function (apptMarker) {
        this.selectedApptMarker = apptMarker;
        this.showApptMarkerWindow = true;
      },

      refreshMapComponents: function () {
        const vm = this;

        //=== Reset markers & bounds
        const apptMarkers = [];
        var bounds = new google.maps.LatLngBounds();

        for (var i = 0, l = vm.availability.appointments.length; i < l; i++) {
          var appt = vm.availability.appointments[i];

          var apptMarker = {
            appointment_id: appt.id,
            appointment: appt,
            label: {
              text: "[" + (appt.order + 1) + "/" + l + "]: " + appt.patient.full_name,
              className: 'appointments-map-marker-label'
            },
            position: {
              lat: appt.patient.latitude,
              lng: appt.patient.longitude
            }
          };

          bounds.extend(new google.maps.LatLng(apptMarker.position.lat, apptMarker.position.lng));

          apptMarkers.push(apptMarker);
        }

        vm.appointmentMarkers = apptMarkers;

        //=== Reset bound & center

        if (vm.availability.appointments.length === 0) {
          vm.$refs.map.$mapObject.setCenter({
            lat: vm.availability.latitude,
            lng: vm.availability.longitude
          });
        } else {
          vm.$refs.map.$mapObject.fitBounds(bounds);
        }

      },
    }
  });
})();
