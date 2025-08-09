// TODO: implement inactivity/idle timeout to stop auto-refreshing conversations
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
        },
        conversationsRefreshInterval: null,
        unreadCounterRefreshInterval: null,
        replyMessage: '',
        sendingMessage: false
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

          // For messages older than 24 hours, show date and time
          const options = {
            year: 'numeric',
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
            hour12: true
          };

          return date.toLocaleDateString('en-US', options);
        }
      },
      computed: {
      },
      mounted: function() {
        const vm = this;

        $(document).on(
          'click',
          '[js-conversations-sidebar-toggle]',
          function(e) {
              e.preventDefault();
              e.stopPropagation();
              vm.isOpen = true;
              vm.loadConversations();
              vm.startConversationsRefresh();
          }
        );

        // Listen for patient conversation button clicks
        $(document).on(
          'click',
          '[js-btn-start-patient-conversation]',
          function(e) {
              e.preventDefault();
              e.stopPropagation();

              const patientId = $(this).data('patient-id');
              const patientName = $(this).data('patient-name');
              const patientMobile = $(this).data('patient-mobile');

              if (patientMobile === undefined || patientMobile === null) {
                vm.$notify('The clint mobile number is not present or invalid', 'error');
              } else {
                vm.openPatientConversation({
                  patient_id: patientId,
                  patient_name: patientName,
                  patient_mobile: patientMobile
                });
              }
          }
        );

        // Start badge counter refresh immediately when component mounts
        vm.startUnreadCounterRefresh();
      },
      beforeDestroy: function() {
        this.stopAutoRefreshConversations();
        this.stopAutoRefreshUnreadCounter();
      },
      methods: {

        onClickClose: function() {
            this.isOpen = false;
            this.selectedConversation = null;
            this.resetPagination();
            this.stopAutoRefreshConversations(); // Only stop conversations refresh, keep badge counter running
        },

        onFocusOut: function() {
            const vm = this;
            // Add a small delay to prevent conflict with conversation selection
            if (vm.isOpen) {
                setTimeout(function() {
                    vm.isOpen = false;
                    vm.selectedConversation = null;
                    vm.resetPagination();
                    vm.stopAutoRefreshConversations(); // Only stop conversations refresh, keep badge counter running
                }, 150);
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
          this.loadConversationMessages(conversation.patient_id);

          // Force mark conversation as read if it has any unread messages long time ago
          this.markConversationAsRead(conversation.patient_id);
        },

        loadConversationMessages: function(patientId, page = 1) {
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
              console.error('Failed to load messages:', xhr);
              vm.$notify && vm.$notify('Failed to load messages', 'error');
            },
            complete: function() {
              vm.messagesLoading = false;
            }
          });
        },

        loadMoreMessages: function() {
          if (this.messagesPagination.current_page < this.messagesPagination.total_pages && !this.messagesLoading) {
            this.loadConversationMessages(this.selectedConversation.patient_id, this.messagesPagination.current_page + 1);
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
          this.replyMessage = '';

          // Refresh conversations list to show latest updates
          this.loadConversations();
        },

        formatMessagePreview: function(message) {
          if (!message) return '';
          return message.length > 50 ? message.substring(0, 50) + '...' : message;
        },

        startConversationsRefresh: function() {
          const vm = this;

          // Stop any existing conversations refresh interval
          if (vm.conversationsRefreshInterval) {
            clearInterval(vm.conversationsRefreshInterval);
          }

          // Auto-refresh conversations or individual conversation messages when sidebar is open
          vm.conversationsRefreshInterval = setInterval(function() {
            if (vm.isOpen) {
              if (!vm.selectedConversation) {
                // Refresh conversations list when on conversations view
                vm.refreshConversations();
              } else {
                // Refresh individual conversation messages when viewing a conversation
                vm.refreshSelectedConversationMessages();
              }
            }
          }, 10000); // 10 seconds
        },

        startUnreadCounterRefresh: function() {
          const vm = this;

          // Stop any existing badge refresh interval
          if (vm.unreadCounterRefreshInterval) {
            clearInterval(vm.unreadCounterRefreshInterval);
          }

          // Always refresh badge counter (even when sidebar is closed)
          vm.unreadCounterRefreshInterval = setInterval(function() {
            vm.refreshUnreadBadgeCounter();
          }, 10000);

          // Initial badge counter load
          vm.refreshUnreadBadgeCounter();
        },

        stopAutoRefreshConversations: function() {
          if (this.conversationsRefreshInterval) {
            clearInterval(this.conversationsRefreshInterval);
            this.conversationsRefreshInterval = null;
          }
        },

        stopAutoRefreshUnreadCounter: function() {
          if (this.unreadCounterRefreshInterval) {
            clearInterval(this.unreadCounterRefreshInterval);
            this.unreadCounterRefreshInterval = null;
          }
        },

        refreshConversations: function() {
          const vm = this;
          if (vm.loading) return;

          // Silently refresh conversations without showing loading state
          $.ajax({
            url: '/api/communications/sms_conversations',
            method: 'GET',
            data: {
              page: 1,
            },
            success: function(response) {
              // Only update if we got new data to avoid unnecessary re-renders
              if (JSON.stringify(vm.conversations) !== JSON.stringify(response.conversations)) {
                vm.conversations = response.conversations;
                vm.pagination = response.pagination;
              }
            },
            error: function(xhr) {
              console.error('Failed to refresh conversations:', xhr);
              // Silently fail - don't show error to user for background refresh
            }
          });
        },

        refreshSelectedConversationMessages: function() {
          const vm = this;
          if (vm.messagesLoading || !vm.selectedConversation) return;

          // Get the current scroll position
          const messagesContainer = document.querySelector('#js-conversations-sidebar .messages-container');
          const scrollTop = messagesContainer ? messagesContainer.scrollTop : 0;
          const scrollHeight = messagesContainer ? messagesContainer.scrollHeight : 0;
          const isAtBottom = Math.abs(scrollHeight - scrollTop - messagesContainer.clientHeight) < 5;

          // Silently refresh messages without showing loading state
          $.ajax({
            url: '/api/communications/patient_sms_conversations/' + vm.selectedConversation.patient_id,
            method: 'GET',
            data: {
              page: 1,
            },
            success: function(response) {
              // Check if we have new messages
              const newMessages = response.messages.reverse();
              const currentMessageIds = vm.conversationMessages.map(msg => msg.id);
              const newMessageIds = newMessages.map(msg => msg.id);

              // Only update if there are actually new messages
              if (JSON.stringify(currentMessageIds) !== JSON.stringify(newMessageIds)) {
                vm.conversationMessages = newMessages;

                // If user was at bottom, scroll to bottom to show new messages
                // If they were scrolled up, keep their position
                vm.$nextTick(function() {
                  if (isAtBottom) {
                    vm.scrollToBottom();
                  }
                });

                vm.markConversationAsRead(vm.selectedConversation.patient_id);
              }
            },
            error: function(xhr) {
              console.error('Failed to refresh conversation messages:', xhr);
              // Silently fail - don't show error to user for background refresh
            }
          });
        },

        refreshUnreadBadgeCounter: function() {
          const vm = this;

          $.ajax({
            url: '/api/communications/sms_conversations/unread_count',
            method: 'GET',
            success: function(response) {
                const badgeElement = $('[js-unread-conversations-counter]');
                const count = response.count;
                if (badgeElement.length) {
                    badgeElement.text(count || 0);

                    // Hide badge if count is 0
                    if (count === 0 || count === null || count === undefined) {
                        badgeElement.hide();
                    } else {
                        badgeElement.show();
                    }
                }
            },
            error: function(xhr) {
              console.error('Failed to refresh badge counter:', xhr);
              // Silently fail - don't show error to user for background refresh
            }
          });
        },

        sendReplyMessage: function() {
          const vm = this;
          if (!vm.replyMessage.trim() || vm.sendingMessage || !vm.selectedConversation) return;

          vm.sendingMessage = true;

          $.ajax({
            url: '/api/communications/patient_sms_conversations/' + vm.selectedConversation.patient_id + '/send_message',
            method: 'POST',
            data: {
              message: vm.replyMessage.trim(),
              _token: $('meta[name="csrf-token"]').attr('content')
            },
            success: function(response) {
              // Clear the input
              vm.replyMessage = '';

              // Add the new message to the conversation
              const newMessage = {
                id: response.message_id || Date.now(), // Use response ID or timestamp as fallback
                message: response.message,
                direction: 'Outbound',
                created_at: response.created_at || new Date().toISOString(),
                from: response.from || 'You'
              };

              // Add to the end of messages (newest at bottom)
              vm.conversationMessages.push(newMessage);

              // Scroll to bottom to show new message
              vm.$nextTick(function() {
                vm.scrollToBottom();
              });
            },
            error: function(xhr) {
              console.error('Failed to send message:', xhr);
              let errorMessage = 'Failed to send message';

              if (xhr.responseJSON && xhr.responseJSON.message) {
                errorMessage = xhr.responseJSON.message;
              } else if (xhr.responseJSON && xhr.responseJSON.errors) {
                errorMessage = xhr.responseJSON.errors.join(', ');
              }

              // Show error to user
              alert('Error: ' + errorMessage);
            },
            complete: function() {
              vm.sendingMessage = false;
            }
          });
        },

        handleEnterKeyOnReplyInput: function(event) {
          if (event.metaKey || event.ctrlKey) {
            // Send message on Cmd+Enter (Mac) or Ctrl+Enter (Windows/Linux)
            this.sendReplyMessage();
          }
          // Allow Enter alone for new line
        },

        markConversationAsRead: function(patientId) {
          const vm = this;

          $.ajax({
            url: '/api/communications/patient_sms_conversations/' + patientId + '/mark_as_read',
            method: 'POST',
            data: {
              _token: $('meta[name="csrf-token"]').attr('content')
            },
            success: function(response) {
              // Update the conversation in the list to remove unread status
              const conversation = vm.conversations.find(conv => conv.patient_id === patientId);
              if (conversation) {
                conversation.read = true;
              }

              // Refresh badge counter immediately after marking as read
              vm.refreshUnreadBadgeCounter();
            },
            error: function(xhr) {
              console.error('Failed to mark conversation as read:', xhr);
              // Silently fail - don't disrupt user experience
            }
          });
        },

        openPatientConversation: function(patientData) {
          const vm = this;

          // Set the selected conversation
          vm.selectedConversation = {
            patient_id: patientData.patient_id,
            patient_name: patientData.patient_name,
            patient_mobile: patientData.patient_mobile
          };

          vm.markConversationAsRead(patientData.patient_id);

          // Open the sidebar
          vm.isOpen = true;

          // Load messages for this patient (might be empty for new conversations)
          vm.loadConversationMessages(patientData.patient_id);

          // Stop conversations refresh and start conversation-specific refresh
          vm.stopAutoRefreshConversations();
          vm.startConversationsRefresh();
        },
      }
    })
  }
});
