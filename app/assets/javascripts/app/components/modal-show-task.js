(function () {
  'use strict';

  Vue.component('modal-show-task', {
    template: '#modal-show-task-tmpl',
    mixins: [bootstrapModal],
    data: function () {
      return {
        show: false,
        task: null
      }
    },
    mounted: function () {
      var self = this;

      CalendarEventBus.$on('task-show', function (task) {
        self.resetData();
        self.fetchAndShow(task.id);
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
        this.task = null;
      },
      onClickViewPatient: function() {
        CalendarEventBus.$emit('patient-show', this.task.patient);
      },
      fetchAndShow: function (taskId) {
        var self = this;

        $.ajax({
          method: 'GET',
          url: '/api/tasks/' + taskId + '.json',
          success: function (res) {
            if (res.task) {
              self.task = res.task;
            } else {
              self.$notify('Cannot load task info. An error has occured.', 'error');
            }
            self.show = true;
          },
          error: function(xhr) {
            if (xhr.status == 404) {
              self.$notify('The task does not exist!', 'error');
            } else {
              self.$notify('Cannot load task info. An error has occured.', 'error');
            }
          },
          complete: function() {
            self.show = true;
          }
        });
      }
    }
  });
})();
