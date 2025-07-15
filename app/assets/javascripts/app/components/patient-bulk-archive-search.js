(function() {
  Vue.component('patient-bulk-archive-search', {
    template: '#patient-bulk-archive-search-tmpl',
    data: function() {
      return {
        isSearchingContacts: false,
        isShowModalCreateRequest: false,
        isSubmittingBulkArchiveRequest: false,
        contactOptions: [],
        filter: {
          selectedContact: null,
          contact_id: null,
          create_date_to: null,
          create_date_from: null,
          no_invoice_period: null,
          no_appointment_period: null,
          no_treatment_note_period: null,
        },
        loading: false,
        result: {
          patients: []
        },
        pagination: {
          total_entries: 0,
          page: 1,
          per_page: 25,
          paginator_options: {
            previousText: 'Prev',
            nextText: 'Next'
          }
        },
        createdDateFromDatepickerFilterConfig: {
          altFormat: 'd M Y',
          altInput: true,
          dateFormat: 'Y-m-d',
          allowInput: true,
          disableMobile: true,
          defaultDate: null
        },
        createdDateToDatepickerFilterConfig: {
          altFormat: 'd M Y',
          altInput: true,
          dateFormat: 'Y-m-d',
          allowInput: true,
          disableMobile: true,
          defaultDate: null
        },
        bulkRequestDescription: null
      }
    },

    mounted: function() {
      this.loadPatients();
    },

    filters: {
      humanizePeriod: function(period) {
        return {
          'ALL': 'All the time',
          '6m': '6 months',
          '9m': '9 months',
          '1y': '1 year',
          '2y': '2 years',
          '3y': '3 years',
        }[period];
      }
    },

    computed: {
      isNoFilters: function() {
        return !this.filter.contact_id &&
          !this.filter.create_date_to &&
          !this.filter.create_date_from &&
          !this.filter.no_invoice_period &&
          !this.filter.no_appointment_period &&
          !this.filter.no_treatment_note_period;
      }
    },

    methods: {
      buildSearchParams: function() {
        var params = {
          contact_id: this.filter.contact_id,
          create_date_to: this.filter.create_date_to,
          create_date_from: this.filter.create_date_from,
          no_invoice_period: this.filter.no_invoice_period,
          no_appointment_period: this.filter.no_appointment_period,
          no_treatment_note_period: this.filter.no_treatment_note_period,
          page: this.pagination.page,
          per_page: this.pagination.per_page
        };

        return params;
      },

      onSearchContactChanged: debounce(function(query) {
        var vm = this;

        if (query.trim().length > 0) {
          vm.isSearchingContacts = true;
          $.ajax({
            method: 'GET',
            url: '/api/contacts/search?s=' + query,
            success: function(res) {
              vm.contactOptions = [];
              vm.contactOptions = res.contacts;
            },
            complete: function() {
              vm.isSearchingContacts = false;
            }
          });
        }
      }, 300),

      onContactChanged: function(contact) {
        this.pagination.page = 1;

        if (contact) {
          this.filter.contact_id = contact.id;
        } else {
          this.filter.contact_id = null;
        }

        this.loadPatients();
      },

      onCreateDateFromChanged: function() {
        this.pagination.page = 1;
        this.loadPatients();
      },

      onCreateDateToChanged: function() {
        this.pagination.page = 1;
        this.loadPatients();
      },

      onPageChanged: function(page) {
        this.pagination.page = page;
        this.loadPatients();
      },

      onClickSubmitSearch: function() {
        this.pagination.page = 1;
        this.loadPatients();
      },

      onClickCreateBulkArchiveRequest: function() {
        this.isShowModalCreateRequest = true;
      },

      buildCreateBulkArchiveRequestParams: function() {
        var params = {
          contact_id: this.filter.contact_id,
          create_date_to: this.filter.create_date_to,
          create_date_from: this.filter.create_date_from,
          no_invoice_period: this.filter.no_invoice_period,
          no_appointment_period: this.filter.no_appointment_period,
          no_treatment_note_period: this.filter.no_treatment_note_period,
          description: this.bulkRequestDescription
        };

        return params;
      },

      onClickSubmitBulkArchiveRequest: function() {
        if (!confirm('This action could not be undone. Are you sure you want to process?')) {
          return;
        }

        const vm = this;

        $.ajax({
          method: 'POST',
          url: '/app/patient_bulk_archive/create_request',
          dataType: 'json',
          contentType: 'application/json',
          data: JSON.stringify(vm.buildCreateBulkArchiveRequestParams()),
          beforeSend: function() {
            vm.isSubmittingBulkArchiveRequest = true;
          },
          success: function(res) {
            vm.isShowModalCreateRequest = false;
            vm.isSubmittingBulkArchiveRequest = false;
            vm.$notify('The request has been successfully created.', 'success');
            location.href = '/app/patient_bulk_archive/requests';
          },
          error: function(xhr) {
            vm.loading = false;

            var errorMsg = 'An error has occurred.';

            if (xhr.responseJSON && xhr.responseJSON.message) {
              errorMsg = xhr.responseJSON.message;
            }

            if (xhr.responseJSON) {
              if (xhr.status === 422 && xhr.responseJSON.errors) {
                errorMsg += ' ' + xhr.responseJSON.errors.join('. ');
              }
            }

            vm.$notify(errorMsg, 'error');
            vm.isSubmittingBulkArchiveRequest = false;
          }
        });
      },

      onClickArchive: function(patient) {
        var vm = this;
        if (confirm('Are you sure you want to archive this client?')) {
          $.ajax({
            method: 'PUT',
            url: '/app/patients/' + patient.id + '/archive',
            dataType: 'json',
            success: function(res) {
              vm.loading = false;
              vm.loadPatients();
              vm.$notify('The client has been successfully archived.', 'success');
            },
            error: function(xhr) {
              vm.loading = false;

              if (xhr && xhr.responseJSON && xhr.responseJSON.message) {
                vm.$notify(xhr.responseJSON.message, 'error');
              } else {
                vm.$notify('Failed to archive the client. Sorry for the inconvenience.', 'error');
              }
            }
          });
        }
      },

      loadPatients: function() {
        if (this.isNoFilters) {
          return;
        }

        var vm = this;
        vm.loading = true;

        $.ajax({
          method: 'GET',
          url: '/app/patient_bulk_archive/search',
          data: vm.buildSearchParams(),
          success: function(res) {
            vm.loading = false;
            vm.result.patients = res.patients;
            vm.pagination.total_entries = res.pagination.total_entries;
            vm.$nextTick(function() {
              window.scrollTo(0, 0);
            });
          },
          error: function(xhr) {
            vm.loading = false;
          }
        });
      }
    }
  });
})();