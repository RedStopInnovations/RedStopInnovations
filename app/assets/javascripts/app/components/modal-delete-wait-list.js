(function() {
  'use strict';
  Vue.component('modal-delete-wait-list', {
    template: '#modal-delete-wait-list-tmpl',
    mixins: [bootstrapModal],
    props: {
      business: {
        type: Object,
        required: true
      }
    },
    data: function() {
      return {
        show: false,
        loading: false,
        waitList: null,
        deletion: {
          delete_repeats: false,
        }
      }
    },
    mounted: function() {
      var self = this;
      CalendarEventBus.$on('waitlist-delete', function(waitList) {
        self.waitList = waitList;
        self.deletion.delete_repeats = false;
        self.showModal();
      });
    },
    methods: {
      onModalClosed: function() {
        this.show = false;
      },
      showModal: function() {
        this.show = true;
      },
      cancel: function() {
        this.show = false;
      },
      buildDeletionData: function() {
        return {
          delete_repeats: this.deletion.delete_repeats
        };
      },
      confirm: function() {
        var self = this;
        $.ajax({
          method: 'DELETE',
          url: '/api/wait_lists/' + self.waitList.id,
          contentType: 'application/json',
          data: JSON.stringify(self.buildDeletionData()),
          beforeSend: function() {
            self.loading = true;
          },
          success: function(res) {
            self.show = false;
            self.$notify('An entry has been removed from the waiting list.');
            CalendarEventBus.$emit('waitlist-deleted', self.waitList);
          },
          error: function(xhr) {
            self.$notify('An error has occurred. Sorry for the inconvenience.');
          },
          complete: function() {
            self.loading = false;
          }
        });
      }
    }
  });
})();
