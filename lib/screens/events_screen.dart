import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/event.dart';
import 'package:flutter_application_1/screens/create_event_screen.dart';
import 'package:flutter_application_1/screens/edit_event_screen.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:flutter_application_1/screens/event_details_screen.dart';
import 'package:get_it/get_it.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_application_1/widgets/event_widget.dart';
import 'package:flutter_application_1/services/connectivity_service.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  static const routeName = '/events';
  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseService firebaseService = GetIt.instance<FirebaseService>();
  bool _isOrganiser = false;
  bool _loadingRole = true;
  bool _online = true;
  late TabController _tabController;
  CalendarFormat _calFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late final Stream<List<Event>> _eventsStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _eventsStream = firebaseService.getEventsAsStream();
    _initRole();
    GetIt.instance<ConnectivityService>().isOnline$.listen((isOnline) {
      if (!mounted) return;
      setState(() => _online = isOnline);
    });
  }

  Future<void> _initRole() async {
    final isOrg = await firebaseService.isCurrentUserOrganiser();
    if (!mounted) return;
    // to show create event button to organisations
    setState(() {
      _isOrganiser = isOrg;
      _loadingRole = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final texttheme = Theme.of(context).textTheme;
    final mq = MediaQuery.of(context);
    final isLandscape = mq.orientation == Orientation.landscape;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: SafeArea(
          child: TabBar(
            controller: _tabController,
            labelColor: scheme.primary,
            unselectedLabelColor: scheme.onSurfaceVariant,
            indicatorColor: scheme.primary,
            // divider for events and calendar view
            tabs: const [Tab(text: 'List'), Tab(text: 'Calendar')],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: StreamBuilder<List<Event>>(
          stream: _eventsStream,
          initialData: [],
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final events = snapshot.data ?? [];
            if (snapshot.connectionState == ConnectionState.waiting &&
                events.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            // group events by day using startDateTime date
            // used for calendar
            final Map<DateTime, List<Event>> byDay = {};
            for (final event in events) {
              final dt = event.startDateTime!;
              final dayKey = DateTime(dt.year, dt.month, dt.day);
              byDay.putIfAbsent(dayKey, () => []).add(event);
            }

            // make it the current day if nothing is chosen if not make it the selected day
            final selectedDayKey =
                _selectedDay == null
                    ? DateTime(
                      _focusedDay.year,
                      _focusedDay.month,
                      _focusedDay.day,
                    )
                    : DateTime(
                      _selectedDay!.year,
                      _selectedDay!.month,
                      _selectedDay!.day,
                    );

            // List tab
            return TabBarView(
              controller: _tabController,
              children: [
                // Portrait uses single column list, landscape uses 2-column rows
                Builder(
                  builder: (context) {
                    Widget buildEventTile(Event event) {
                      return InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (_) => EventDetailsScreen(eventId: event.id!),
                            ),
                          );
                        },

                        child: EventWidget(
                          event: event,
                          trailing:
                              _isOrganiser
                                  ? PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (!_online) {
                                        ScaffoldMessenger.maybeOf(
                                          context,
                                        )?.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Offline: action unavailable',
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      if (value == 'edit') {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder:
                                                (_) => const EditEventScreen(),
                                            settings: RouteSettings(
                                              arguments: event,
                                            ),
                                          ),
                                        );
                                      } else if (value == 'delete') {
                                        await firebaseService.deleteEvent(
                                          event.id!,
                                        );
                                      }
                                    },
                                    itemBuilder:
                                        (ctx) => const [
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Text('Edit'),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Delete'),
                                          ),
                                        ],
                                  )
                                  : null,
                        ),
                      );
                    }

                    if (!isLandscape) {
                      // Portrait: original single list
                      return ListView.builder(
                        itemCount: (events.isEmpty ? 1 : events.length) + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                20,
                                20,
                                10,
                              ),
                              child: Text(
                                'Upcoming Events',
                                style: texttheme.headlineMedium?.copyWith(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }
                          if (events.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(child: Text('No events yet')),
                            );
                          }
                          final event = events[index - 1];
                          return buildEventTile(event);
                        },
                      );
                    }

                    // Landscape: 2 horizontally events (pair per row)
                    final rowsCount = (events.length + 1) ~/ 2;
                    return ListView.builder(
                      itemCount: 1 + (rowsCount == 0 ? 1 : rowsCount),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                            child: Text(
                              'Upcoming Events',
                              style: texttheme.headlineMedium?.copyWith(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        if (rowsCount == 0) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: Text('No events yet')),
                          );
                        }
                        final leftIndex = (index - 1) * 2;
                        final rightIndex = leftIndex + 1;
                        final left = events[leftIndex];
                        final hasRight = rightIndex < events.length;
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 6.0,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: buildEventTile(left)),
                              const SizedBox(width: 12),
                              Expanded(
                                child:
                                    hasRight
                                        ? buildEventTile(events[rightIndex])
                                        : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                // Calendar tab
                !isLandscape
                    ? Column(
                      children: [
                        TableCalendar<Event>(
                          firstDay: DateTime(2000),
                          lastDay: DateTime(2100),
                          focusedDay: _focusedDay,
                          calendarFormat: _calFormat,
                          headerStyle: const HeaderStyle(
                            formatButtonShowsNext: false,
                          ),
                          availableCalendarFormats: {
                            CalendarFormat.month: 'Month',
                            CalendarFormat.twoWeeks: '2 weeks',
                            CalendarFormat.week: 'Week',
                          },
                          selectedDayPredicate:
                              (day) => isSameDay(_selectedDay, day),
                          eventLoader: (day) {
                            final key = DateTime(day.year, day.month, day.day);
                            return byDay[key] ?? const [];
                          },
                          calendarBuilders: CalendarBuilders<Event>(
                            markerBuilder: (context, day, events) {
                              if (events.isEmpty)
                                return const SizedBox.shrink();
                              final color =
                                  Theme.of(context).colorScheme.primary;
                              final maxDots = 3;
                              final count =
                                  events.length > maxDots
                                      ? maxDots
                                      : events.length;
                              return Align(
                                alignment: Alignment.bottomCenter,
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 2,
                                  runSpacing: 2,
                                  children: List.generate(
                                    count,
                                    (_) => Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                          onFormatChanged: (format) {
                            setState(() => _calFormat = format);
                          },
                          onPageChanged: (focusedDay) {
                            _focusedDay = focusedDay;
                          },
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child:
                              (byDay[selectedDayKey] == null ||
                                      byDay[selectedDayKey]!.isEmpty)
                                  ? const Center(
                                    child: Text('No events this day'),
                                  )
                                  : ListView.builder(
                                    itemCount: byDay[selectedDayKey]!.length,
                                    itemBuilder: (context, idx) {
                                      final event = byDay[selectedDayKey]![idx];
                                      return InkWell(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => EventDetailsScreen(
                                                    eventId: event.id!,
                                                  ),
                                            ),
                                          );
                                        },
                                        child: EventWidget(
                                          event: event,
                                          trailing:
                                              _isOrganiser
                                                  ? PopupMenuButton<String>(
                                                    onSelected: (value) async {
                                                      if (!_online) {
                                                        ScaffoldMessenger.maybeOf(
                                                          context,
                                                        )?.showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              'Offline: action unavailable',
                                                            ),
                                                          ),
                                                        );
                                                        return;
                                                      }
                                                      if (value == 'edit') {
                                                        Navigator.of(
                                                          context,
                                                        ).push(
                                                          MaterialPageRoute(
                                                            builder:
                                                                (_) =>
                                                                    const EditEventScreen(),
                                                            settings:
                                                                RouteSettings(
                                                                  arguments:
                                                                      event,
                                                                ),
                                                          ),
                                                        );
                                                      } else if (value ==
                                                          'delete') {
                                                        await firebaseService
                                                            .deleteEvent(
                                                              event.id!,
                                                            );
                                                      }
                                                    },
                                                    itemBuilder:
                                                        (ctx) => const [
                                                          PopupMenuItem(
                                                            value: 'edit',
                                                            child: Text('Edit'),
                                                          ),
                                                          PopupMenuItem(
                                                            value: 'delete',
                                                            child: Text(
                                                              'Delete',
                                                            ),
                                                          ),
                                                        ],
                                                  )
                                                  : null,
                                        ),
                                      );
                                    },
                                  ),
                        ),
                      ],
                    )
                    : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 1,
                          child: TableCalendar<Event>(
                            firstDay: DateTime(2000),
                            lastDay: DateTime(2100),
                            focusedDay: _focusedDay,
                            calendarFormat: _calFormat,
                            headerStyle: const HeaderStyle(
                              formatButtonShowsNext: false,
                            ),
                            availableCalendarFormats: {
                              CalendarFormat.month: 'Month',
                              CalendarFormat.twoWeeks: '2 weeks',
                              CalendarFormat.week: 'Week',
                            },
                            // Tighter rows so the month fits better in landscape
                            rowHeight: 36,
                            selectedDayPredicate:
                                (day) => isSameDay(_selectedDay, day),
                            eventLoader: (day) {
                              final key = DateTime(
                                day.year,
                                day.month,
                                day.day,
                              );
                              return byDay[key] ?? const [];
                            },
                            calendarBuilders: CalendarBuilders<Event>(
                              markerBuilder: (context, day, events) {
                                if (events.isEmpty)
                                  return const SizedBox.shrink();
                                final color =
                                    Theme.of(context).colorScheme.primary;
                                final maxDots = 3;
                                final count =
                                    events.length > maxDots
                                        ? maxDots
                                        : events.length;
                                return Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 2,
                                    runSpacing: 2,
                                    children: List.generate(
                                      count,
                                      (_) => Container(
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                            },
                            onFormatChanged: (format) {
                              setState(() => _calFormat = format);
                            },
                            onPageChanged: (focusedDay) {
                              _focusedDay = focusedDay;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child:
                              (byDay[selectedDayKey] == null ||
                                      byDay[selectedDayKey]!.isEmpty)
                                  ? const Center(
                                    child: Text('No events this day'),
                                  )
                                  : ListView.builder(
                                    itemCount: byDay[selectedDayKey]!.length,
                                    itemBuilder: (context, idx) {
                                      final event = byDay[selectedDayKey]![idx];
                                      return InkWell(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => EventDetailsScreen(
                                                    eventId: event.id!,
                                                  ),
                                            ),
                                          );
                                        },
                                        child: EventWidget(
                                          event: event,
                                          trailing:
                                              _isOrganiser
                                                  ? PopupMenuButton<String>(
                                                    onSelected: (value) async {
                                                      if (!_online) {
                                                        ScaffoldMessenger.maybeOf(
                                                          context,
                                                        )?.showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              'Offline: action unavailable',
                                                            ),
                                                          ),
                                                        );
                                                        return;
                                                      }
                                                      if (value == 'edit') {
                                                        Navigator.of(
                                                          context,
                                                        ).push(
                                                          MaterialPageRoute(
                                                            builder:
                                                                (_) =>
                                                                    const EditEventScreen(),
                                                            settings:
                                                                RouteSettings(
                                                                  arguments:
                                                                      event,
                                                                ),
                                                          ),
                                                        );
                                                      } else if (value ==
                                                          'delete') {
                                                        await firebaseService
                                                            .deleteEvent(
                                                              event.id!,
                                                            );
                                                      }
                                                    },
                                                    itemBuilder:
                                                        (ctx) => const [
                                                          PopupMenuItem(
                                                            value: 'edit',
                                                            child: Text('Edit'),
                                                          ),
                                                          PopupMenuItem(
                                                            value: 'delete',
                                                            child: Text(
                                                              'Delete',
                                                            ),
                                                          ),
                                                        ],
                                                  )
                                                  : null,
                                        ),
                                      );
                                    },
                                  ),
                        ),
                      ],
                    ),
              ],
            );
          },
        ),
      ),
      floatingActionButton:
          (!_loadingRole && _isOrganiser)
              ? FloatingActionButton(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                onPressed:
                    !_online
                        ? null
                        : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CreateEventScreen(),
                            ),
                          );
                        },
                child: const Icon(Icons.add),
              )
              : null,
    );
  }
}
