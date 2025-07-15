(function () {
  'use strict';

  Vue.component('modal-show-practitioner', {
    template: '#modal-show-practitioner-tmpl',
    mixins: [bootstrapModal],
    data: function () {
      return {
        show: false,
        isRestricted: false,
        practitioner: null
      }
    },
    mounted: function () {
      var self = this;

      CalendarEventBus.$on('practitioner-show', function (practitioner) {
        self.resetData();
        self.practitioner = practitioner;
        self.show = true;
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
        this.practitioner = null;
      },
    }
  });
})();