import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/event.dart';
import 'package:flutter_application_1/screens/create_event_screen.dart';
import 'package:flutter_application_1/screens/edit_event_screen.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:get_it/get_it.dart';

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

  @override
  void initState() {
    super.initState();
    _initRole();
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

    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
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
          if (events.isEmpty) {
            return const Center(child: Text('No events yet'));
          }
          return ListView.separated(
            itemCount: events.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final e = events[index];
              return ListTile(
                title: Text(e.title ?? 'Untitled'),
                subtitle: Text(
                  [
                    if (e.location != null) e.location!,
                    if (e.startDateTime != null)
                      '${e.startDateTime}'.replaceFirst('.000', ''),
                  ].join(' • '),
                ),
                trailing:
                    _isOrganiser
                        ? PopupMenuButton<String>(
                          onSelected: (value) async {
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
                onPressed: () {
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
