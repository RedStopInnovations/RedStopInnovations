(function() {
  // Register Vue components globally
  Vue.component('modal', VueStrap.modal);
  Vue.component('datepicker', VueStrap.datepicker);
  Vue.component('dropdown', VueStrap.dropdown);
  Vue.component('popover', VueStrap.popover);
  Vue.component('v-multiselect', VueMultiselect.Multiselect);
  Vue.component('v-flatpickr', window.VueFlatpickr);
  Vue.component('gmap-map', VueGoogleMaps.Map);
  Vue.component('gmap-marker', VueGoogleMaps.Marker);
  Vue.component('gmap-circle', VueGoogleMaps.Circle);
  Vue.component('gmap-info-window', VueGoogleMaps.InfoWindow);
  Vue.use(ColorPanel);
  Vue.use(ColorPicker);
})();
