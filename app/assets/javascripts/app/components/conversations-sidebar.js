$(function() {
  if ($('#js-conversations-sidebar').length) {
    new Vue({
      el: '#js-conversations-sidebar',
      data: {
        isOpen: false,
        conversations: [],
        loading: false,
        selectedConversation: null,
        conversationMessages: [],
        messagesLoading: false,
        messagesPagination: {
          current_page: 1,
          total_count: 0,
          total_pages: 0
        },
        pagination: {
          current_page: 1,
          total_count: 0,
          total_pages: 0
        }
      },
      filters: {
        timeAgo: function(dateString) {
          if (!dateString) return '';

          const date = new Date(dateString);
          const now = new Date();
          const diffInSeconds = Math.floor((now - date) / 1000);

          if (diffInSeconds < 60) {
            return 'just now';
          }

          const diffInMinutes = Math.floor(diffInSeconds / 60);
          if (diffInMinutes < 60) {
            return diffInMinutes + 'm ago';
          }

          const diffInHours = Math.floor(diffInMinutes / 60);
          if (diffInHours < 24) {
            return diffInHours + 'h ago';
          }

          const diffInDays = Math.floor(diffInHours / 24);
          if (diffInDays < 7) {
            return diffInDays + 'd ago';
          }

          const diffInWeeks = Math.floor(diffInDays / 7);
          if (diffInWeeks < 4) {
            return diffInWeeks + 'w ago';
          }

          // For older dates, show the actual date
          return date.toLocaleDateString();
        }
      },
      computed: {
      },
      mounted: function() {
        const vm = this;

        //=== Listen events to open search that trigger from elements outside the component
        document.addEventListener(
          'app.conversations-sidebar.open', function(e) {
            vm.isOpen = true;
            vm.loadConversations();
          }
        );

        $(function() {
          $(document).on(
            'click',
            '[js-conversations-sidebar-toggle]',
            function(e) {
              e.preventDefault();
              document.dispatchEvent(new CustomEvent('app.conversations-sidebar.open'));
            }
          );
        });
      },
      methods: {

        onClickClose: function() {
          this.isOpen = false;
          this.selectedConversation = null;
          this.resetPagination();
        },

        onFocusOut: function() {
          if (this.isOpen) {
            this.isOpen = false;
            this.selectedConversation = null;
            this.resetPagination();
          }
        },

        loadConversations: function(page = 1) {
          const vm = this;
          if (vm.loading) return;

          vm.loading = true;

          $.ajax({
            url: '/api/communications/sms_conversations',
            method: 'GET',
            data: {
              page: page,
            },
            success: function(response) {
              if (page === 1) {
                vm.conversations = response.conversations;
              } else {
                vm.conversations = vm.conversations.concat(response.conversations);
              }
              vm.pagination = response.pagination;
            },
            error: function(xhr) {
              console.error('Failed to load conversations:', xhr);
              // You could add error handling here
            },
            complete: function() {
              vm.loading = false;
            }
          });
        },

        loadMoreConversations: function() {
          if (this.pagination.current_page < this.pagination.total_pages && !this.loading) {
            this.loadConversations(this.pagination.current_page + 1);
          }
        },

        resetPagination: function() {
          this.pagination.current_page = 1;
          this.conversations = [];
        },

        onClickConversation: function(conversation) {
          this.selectedConversation = conversation;
          this.loadPatientMessages(conversation.patient_id);
        },

        loadPatientMessages: function(patientId, page = 1) {
          const vm = this;
          if (vm.messagesLoading) return;

          vm.messagesLoading = true;

          $.ajax({
            url: '/api/communications/patient_sms_conversations/' + patientId,
            method: 'GET',
            data: {
              page: page,
            },
            success: function(response) {
              if (page === 1) {
                // Reverse the messages so oldest appear at top, newest at bottom
                vm.conversationMessages = response.messages.reverse();
                // Scroll to bottom for new conversation
                vm.$nextTick(function() {
                  vm.scrollToBottom();
                });
              } else {
                // Prepend older messages to the beginning (reverse them first)
                vm.conversationMessages = response.messages.reverse().concat(vm.conversationMessages);
              }
              vm.messagesPagination = response.pagination;
            },
            error: function(xhr) {
              console.error('Failed to load patient messages:', xhr);
              vm.$notify && vm.$notify('Failed to load messages', 'error');
            },
            complete: function() {
              vm.messagesLoading = false;
            }
          });
        },

        loadMoreMessages: function() {
          if (this.messagesPagination.current_page < this.messagesPagination.total_pages && !this.messagesLoading) {
            this.loadPatientMessages(this.selectedConversation.patient_id, this.messagesPagination.current_page + 1);
          }
        },

        scrollToBottom: function() {
          const messagesContainer = document.querySelector('#js-conversations-sidebar .messages-container');
          if (messagesContainer) {
            messagesContainer.scrollTop = messagesContainer.scrollHeight;
          }
        },

        goBackToConversations: function() {
          this.selectedConversation = null;
          this.conversationMessages = [];
          this.messagesPagination.current_page = 1;
        },

        formatMessagePreview: function(message) {
          if (!message) return '';
          return message.length > 50 ? message.substring(0, 50) + '...' : message;
        }

      }
    })
  }
});
