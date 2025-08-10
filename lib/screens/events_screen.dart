import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/event.dart';
import 'package:flutter_application_1/screens/create_event_screen.dart';
import 'package:flutter_application_1/screens/edit_event_screen.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
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
  final FirebaseService _svc = GetIt.instance<FirebaseService>();
  bool _isOrganiser = false;
  bool _loadingRole = true;
  bool _online = true;
  late TabController _tabController;
  CalendarFormat _calFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initRole();
    GetIt.instance<ConnectivityService>().isOnline$.listen((isOnline) {
      if (!mounted) return;
      setState(() => _online = isOnline);
    });
  }

  Future<void> _initRole() async {
    final isOrg = await _svc.isCurrentUserOrganiser();
    if (!mounted) return;
    setState(() {
      _isOrganiser = isOrg;
      _loadingRole = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final texttheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: SafeArea(
          child: TabBar(
            controller: _tabController,
            labelColor: scheme.primary,
            unselectedLabelColor: scheme.onSurfaceVariant,
            indicatorColor: scheme.primary,
            tabs: const [Tab(text: 'List'), Tab(text: 'Calendar')],
          ),
        ),
      ),
      body: StreamBuilder<List<Event>>(
        stream: _svc.getEventsAsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final events = snapshot.data ?? [];
          // Group events by day using startDateTime date
          final Map<DateTime, List<Event>> byDay = {};
          for (final e in events) {
            final dt = e.startDateTime!;
            final dayKey = DateTime(dt.year, dt.month, dt.day);
            byDay.putIfAbsent(dayKey, () => []).add(e);
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
              // normal view
              ListView.builder(
                itemCount: (events.isEmpty ? 1 : events.length) + 1,
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
                  if (events.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: Text('No events yet')),
                    );
                  }
                  final e = events[index - 1];
                  return EventWidget(
                    event: e,
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
                                      builder: (_) => const EditEventScreen(),
                                      settings: RouteSettings(arguments: e),
                                    ),
                                  );
                                } else if (value == 'delete') {
                                  await _svc.deleteEvent(e.id!);
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
                  );
                },
              ),
              // Calendar tab
              Column(
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
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    eventLoader: (day) {
                      final key = DateTime(day.year, day.month, day.day);
                      return byDay[key] ?? const [];
                    },
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
                            ? const Center(child: Text('No events this day'))
                            : ListView.builder(
                              itemCount: byDay[selectedDayKey]!.length,
                              itemBuilder: (context, idx) {
                                final e = byDay[selectedDayKey]![idx];
                                return EventWidget(
                                  event: e,
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
                                                        (_) =>
                                                            const EditEventScreen(),
                                                    settings: RouteSettings(
                                                      arguments: e,
                                                    ),
                                                  ),
                                                );
                                              } else if (value == 'delete') {
                                                await _svc.deleteEvent(e.id!);
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
