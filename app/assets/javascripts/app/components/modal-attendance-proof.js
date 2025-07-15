(function() {
  'use strict';

  Vue.component('modal-attendance-proof', {
    template: '#modal-attendance-proof-tmpl',

    mixins: [bootstrapModal],

    data: function() {
      return {
        show: false,
        loading: false,
        uploadedItems: [],
        appointment: null,
        selectedFile: null
      }
    },

    mounted: function () {
      var vm = this;

      CalendarEventBus.$on('appointment-attendance-proof', function (appointment) {
        vm.appointment = appointment;
        vm.uploadedItems = [];
        vm.show = true;
        vm.clearSelectedFile();
        vm.loadProofs();
      });
    },

    methods: {
      onModalClosed: function() {
        this.show = false;
      },

      close: function() {
        this.show = false;
      },

      clearSelectedFile: function() {
        this.$refs.inputFile.value = '';
        this.selectedFile = null;
      },

      onClickUpload: function() {
        var vm = this;
        if (!vm.selectedFile) {
          vm.$notify('No file is selected.', 'warning');
        }
        var formData = new FormData;
        formData.append('file', vm.selectedFile);

        vm.loading = true;
        $.ajax({
          method: 'POST',
          url: '/api/appointments/' + vm.appointment.id + '/attendance_proofs',
          cache: false,
          contentType: false,
          processData: false,
          data: formData,
          success: function(res) {
            vm.loading = false;
            vm.clearSelectedFile();
            vm.$notify('The file was successfully uploaded.', 'success');
            vm.loadProofs();
          },
          error: function(xhr) {
            vm.loading = false;
            if (xhr.responseJSON && xhr.responseJSON.message) {
              vm.$notify(xhr.responseJSON.message, 'error');
            } else {
              vm.$notify('Failed to upload file. Sorry for the inconvenience.', 'error');
            }
          }
        });
      },

      onFileInputChange: function(e) {
        var files = e.target.files || e.dataTransfer.files;
        if (files.length > 0) {
          this.selectedFile = files[0];
        } else {
          this.selectedFile = null;
        }
      },

      onClickDeleteItem: function(item) {
        if (!confirm('Are you sure you want to delete this file?')) {
          return;
        }

        var vm = this;
        vm.loading = true;
        $.ajax({
          method: 'DELETE',
          url: '/api/appointments/' + vm.appointment.id + '/attendance_proofs/' + item.id,
          success: function(res) {
            vm.loading = false;
            vm.$notify('The file was successfully deleted.', 'success');
            vm.loadProofs();
          },
          error: function(xhr) {
            vm.loading = false;

            if (xhr.responseJSON && xhr.responseJSON.message) {
              vm.$notify(xhr.responseJSON.message, 'error');
            } else {
              vm.$notify('Failed to delete file. Sorry for the inconvenience.', 'error');
            }
          }
        });
      },

      loadProofs: function() {
        var vm = this;
        vm.loading = true;

        $.ajax({
          method: 'GET',
          url: '/api/appointments/' + vm.appointment.id + '/attendance_proofs',
          success: function(res) {
            vm.uploadedItems = res.attendance_proofs;
            vm.loading = false;
          },
          error: function(xhr) {
            vm.loading = false;
            vm.$notify('Failed to fetch uploaded files.', 'error');
          }
        });
      }
    }
  });
})();
