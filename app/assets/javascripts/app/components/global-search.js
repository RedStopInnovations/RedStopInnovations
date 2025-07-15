$(function() {
  if ($('#js-global-search-container').length) {
    new Vue({
      el: '#js-global-search-container',
      data: {
        searchTarget: 'patient',
        isOpen: false,
        searchQuery: '',
        lastSearchQuery: null,
        isSearching: false,
        patientResults: [],
        contactResults: [],
        invoiceResults: [],
        practitionerResults: [],
        recentVisits: []
      },
      computed: {
        isEmptySearchQuery: function() {
          return this.searchQuery.trim().length === 0;
        },
        searchQueryPlaceholder: function() {
          return {
            'patient': 'Search clients by name',
            'contact': 'Search contacts by name',
            'invoice': 'Search invoices by number or client name',
            'practitioner': 'Search practitioners by name',
          }[this.searchTarget];
        }
      },
      mounted: function() {
        const vm = this;

        document.addEventListener('keyup', function(e) {
          //=== Open search hotkey (/)
          if (e.key === '/' && !(/input|textarea|select/i.test(e.target.nodeName) || e.target.type === "text")) {
            ahoy.track("Open quick search", {tags: "quick search", trigger: 'slash key', referrer: window.location.pathname});
            vm.isOpen = true;
            vm.$nextTick(function() {
              vm.$refs.inputSearchElement.focus();
            });
          }

          //=== Close search hotkey (ESC)
          if (vm.isOpen && (e.key === 'Escape' || e.key === "Esc")) {
            vm.isOpen = false;
          }
        }, false);

        //=== Listen events to open search that trigger from elements outside the component
        document.addEventListener(
          'app.quicksearch.open', function(e) {
            vm.isOpen = true;
            vm.$nextTick(function() {
              vm.$refs.inputSearchElement.focus();
            });
          }
        );

        $(function() {
          $(document).on(
            'click',
            '#js-form-quick-search-header, #js-btn-toggle-quick-search-header-mobile',
            function(e) {
              e.preventDefault();
              ahoy.track("Open quick search", {tags: "quick search", trigger: 'header button', referrer: window.location.pathname});
              document.dispatchEvent(new CustomEvent('app.quicksearch.open'));
            }
          );
        });
      },
      methods: {
        setSearchTarget: function(target) {
          this.searchTarget = target;
          if (!this.isEmptySearchQuery) {
            this.doSearch();
          }

          this.$nextTick(function() {
            this.$refs.inputSearchElement.focus();
          });
        },

        onClickClose: function() {
          this.isOpen = false;
        },

        onClickInputSearch: function() {
          this.isOpen = true;
        },

        onFocusOut: function() {
          if (this.isOpen) {
            this.isOpen = false;
          }
        },

        onClickClearInputSearch: function() {
          this.searchQuery = '';
          this.lastSearchQuery = '';
          const vm = this;
          vm.$nextTick(function() {
            vm.$refs.inputSearchElement.focus();
          });
        },

        onChangeInputSearch: debounce(function() {
          if (this.searchQuery.trim().length > 0) {
            // Workaround focusout input trigger change event
            if (this.searchQuery.trim() !== this.lastSearchQuery) {
              this.isOpen = true;
              this.doSearch();
            }
          }
        }, 300),

        doSearch: function() {
          const vm = this;
          vm.isSearching = true;

          const searchQuery = vm.searchQuery.trim();

          ahoy.track("Search by quick search", {tags: "quick search", query: searchQuery, target: vm.searchTarget, referrer: window.location.pathname});

          if (vm.searchTarget == 'patient') {
            vm.patientResults = [];
            $.ajax({
              method: 'GET',
              url: '/api/patients/search?limit=10&s=' + searchQuery,
              success: function(res) {
                vm.patientResults = res.patients;
                vm.lastSearchQuery = searchQuery;
              },
              complete: function() {
                setTimeout(function() {
                  vm.isSearching = false;
                });
              },
              error: function(xhr) {
                var errMsg = 'An error has occurred while searching for clients.';
                if (xhr.responseJSON && xhr.responseJSON.message) {
                  errMsg += 'Error: ' + xhr.responseJSON.message;
                }
                vm.$notify(errMsg, 'error');
              }
            });
          }

          if (vm.searchTarget == 'contact') {
            vm.contactResults = [];
            vm.isSearching = true;

            $.ajax({
              method: 'GET',
              url: '/api/contacts/search?limit=10&s=' + searchQuery,
              success: function(res) {
                vm.contactResults = res.contacts;
                vm.lastSearchQuery = searchQuery;
              },
              complete: function() {
                setTimeout(function() {
                  vm.isSearching = false;
                });
              },
              error: function() {
                vm.$notify('An error has occurred while searching for contacts.', 'error');
              }
            });
          }

          if (vm.searchTarget == 'invoice') {
            vm.invoiceResults = [];
            vm.isSearching = true;

            $.ajax({
              method: 'GET',
              url: '/api/invoices/search?limit=10&s=' + searchQuery,
              success: function(res) {
                vm.invoiceResults = res.invoices;
                vm.lastSearchQuery = searchQuery;
              },
              complete: function() {
                setTimeout(function() {
                  vm.isSearching = false;
                });
              },
              error: function() {
                vm.$notify('An error has occurred while searching for invoices.', 'error');
              }
            });
          }

          if (vm.searchTarget == 'practitioner') {
            vm.invoiceResults = [];
            vm.isSearching = true;

            $.ajax({
              method: 'GET',
              url: '/api/practitioners/search?limit=10&s=' + searchQuery,
              success: function(res) {
                vm.practitionerResults = res.practitioners;
                vm.lastSearchQuery = searchQuery;
              },
              complete: function() {
                setTimeout(function() {
                  vm.isSearching = false;
                });
              },
              error: function() {
                vm.$notify('An error has occurred while searching for practitioners.', 'error');
              }
            });
          }
        }
      }
    })
  }
});
