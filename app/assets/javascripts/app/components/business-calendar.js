(function() {
  var DEFAULT_AVAILABILITY_TYPES_COLORS_MAP = {
    1: '#44b654',
    4: '#3d88ad',
    5: '#8d41c5',
    6: '#cddc39',
  };

  var DEFAULT_TEXT_COLOR = '#FFFFFF';

  Vue.component('business-calendar', {
    template: '#business-calendar-tmpl',
    data: function() {
      var that = this;
      var vm = this;

      return {
        settings: {
          // viewMode: 'availability',
          startDate: new Date(),
          calendarView: 'agendaThreeDay',
          calendarCurrentDateTitle: '',
          timezone: App.timezone
        },
        calendarDatepickerConfig: {
          inline: true,
          enableTime: false,
          onChange: this.onCalendarDatepickerChange,
          firstDayOfWeek: 1
        },
        loading: true,
        sidebarVisible: true,
        business: null,
        availabilities: [],
        currentAvailability: null,
        practitionerFilterOptions: [],
        practitionersBusinessHours: {},
        selectedPractitioners: [],
        resources: [],
        appearanceSettings: {},
        canEditAppearanceSettings: false,
        eventSources: [
          {
            events: function(start, end, timezone, callback) {
              if (that.selectedPractitioners.length === 0) {
                that.loading = false;
                callback([]);
                return;
              }

              var availTypeColorSettings = [];
              if (vm.appearanceSettings.availability_type_colors) {
                availTypeColorSettings = vm.appearanceSettings.availability_type_colors;
              }

              that.loading = true;
              var availabilities = [];
              var events = [];

              $.ajax({
                url: '/api/availabilities.json',
                data: that.buildCalendarQueryParams(start, end, timezone),
                success: function(res) {
                  that.setDateCalendarDatepickers(new Date(start.format('YYYY-MM-DD')));

                  availabilities = res.availabilities;
                  that.availabilities = availabilities;

                  // @see https://fullcalendar.io/docs/event_data/Event_Object/
                  for (var i = availabilities.length - 1; i >= 0; i--) {
                    var avail = availabilities[i];

                    var availColorSetting = availTypeColorSettings.find(function(availType) {
                      return availType.id == avail.availability_type_id;
                    });

                    var textColor = DEFAULT_TEXT_COLOR;
                    var availColor = DEFAULT_AVAILABILITY_TYPES_COLORS_MAP[avail.availability_type_id];

                    if (availColorSetting) {
                      availColor = availColorSetting.color;
                    }

                    var event = {
                      type: 'availability',
                      start: avail.start_time,
                      end: avail.end_time,
                      textColor: textColor,
                      color: availColor,
                      resourceId: avail.practitioner_id,
                      editable: true,
                      value: avail // availability reference to use later
                    };

                    events.push(event);
                  }
                  callback(events);
                  that.$nextTick(function() {
                    that.refreshResources();
                    that.loading = false;
                  });
                },
                complete: function() {
                  that.loading = false;
                },
                error: function(xhr) {
                  that.$nextTick(function() {
                    that.loading = false;
                  });
                  that.$notify('There was an error while retrieving data. Response status: ' + xhr.status, 'error');
                }
              });
            }
          },
          // Tasks event source
          {
            events: function(start, end, timezone, callback) {
              if (that.selectedPractitioners.length === 0) {
                callback([]);
                return;
              }

              var events = [];

              $.ajax({
                url: '/api/tasks/completed.json',
                dataType: 'json',
                data: that.buildTasksQueryParams(start, end, timezone),
                success: function(res) {
                  const tasks = res.tasks;
                  that.tasks = tasks;

                  // @see https://fullcalendar.io/docs/event_data/Event_Object/
                  for (var i = tasks.length - 1; i >= 0; i--) {
                    const task = tasks[i];

                    for (var j = task.task_users.length - 1; j >= 0; j--) {
                      const assignment = task.task_users[j];
                      const userId = assignment.user_id;
                      const event = {
                        type: 'task',
                        value: task,
                        start: assignment.complete_at,
                        end: assignment.complete_at,
                        title: task.name,
                        allDay: true,
                        // backgroundColor: DEFAULT_TASK_EVENT_BACKGROUND_COLOR,
                        resourceId: that.findPractitionerIdByUserId(userId),
                        editable: false
                      };

                      events.push(event);
                    }
                  }
                  callback(events);
                },
                complete: function() {
                },
                error: function(xhr) {
                  that.$notify('There was an error while retrieving tasks. Response status: ' + xhr.status, 'error');
                }
              });
            }
          }
        ],
        initialAction: null
      };
    },
    computed: {
      selectedPractitionersCount: function() {
        return this.selectedPractitioners.length;
      },
      practitionersCount: function() {
        return this.business.practitioners.length;
      },
      selectedPractitionerIds: function() {
        return this.selectedPractitioners.map(function(pract) { return pract.id });
      },
      isRestrictedPractitionerRole: function() {
        return App.user && (App.user.role == App.CONSTANTS.USER.ROLE_RESTRICTED_PRACTITIONER);
      },
      isCurrentUserAPractitioner: function() {
        return App.user && App.user.is_practitioner;
      },
      canViewOtherCalendar: function() {
        return App.user && [
          App.CONSTANTS.USER.ROLE_ADMINISTRATOR,
          App.CONSTANTS.USER.ROLE_SUPERVISOR,
          App.CONSTANTS.USER.ROLE_RECEPTIONIST,
          App.CONSTANTS.USER.ROLE_RESTRICTED_SUPERVISOR].indexOf(App.user.role) !== -1;
      }
    },
    mounted: function() {
      this.canEditAppearanceSettings = App.user.role == App.CONSTANTS.USER.ROLE_ADMINISTRATOR;

      var that = this;
      this.parseInitialActionParams();
      $('body').on('click', '#mobile-calendar-actions-dropdown', function() {
        $('#mobile-calendar-actions-dropdown').addClass('hide');
      });

      CalendarEventBus.$on('availability-show', function(avail) {
        that.showAvailability(avail.id);
      });

      CalendarEventBus.$on('appointment-status-updated', function(appointment) {
        that.refreshCalendar();
      });

      CalendarEventBus.$on('appointment-confirmation-status-updated', function(appointment) {
        that.refreshCalendar();
      });

      CalendarEventBus.$on('availability-appointments-order-updated', function() {
        that.refreshCalendar();
      });

      CalendarEventBus.$on('appointment-created', function(appointment) {
        that.refreshCalendar();
      });

      CalendarEventBus.$on('availability-updated', function(avail) {
        that.refreshCalendar();
      });

      CalendarEventBus.$on('calendar-appearance-settings.updated', function(settings) {
        that.appearanceSettings = settings;
        that.applyAppearanceSettings();
      });
    },
    methods: {
      /**
        Parse initial parameters which wrapped by '_ia'
      */
      parseInitialActionParams: function() {
        if (Utils.getQueryParameter('_ia')) {
          this.initialAction = {
            name: Utils.getQueryParameter('_ia'),
            params: {},
            valid: true
          };

          switch (this.initialAction.name) {
            case 'add_to_waiting_list':
              var patientId = Utils.getQueryParameter('patient_id');
              var profession = Utils.getQueryParameter('profession');
              var practitionerId = Utils.getQueryParameter('practitioner_id');
              if (patientId) {
                this.initialAction.params.patientId = patientId;
                this.initialAction.params.profession = profession;
                this.initialAction.params.practitionerId = practitionerId;
              } else {
                this.initialAction.valid = false;
              }
              break;

            case 'schedule_waiting_list': {
              var waitListItemID = Utils.getQueryParameter('id');
              if (waitListItemID) {
                this.initialAction.params.waitListItemID = waitListItemID;
              } else {
                this.initialAction.valid = false;
              }
              break;
            }

            case 'schedule_from_referral': {
              var referralID = Utils.getQueryParameter('referral_id');
              if (referralID) {
                this.initialAction.params.referralID = referralID;
              } else {
                this.initialAction.valid = false;
              }
              break;
            }

            case 'schedule_from_appointment': {
              var apptID = Utils.getQueryParameter('appointment_id');
              if (apptID) {
                this.initialAction.params.appointmentID = apptID;
              } else {
                this.initialAction.valid = false;
              }
              break;
            }

            case 'schedule_from_patient': {
              var patientID = Utils.getQueryParameter('patient_id');
              if (patientID) {
                this.initialAction.params.patientID = patientID;
              } else {
                this.initialAction.valid = false;
              }
              break;
            }
          }
        }

        if (this.initialAction && !this.initialAction.valid) {
          console.warn('Calendar initial action is invalid!');
        }
      },
      processInitialAction: function() {
        // TODO: move somewhere else
        var self = this;
        switch (this.initialAction.name) {
          case 'add_to_waiting_list':
            this.$refs.modalCreateWaitList.showModalWithPatient(
              this.initialAction.params.patientId,
              this.initialAction.params
            );
            break;

          case 'schedule_waiting_list': {
            $.ajax({
              url: '/api/wait_lists/' + this.initialAction.params.waitListItemID,
              success: function(res) {
                CalendarEventBus.$emit('waitlist-schedule', res.wait_list);
              }
            });

            break;
          }

          case 'schedule_from_referral': {
            $.ajax({
              url: '/api/referrals/' + this.initialAction.params.referralID,
              success: function(res) {
                CalendarEventBus.$emit('referral-schedule', res.referral);
              },
              error: function(xhr) {
                self.$notify('There was an error while retrieving referral info.', 'error');
              }
            });

            break;
          }

          case 'schedule_from_appointment': {
            $.ajax({
              url: '/api/appointments/' + this.initialAction.params.appointmentID,
              success: function(res) {
                CalendarEventBus.$emit('appointment-repeat', res.appointment);
              },
              error: function(xhr) {
                self.$notify('There was an error while retrieving the last appointment info.', 'error');
              }
            });

            break;
          }

          case 'schedule_from_patient': {
            $.ajax({
              url: '/api/patients/' + this.initialAction.params.patientID,
              success: function(res) {
                CalendarEventBus.$emit('patient-schedule', res.patient);
              },
              error: function(xhr) {
                self.$notify('There was an error while retrieving the client info.', 'error');
              }
            });

            break;
          }
        }
      },
      allPractitionerIds: function() {
        return this.business.practitioners.map(
          function(pract) {
            return pract.id;
          }
        );
      },
      buildCalendarQueryParams: function(startTime, endTime, timezone) {
        var query = {
          from_date: startTime.format('YYYY-MM-DD'),
          to_date: endTime.clone().subtract(1, 'seconds').format('YYYY-MM-DD'),
          timezone: timezone,
          _: (new Date().getTime())
        };

        if (this.selectedPractitionerIds.length != this.business.practitioners.length) {
          query.practitioner_ids = this.selectedPractitionerIds;
        }

        return query;
      },
      buildTasksQueryParams: function(startTime, endTime, timezone) {
        var query = {
          from_date: startTime.format('YYYY-MM-DD'),
          to_date: endTime.clone().subtract(1, 'seconds').format('YYYY-MM-DD'),
          timezone: timezone,
          _: (new Date().getTime())
        };

        if (this.selectedPractitionerIds.length != this.business.practitioners.length) {
          query.practitioner_ids = this.selectedPractitionerIds;
        }

        return query;
      },
      fetchAvailabilityUrl: function(id) {
        return '/api/availabilities/' + id + '.json';
      },
      refetchAvailability: function(availabilityId) {
        var that = this;
        $.ajax({
          url: that.fetchAvailabilityUrl(availabilityId),
          success: function(res) {
            that.currentAvailability = res.availability;
            that.$nextTick(function() {
              that.$refs.modalShowAvailability.setAvailability(that.currentAvailability);
            });
          }
        });
      },
      showAvailability: function(availabilityId) {
        var that = this;
        var vmModalShowAvail = that.$refs.modalShowAvailability;
        vmModalShowAvail.fetchAndShow(availabilityId);
      },
      // showAppointment: function(appointment) {
      //   this.onAppointmentEdit(appointment);
      // },
      // Calendar events
      onCalendarEventSelected: function(event, jsEvent, view) {
        if (view.name == 'listWeek' || view.name == 'listDay') {
          if (event.type == 'task') {
            CalendarEventBus.$emit('task-show', event.value);
          } else {
            return;
          }
        } else {
          if (event.type == 'availability') {
            this.showAvailability(event.value.id);
          } else if (event.type == 'appointment') {
            this.showAvailability(event.value.availability_id);
          } else if (event.type == 'task') {
            CalendarEventBus.$emit('task-show', event.value);
          }
        }
      },
      onCalendarEventDrop: function(event, revertFunc) {
        this.showConfirmAvaibilityChangeModal(event);
      },
      onCalendarEventResized: function(event, revertFunc) {
        if (event.type == 'availability') {
          this.showConfirmAvaibilityChangeModal(event);
        }
      },
      onCalendarEventCreated: function(start, end, jsEvent, resource) {
        var practitionerId = null;
        if (resource) {
          practitionerId = resource.id;
        }

        this.showCreateAvailabilityModal({
          start: start,
          end: end,
          practitionerId: practitionerId
        });
      },
      onCalendarEventRender: function(event, element) {
        var that = this;
        if (element.hasClass('fc-list-item')) { // List view
          // Same for availability and appointment view mode
          if (event.type == 'availability') {
            var avail = event.value;
            var vm = new Vue({
              template: '<availability-listview :availability="availability" :business="business"  :appearanceSettings="appearanceSettings"/>',
              data: {
                availability: avail,
                business: that.business,
                appearanceSettings: that.appearanceSettings
              }
            });
            vm.$mount();
            element.find('.fc-list-item-title').get(0).appendChild(vm.$el);
          } else if (event.type == 'task') {
            element.addClass('fc-list-item-task');
          }
        } else {
          // Agenda view
          if (event.type == 'availability') {
            element.addClass('fc-event-availability');
            var avail = event.value;
            if (event.allDay) {
              return;
            }
            if (avail) {
              if (avail.availability_type_id == 5) { // Non-billable
                element.find('.fc-content').append(
                  '<span class="name" title="' + Utils.simpleSanitizeHtmlString(avail.name) + '">' + Utils.truncateWords(avail.name, 25) + '</span>'
                );
              }

              if (avail.availability_type_id == App.GROUP_APPOINTMENT_TYPE_ID) { // Group appointment
                var groupApptTitle = '';

                if (avail.group_appointment_type) {
                  groupApptTitle = avail.group_appointment_type.name;
                }

                element.find('.fc-content').append(
                  '<span class="name" title="' + Utils.simpleSanitizeHtmlString(groupApptTitle) + '">' + Utils.truncateWords(groupApptTitle, 25) + '</span>'
                );
              }

              // Mount appointments inside the availablity
              if (avail.availability_type_id == 1 || avail.availability_type_id == 4) {
                var vm = new Vue({
                  template: '<appointments-list-agenda :appointments="appointments" :appearanceSettings="appearanceSettings"/>',
                  data: {
                    appointments: avail.appointments,
                    appearanceSettings: that.appearanceSettings
                  }
                });
                vm.$mount();
                element.find('.fc-content').get(0).appendChild(vm.$el);
              }

              // Html for atttending stats
              if (avail.availability_type_id == 1 || avail.availability_type_id == 4|| avail.availability_type_id == 6) { // Home visits, Facility
                var attendingHtml =
                  '<span class="attending-stats">[' +
                    Utils.simpleSanitizeHtmlString(avail.appointments.length + '/' + avail.max_appointment) +
                  ']</span>';
                element.find('.fc-time').prepend(attendingHtml);
              }
            }
          }
        }
      },
      showConfirmAvaibilityChangeModal: function(event) {
        var vmModalConfirm = this.$refs.modalConfirmChangeAvailability;
        vmModalConfirm.setAvailabilityChanges(event.value, event);
        this.$nextTick(function() {
          vmModalConfirm.showModal();
        });
      },
      // Modal show availability events
      onAppointmentCancelled: function(appointment) {
        this.refetchAvailability(appointment.availability_id);
        this.refreshCalendar();
      },
      onAppointmentDeleted: function(appointment) {
        this.refetchAvailability(appointment.availability_id);
        this.refreshCalendar();
      },
      onAvailabilityDeleted: function(availability) {
        if (this.currentAvailability && this.currentAvailability.id == availability.id) {
          this.currentAvailability = null;
        }
        if (this.$refs.modalShowAvailability.availability.id == availability.id) {
          this.$refs.modalShowAvailability.availability = null;
          this.$refs.modalShowAvailability.show = false;
        }
        this.refreshCalendar();
      },
      onAvailabilityEdit: function(availability) {
        var vmEditAvail = this.$refs.modalEditAvailability;
        vmEditAvail.setAvailability(availability);
        this.$nextTick(function() {
          vmEditAvail.showModal();
        });
      },
      onAvailabilityDelete: function(availability) {
        var vmDeleteAvail = this.$refs.modalDeleteAvailability;
        vmDeleteAvail.setAvailability(availability);
        this.$nextTick(function() {
          vmDeleteAvail.showModal();
        });
      },
      onAppointmentAddToAvailability: function(availability) {
        this.$refs.modalCreateAppointment.showWithAvailability(availability);
      },
      onAppointmentEdit: function(appointment) {
        this.$refs.modalEditAppointment.setAppointment(appointment);
        this.$refs.modalEditAppointment.showModal();
      },
      // Modal edit availability events
      onAvailabilityUpdated: function(availability) {
        this.currentAvailability = availability;
        this.$refs.modalShowAvailability.setAvailability(availability);
        this.refreshCalendar();
      },
      onAvailabilityChangePractitioner: function(availability) {
        this.$refs.modalChangeAvailabilityPractitioner.showModal(availability);
      },
      onAvailabilityUpdatedPractitioner: function(availability) {
        this.currentAvailability = availability;
        this.$refs.modalShowAvailability.setAvailability(availability);
        this.$refs.modalEditAvailability.closeModal();
        this.refreshCalendar();
      },
      // Modal create availability events
      onAvailabilityCreated: function(availability) {
        this.refreshCalendar();
      },
      // Modal create appointment events
      onAppointmentCreated: function(appointment) {
        this.refetchAvailability(appointment.availability_id);
        this.refreshCalendar();
      },
      onPatientAdd: function() {
        this.$refs.modalCreatePatient.showModal();
      },
      // Modal edit appointment events
      onAppointmentUpdated: function(appointment) {
        this.refetchAvailability(appointment.availability_id);
        this.refreshCalendar();
      },

      // Modal create patient events
      onPatientCreated: function(patient) {
        // TODO: change to use events bus
        var modalCreateAppointment = this.$refs.modalCreateAppointment;
        if (modalCreateAppointment.isActive()) {
          modalCreateAppointment.setPatient(patient);
        }
        var modalCreateAvailability = this.$refs.modalCreateAvailability;
        if (modalCreateAvailability.isActive()) {
          modalCreateAvailability.setPatient(patient);
        }
      },

      // Modal confirm availability time changes
      onAvailabilityTimeUpdated: function(availability) {
        this.refreshCalendar();
      },
      onAvailabilityTimeChangeCancelled: function(availability) {
        // TODO: only rerender the event instead of refresh the calendar
        this.refreshCalendar();
      },
      // Modal repeat appointments event
      onRepeatAppointmentsCreated: function(appointments) {
        this.$refs.modalShowAvailability.fetchAndShow(appointments[0].availability_id);
        this.refreshCalendar();
      },
      // Modal wait list events
      onWaitListAdd: function() {
        this.$refs.modalCreateWaitList.showModal();
      },
      onWaitListEdit: function(waitList) {
        this.$refs.modalEditWaitList.showModalWith(waitList);
      },
      onWaitListCreated: function(waitList) {
        if (this.$refs.modalWaitList.isShow()) {
          this.$refs.modalWaitList.clearFiltersAndFetch();
        }
      },
      onWaitListUpdated: function(wailList) {
        if (this.$refs.modalWaitList.isShow()) {
          this.$refs.modalWaitList.clearFiltersAndFetch();
        }
      },
      showWaitListModal: function() {
        this.$refs.modalWaitList.showModal();
      },
      showCreateAvailabilityModal: function(options) {
        var vmModalCreateAvail = this.$refs.modalCreateAvailability;

        vmModalCreateAvail.resetForm();
        if (options.start && options.end) {
          vmModalCreateAvail.setAvailabilityTime(
            options.start,
            options.end
          );
        }

        if (options.practitionerId) {
          vmModalCreateAvail.setPractitionerId(options.practitionerId);
        }
        this.$nextTick(function() {
          vmModalCreateAvail.showModal();
        });
      },
      buildSelectPractitionerOptions: function(business, excludePractitionerIds) {
        var options = [];

        for (var i = 0, gl = business.groups.length; i < gl; i++) {
          var group = business.groups[i];
          var groupOption = {
            id: 'group-' + group.id,
            type: 'Group',
            value: group,
            label: group.name
          };
          options.push(groupOption);
        }

        for (var j = 0, pl = business.practitioners.length; j < pl; j++) {
          var pract = business.practitioners[j];
          if (excludePractitionerIds.indexOf(pract.id) == -1) {
            var practOption = {
              id: 'practitioner-' + pract.id,
              type: 'Practitioner',
              value: pract,
              label: pract.full_name
            };
            options.push(practOption);
          }
        }

        return options;
      },
      getSelectedPractitionerIds: function() {
        var selectedPractIds = [];
        for (var i = this.selectedPractitioners.length - 1; i >= 0; i--) {
          selectedPractIds.push(this.selectedPractitioners[i].id);
        }
        return selectedPractIds;
      },
      updatePractitionerFilterOptions: function() {
        var selectedPractIds = this.getSelectedPractitionerIds();
        this.practitionerFilterOptions = this.buildSelectPractitionerOptions(
          this.business,
          selectedPractIds
        );
      },
      setBusiness: function(business, practitionerIds) {
        this.business = business;
        var preSelectedPractitionerIds = [];

        if (practitionerIds && practitionerIds.length) {
          preSelectedPractitionerIds = practitionerIds;
        }

        this.selectedPractitioners = [];
        for (var i = business.practitioners.length - 1; i >= 0; i--) {
          var pract = business.practitioners[i];
          if (preSelectedPractitionerIds.indexOf(pract.id) !== -1) {
            this.selectedPractitioners.push(pract);
          }
        }

        this.updatePractitionerFilterOptions();

        this.loadAppearanceSettings();

        this.refreshResources();

        this.$nextTick(function() {
          if (this.initialAction && this.initialAction.valid) {
            this.processInitialAction();
          }
          this.clearState();
        });
      },
      refreshResources: function() {
        var resources = [];

        for (var i = 0, l = this.business.practitioners.length; i < l; i++) {
          var pract = this.business.practitioners[i];
          var businessHours = this.transformBusinessHourSettings(pract.business_hours);
          if (this.selectedPractitionerIds.indexOf(pract.id) !== -1) {
            var resource = {
              id: pract.id,
              title: pract.first_name,
              businessHours: businessHours.length > 0 ? businessHours : false
            };
            resources.push(resource);
          }
        }
        this.resources = resources;
        this.$nextTick(function() {
          this.$refs.fullcalendar.$emit('refetch-resources');
        });
      },
      /**
       * Transform business hours from database to the Fullcalendar format
       * @see: https://fullcalendar.io/docs/v3/businessHours
       * NOTE: need to update when upgrade the Fullcalendar version
       *
       * NOTE: if not business hours setting found, disable businessHours
       */
      transformBusinessHourSettings: function(practitionerBusinessHoursSettings) {
        var businessHours = [];

        for (var i = 0, l = practitionerBusinessHoursSettings.length; i < l; i++) {
          var dayOfWeekSetting = practitionerBusinessHoursSettings[i];

          if (dayOfWeekSetting.active) {
            if (dayOfWeekSetting.availability && dayOfWeekSetting.availability.length > 0) {
              for (var ai = dayOfWeekSetting.availability.length - 1; ai >= 0; ai--) {
                var avail = dayOfWeekSetting.availability[ai];
                businessHours.push({
                  dow: [dayOfWeekSetting.day_of_week],
                  start: avail.start,
                  end: avail.end,
                });
              }
            } else {
              businessHours.push({
                dow: [dayOfWeekSetting.day_of_week],
                start: '00:00',
                end: '23:59',
              });
            }
          }
        }

        return businessHours;
      },
      onChangedPractitioners: function() {
        this.refreshResources();
        this.refreshCalendar();
        this.$emit('filters-changed');
      },
      refreshCalendar: function() {
        this.$refs.fullcalendar.$emit('refetch-events');
      },
      selectAllPractitioners: function() {
        this.selectedPractitioners = this.business.practitioners.slice(0);
        this.updatePractitionerFilterOptions();
        this.onChangedPractitioners();
      },
      deselectAllPractitioners: function() {
        this.selectedPractitioners = [];
        this.updatePractitionerFilterOptions();
        this.onChangedPractitioners();
      },
      selectOnlyMe: function() {
        if (this.isCurrentUserAPractitioner) {
          for (var i = 0; i < this.business.practitioners.length; i++) {
            var pract = this.business.practitioners[i];
            if (pract.id === App.user.practitioner_id) {
              this.selectedPractitioners = [pract];
              this.onChangedPractitioners();
              break;
            }
          }
        }
      },
      onSelectPractitionerOption: function(option) {
        if (option.type === 'Practitioner') {
          var pract = option.value;
          this.selectedPractitioners.push(pract);
        } else if (option.type === 'Group') {
          var group = option.value;
          var groupPractitioners = [];
          for (var i = 0; i < this.business.practitioners.length; i++) {
            var pract = this.business.practitioners[i];
            if (group.practitioner_ids.indexOf(pract.id) !== -1) {
              groupPractitioners.push(pract);
            }
          }
          this.selectedPractitioners = groupPractitioners;
        }
        this.updatePractitionerFilterOptions();
        this.onChangedPractitioners();
      },
      removePractitioner: function(practitioner) {
        for (var i = this.selectedPractitioners.length - 1; i >= 0; i--) {
          if (this.selectedPractitioners[i].id == practitioner.id) {
            this.selectedPractitioners.splice(i, 1);
            break;
          }
        }

        this.updatePractitionerFilterOptions();
        this.onChangedPractitioners();
      },

      applyAppearanceSettings: function() {
        if (this.appearanceSettings.is_show_tasks) {
          this.$refs.fullcalendar.option('allDaySlot', true);
        } else {
          this.$refs.fullcalendar.option('allDaySlot', false);
        }
        this.refreshCalendar();
      },

      loadAppearanceSettings: function() {
        var vm = this;
        $.ajax({
          method: 'GET',
          url: '/api/calendar/appearance_settings',
          success: function(res) {
            if (res.settings) {
              vm.appearanceSettings = res.settings;
            }
            vm.applyAppearanceSettings();
          },
          error: function(xhr) {
            vm.$notify('Could not load calendar appearance settings.', 'error');
          }
        });
      },
      showCreateAppointmentModal: function() {
        this.$refs.modalCreateAppointment.showModal();
      },
      showCalendarAppearanceSettings: function() {
        CalendarEventBus.$emit('calendar-appearance-settings.show');
      },
      onToggleViewModeChanged: function(change) {
        this.settings.viewMode = change.value ? 'appointment' : 'availability';
        this.refreshCalendar();
        this.$emit('settings-changed');
      },
      // NOTE: debounce to workaround the onChange event trigger twice
      onCalendarDatepickerChange: debounce(function(selectedDates, dateStr, instance) {
        this.$refs.fullcalendar.gotoDate(moment(selectedDates[0]));
      }, 200),
      setDateCalendarDatepickers: function(date) {
        this.$nextTick(function() {
          this.$refs.calendarDatepicker.fp.setDate(date, false);
          this.$refs.mobilecalendarDatepicker.fp.setDate(date, false);
        });
      },
      onCalendarViewRender: function(view, element) {
        this.settings.calendarCurrentDateTitle = view.title;
        // Remember view mode
        if (this.settings.calendarView != view.name) {
          this.settings.calendarView = view.name;
          this.$emit('settings-changed');
        }
      },
      // Mobile header events
      changeCalendarView: function(viewName) {
        this.$refs.fullcalendar.changeView(viewName);
      },
      goNextCalendar: function() {
        this.$refs.fullcalendar.next();
      },
      goPrevCalendar: function() {
        this.$refs.fullcalendar.prev();
      },
      goTodayCalendar: function() {
        this.$refs.fullcalendar.today();
      },
      onTimezoneChange: function() {
        this.$emit('settings-changed');
        document.dispatchEvent(
          new CustomEvent('app.timezone.change', {
            bubbles: true,
            detail: {
              timezone: this.settings.timezone
            }
          })
        );
      },
      toggleMobileCalendarActionsMenu: function() {
        $('#mobile-calendar-actions-dropdown').toggleClass('hide');
      },
      addAppointment: function() {
        CalendarEventBus.$emit('appointment-add');
      },
      clearState: function() {
        window.history.pushState(
          'calendar-business-' + this.business.id,
          document.title,
          window.location.pathname
        );
      },
      // NOTE: can avoid this complexity by using user ID instead of practitioner ID as resource ID
      findPractitionerIdByUserId: function(userId) {
        for (let i = this.business.practitioners.length - 1; i >= 0; i--) {
          const pract = this.business.practitioners[i];
          if (pract.user_id === userId) {
            return pract.id;
          }
        }
      }
    }

  });
})();
