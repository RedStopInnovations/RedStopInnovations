(function() {
  'use strict';

  Vue.component('modal-appointment-bookings-answers', {
    template: '#modal-appointment-bookings-answers-tmpl',
    mixins: [bootstrapModal],
    data: function() {
      return {
        show: false,
        bookingsAnswers: []
      }
    },
    mounted: function() {
      var self = this;
      CalendarEventBus.$on('appointment-bookings-answers-show', function(appointment) {
        self.showAnswers(appointment.bookings_answers);
      });
    },
    methods: {
      showAnswers: function(bookingsAnswers) {
        this.bookingsAnswers = bookingsAnswers;
        this.show = true;
      },
      close: function() {
        this.show = false;
      },
      onModalClosed: function() {
        this.show = false;
      }
    }
  })
})();
