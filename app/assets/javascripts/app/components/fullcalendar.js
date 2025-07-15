(function() {
    Vue.component('fullcalendar', {
        template: '<div ref="calendar"></div>',
        props: {
            resources: {
                default: function() {
                    return [];
                }
            },
            events: {
                default: function() {
                    return [];
                }
            },
            eventSources: {
                default: function() {
                    return [];
                }
            },
            editable: {
                default: function () {
                    return true;
                }
            },
            selectable: {
                default: function () {
                    return true;
                }
            },
            allDaySlot: {
                default: function () {
                    return false;
                }
            },
            selectHelper: {
                default: function () {
                    return true;
                }
            },
            header: {
                default: function () {
                    return false;
                }
            },
            views: {
                default: function() {
                    return {
                        agendaThreeDay: {
                            type: 'agenda',
                            duration: { days: 3 },
                            buttonText: '3 days',
                            groupByResource: true,
                            groupByDateAndResource: true
                        },
                        weekdays: {
                            type: 'agenda',
                            duration: { weeks: 1 },
                            buttonText: 'weekdays',
                            groupByResource: true,
                            hiddenDays: [0, 6],
                            groupByDateAndResource: true
                        },
                        agendaWeek: {
                            groupByResource: true,
                            groupByDateAndResource: true
                        }
                    }
                }
            },
            defaultView: {
                default: function () {
                    return 'agendaWeek';
                }
            },
            timezone: {
                default: function() {
                    return 'UTC';
                }
            },
            sync: {
                default: function() {
                    return false;
                }
            }
        },
        created: function() {
            this.$on('remove-event', function(event) {
                $(this.$refs.calendar).fullCalendar('removeEvents', event.id);
            });
            this.$on('rerender-events', function(event) {
                $(this.$refs.calendar).fullCalendar('rerenderEvents');
            });
            this.$on('refetch-events', function(event) {
                $(this.$refs.calendar).fullCalendar('refetchEvents');
            });
            this.$on('refetch-resources', function(event) {
                $(this.$refs.calendar).fullCalendar('refetchResources');
            });
            this.$on('render-event', function(event) {
                $(this.$refs.calendar).fullCalendar('renderEvent', event);
            });
            this.$on('reload-events', function() {
                $(this.$refs.calendar).fullCalendar('removeEvents');
                $(this.$refs.calendar).fullCalendar('addEventSource', this.events);
            });
            this.$on('rebuild-sources', function() {
                $(this.$refs.calendar).fullCalendar('removeEvents');
                this.eventSources.map(function(event) {
                    $(this.$refs.calendar).fullCalendar('addEventSource', event);
                });
            });
        },
        mounted: function() {
            var cal = $(this.$refs.calendar);
            var self = this;
            $(this.$refs.calendar).fullCalendar({
                schedulerLicenseKey: '0358404733-fcs-1499830747',
                lazyFetching: false,
                firstDay: 1, // Monday as first day of week
                height: function() {
                    return $('#business-calendar').closest('.content-wrapper').height();
                },
                header: this.header,
                defaultView: this.defaultView,
                editable: this.editable,
                selectable: this.selectable,
                selectHelper: this.selectHelper,
                aspectRatio: 2,
                allDayText: 'Tasks',
                allDaySlot: this.allDaySlot,
                eventLimit: true,
                titleFormat: 'D MMM, YYYY',
                columnFormat: 'ddd D/M',
                timeFormat: 'hh:mma',
                scrollTime: '07:00:00',
                timezone: self.timezone,
                events: self.events,
                nowIndicator: true,
                slotDuration: '00:15:00',
                slotLabelInterval: '01:00:00',
                eventSources: self.eventSources,
                minTime: '05:00',
                maxTime: '22:00',
                now: function() {
                    return moment().tz(self.timezone);
                },
                resources: function(callback) {
                    callback(self.resources);
                },
                views: this.views,
                selectConstraint: { // Limit selectable in a single day
                  start: '00:01',
                  end: '23:59'
                },
                eventConstraint: { // Limit resizing in a single day
                  start: '00:01',
                  end: '23:59'
                },
                eventRender: function(event, element) {
                    if (this.sync) {
                        self.events = cal.fullCalendar('clientEvents');
                    }
                    self.$emit('event-render', event, element);
                },
                eventDestroy: function(event) {
                    if (this.sync) {
                        self.events = cal.fullCalendar('clientEvents');
                    }
                },
                eventClick: function(event, jsEvent, view) {
                    var $target = $(jsEvent.target);
                    // Workaround click links in list view
                    if (!$target.hasClass('patient-link') && !$target.hasClass('phone-link') &&
                        !$target.hasClass('map-link')) {
                      self.$emit('event-selected', event, jsEvent, view);
                    }
                },
                eventDrop: function(event, delta, revertFunc) {
                    self.$emit('event-drop', event, revertFunc);
                },
                eventResize: function(event, delta, revertFunc) {
                    self.$emit('event-resize', event, revertFunc);
                },
                select: function(start, end, jsEvent, view, resource) {
                    self.$emit(
                        'event-created',
                        start,
                        end,
                        jsEvent,
                        resource
                    );
                },
                viewRender: function(view, elm) {
                    /* Change fixed time table 'left' property when horizontal scroll fc-view */
                    $('.fc-view').on('scroll', function(e) {
                        self.repositionFixedTimesTable();
                    });
                    self.$emit(
                        'view-rendered',
                        view,
                        elm
                    );
                    self.resizeEventTables();
                },
                eventAfterAllRender: function() {
                    if (self.isAgendaView()) {
                        var $cal = $(self.$refs.calendar);
                        if ($('.table-axis-times-fixed').length === 0) {
                            var $tableEvents = $cal.find('.fc-slats > table');
                            var columnWidth = Math.max.apply(
                                Math,
                                $tableEvents.find('td.fc-axis.fc-time').map(
                                    function() {
                                      return this.offsetWidth;
                                    }
                                ).get());
                            var $tableTimesFixed = $('<table/>', {
                                class: 'table-axis-times-fixed',
                                style: 'width: ' + (columnWidth + 1) + 'px'
                            });
                            $tableTimesFixed.appendTo($cal.find('.fc-scroller'));
                            $tableEvents.find('td.fc-axis.fc-time').each(function() {
                                $tableTimesFixed.append('<tr><td>' + $(this).html() + '</td></tr>');
                            });
                        }
                    } else {
                        $('.table-axis-times-fixed').remove();
                    }
                }
            });

            /**
             * The table width is fixed, thus we need to update if its container resized.
             */
            document.addEventListener(
                'app.sidebar.collapsing', function() {
                    setTimeout(function() {
                        self.resizeEventTables();
                    }, 300);
                }
            );
            window.addEventListener(
                'resize', function() {
                    setTimeout(function() {
                        self.resizeEventTables();
                    }, 300);
                }
            );
        },
        watch: {
            events: {
                deep: true,
                handler: function(val) {
                    $(this.$refs.calendar).fullCalendar('rerenderEvents');
                }
            },
            eventSources: {
                deep: true,
                handler: function(val) {
                    this.$emit('rebuild-sources');
                },
            },
            timezone: function(timezone) {
                var $cal = $(this.$refs.calendar);
                $cal.fullCalendar('option', 'timezone', timezone);
            }
        },
        beforeDestroy: function() {
            this.$off('remove-event');
            this.$off('rerender-events');
            this.$off('refetch-events');
            this.$off('refetch-resources');
            this.$off('render-event');
            this.$off('reload-events');
            this.$off('rebuild-sources');
        },
        methods: {
            next: function() {
                $(this.$refs.calendar).fullCalendar('next');
            },
            prev: function() {
                $(this.$refs.calendar).fullCalendar('prev');
            },
            today: function() {
                $(this.$refs.calendar).fullCalendar('today');
            },
            gotoDate: function(date) {
                $(this.$refs.calendar).fullCalendar('gotoDate', date);
            },
            option: function(option, value) {
                $(this.$refs.calendar).fullCalendar('option', option, value);
            },
            changeView: function(viewName) {
                $(this.$refs.calendar).fullCalendar('changeView', viewName);
            },
            currentView: function() {
                return $(this.$refs.calendar).fullCalendar('getView');
            },
            isAgendaView: function() {
                return [
                    'agendaDay', 'agendaThreeDay', 'weekdays', 'agendaWeek'
                ]
                .indexOf(this.currentView().name) != -1;
            },
            wrapElement: function() {
                return $('.calendar-wrap');
            },
            repositionFixedTimesTable: function() {
                if ($('.table-axis-times-fixed').length > 0) {
                    $('.table-axis-times-fixed').css(
                        'left',
                        ($('.fc-view').scrollLeft() + 'px')
                    );
                }
            },
            resizeEventTables: function() {
                if (this.isAgendaView()) {
                  var $cal = $(this.$refs.calendar);
                  var currentView = this.currentView();
                  var daysInCurrentView;
                  var daysInCurrentView = {
                    'agendaWeek': 7,
                    'weekdays': 5,
                    'agendaThreeDay': 3,
                    'agendaDay': 1
                  }[currentView.name];

                  var noOfResources = $cal.fullCalendar('getResources').length;

                  if (daysInCurrentView) {

                    var tableWidth = 50 + noOfResources * 82 * daysInCurrentView;
                    var wrapEl = this.wrapElement();
                    if (tableWidth < wrapEl.width()) {
                      tableWidth = wrapEl.width();
                    }
                    $cal.find('.fc-view > table').css('width', tableWidth + 'px');
                  }
                }
            }
        }
    });
})();
