(function() {
  'use strict';

  Vue.component('calendar-mobile-header', {
    template: '#calendar-mobile-header-tmpl',
    data: function() {
      return {
        currentView: null,
        canEditAppearanceSettings: false
      };
    },
    props: {
      dateTitle: {
        type: String,
        required: true
      },
      view: {
        type: String,
        required: true
      }
    },
    computed: {
      isRestrictedPractitionerRole: function() {
        return App.user && (App.user.role == App.CONSTANTS.USER.ROLE_RESTRICTED_PRACTITIONER);
      }
    },
    watch: {
      view: function(val) {
        return this.currentView = this.view;
      }
    },
    mounted: function() {
      this.currentView = this.view;
      this.canEditAppearanceSettings = App.user.role == App.CONSTANTS.USER.ROLE_ADMINISTRATOR;
    },
    methods: {
      prev: function() {
        this.$emit('prev');
      },
      next: function() {
        this.$emit('next');
      },
      today: function() {
        this.$emit('today');
      },
      onViewChanged: function() {
        this.$emit('view-changed', this.currentView);
      },
      appointmentAdd: function() {
        CalendarEventBus.$emit('appointment-add');
      },
      waitListShow: function() {
        this.$emit('waiting-list-show');
      },
      showCalendarAppearanceSettings: function() {
        CalendarEventBus.$emit('calendar-appearance-settings.show');
      }
    }
  });
})();
