import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/event.dart';
import 'package:flutter_application_1/screens/create_event_screen.dart';
import 'package:flutter_application_1/screens/edit_event_screen.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_application_1/widgets/event_widget.dart';
import 'package:flutter_application_1/services/connectivity_service.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  static const routeName = '/events';
  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final FirebaseService _svc = GetIt.instance<FirebaseService>();
  bool _isOrganiser = false;
  bool _loadingRole = true;
  bool _online = true;

  @override
  void initState() {
    super.initState();
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
          return ListView.builder(
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
                              ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                                const SnackBar(
                                  content: Text('Offline: action unavailable'),
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
          );
        },
      ),
      floatingActionButton:
          (!_loadingRole && _isOrganiser)
              ? FloatingActionButton(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                onPressed: !_online
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
