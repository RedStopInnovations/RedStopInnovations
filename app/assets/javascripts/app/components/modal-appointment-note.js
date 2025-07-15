(function() {
  'use strict';

  Vue.component('modal-appointment-note', {
    template: '#modal-appointment-note-tmpl',
    mixins: [bootstrapModal],
    data: function() {
      return {
        show: false,
        notes: ''
      }
    },
    mounted: function() {
      var self = this;

      CalendarEventBus.$on('appointment-note-show', function(appointment) {
        self.showNote(appointment.notes);
      });

    },
    methods: {
      showNote: function(notes) {
        this.notes = notes;
        this.show = true;
      },
      close: function() {
        this.show = false;
      },
      onModalClosed: function() {
        this.show = false;
      }
    }
  });

})();
