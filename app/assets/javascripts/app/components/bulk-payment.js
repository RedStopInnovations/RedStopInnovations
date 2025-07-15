$(function () {
  if ($('#js-bulk-payment-container').length) {
    new Vue({
      el: '#js-bulk-payment-container',

      data: function () {
        return {
          loading: false,
          payments: [],
          invoiceOptions: [],
          isSearchingInvoices: false,
          isComplete: false,
          PAYMENT_METHODS: [
            'Direct deposit',
            'Cash',
            'Cheque',
            'Workcover',
            'Other',
          ],
          DEFAULT_PAYMENT_METHOD: 'Direct deposit',
          paymentDateDatepickerConfig: {
            altInput: true,
            altFormat: 'd M Y',
            dateFormat: 'Y-m-d',
            firstDayOfWeek: 1,
            altInputClass: 'form-control bg-white form-control-sm'
          }
        }
      },

      computed: {
        totalInvoicesAmount: function () {
          let total = 0;
          for (let i = this.payments.length - 1; i >= 0; i--) {
            total += parseFloat(this.payments[i].invoice.amount);
          }
          return total;
        },

        isFormValid: function() {
          return this.payments.length > 0;
        }
      },

      mounted: function () {
        const vm = this;
      },

      methods: {
        addInvoice: function (selectedInvoice) {
          const vm = this;

          // Check if already added
          for (let i = vm.payments.length - 1; i >= 0; i--) {
            if (vm.payments[i].invoice.id === selectedInvoice.id) {
              vm.$notify('The invoice number ' + selectedInvoice.invoice_number + ' was already added', 'error');
              return;
            }
          }

          vm.payments.push({
            invoice: selectedInvoice,
            payment_date: moment().format('YYYY-MM-DD'),
            payment_method: vm.DEFAULT_PAYMENT_METHOD
          });

          // Remove the selected invoice from search results
          for (let j = 0; j <= vm.invoiceOptions.length - 1; j++) {
            if (vm.invoiceOptions[j].id === selectedInvoice.id) {
              vm.invoiceOptions.splice(j, 1);
            }
          }
        },
        onClickRemoveInvoice: function (invoiceIndex) {
          this.payments.splice(invoiceIndex, 1);
        },
        onSelectInvoice: function (invoice) {
          this.addInvoice(invoice);
          this.$nextTick(function() {
            this.$refs.searchInvoice.$el.focus();
          });
        },
        onSearchInvoiceChanged: debounce(function (query) {
          const vm = this;

          if (query.trim().length > 0) {
            vm.isSearchingInvoices = true;
            $.ajax({
              method: 'GET',
              url: '/api/invoices/outstanding_search?s=' + query,
              success: function (res) {
                vm.invoiceOptions = res.invoices;
              },
              complete: function () {
                vm.isSearchingInvoices = false;
              }
            });
          }
        }, 300),

        onClickSubmitPayments: function() {
          if (this.loading) {
            return;
          } else {
            if (confirm('Are you sure you want to create payments?')) {
              this.submitPayments();
            }
          }
        },

        buildSubmitPaymentsData: function() {
          const data = {
            payments: []
          };

          for (let i = 0; i <= this.payments.length - 1; i++) {
            const payment = this.payments[i];
            data.payments.push({
              invoice_id: payment.invoice.id,
              payment_method: payment.payment_method,
              payment_date: payment.payment_date,
            });
          }

          return data;
        },

        submitPayments: function() {
          const vm = this;

          $.ajax({
            url: '/app/payments/bulk_create',
            method: 'POST',
            data: JSON.stringify(vm.buildSubmitPaymentsData()),
            contentType: 'application/json',
            dataType: 'json',
            beforeSend: function() {
              vm.loading = true;
            },
            success: function(res) {
              const createdPayments = res.payments;

              vm.$notify('The payments has been successfully created.');

              createdPayments.forEach(function(createdPayment) {
                const paidForInvoiceId = createdPayment.payment_allocations[0].invoice_id;

                for (let i = 0; i <= vm.payments.length - 1; i++) {
                  if (vm.payments[i].invoice.id === paidForInvoiceId) {
                    vm.payments[i].created_payment = createdPayment;
                  }
                }
              });

              vm.isComplete = true;
            },
            error: function(xhr) {
              let msg = 'An error has occurred. Sorry for the inconvenience.';

              if (xhr.responseJSON && xhr.responseJSON.message) {
                msg = xhr.responseJSON.message;
              }

              if (xhr.status === 422 && xhr.responseJSON.errors.length > 0) {
                msg += ' ' + xhr.responseJSON.errors.join(', ');
              }

              vm.$notify(msg, 'error');
            },
            complete: function() {
              vm.loading = false;
            }
          })
        }
      }
    })
  }
});
