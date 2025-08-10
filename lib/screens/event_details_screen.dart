import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/event.dart';
import 'package:flutter_application_1/screens/edit_event_screen.dart';
import 'package:flutter_application_1/services/connectivity_service.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:flutter_application_1/services/tts_service.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';

class EventDetailsScreen extends StatefulWidget {
  static const routeName = '/eventDetails';
  final String eventId;

  const EventDetailsScreen({super.key, required this.eventId});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool _deleting = false;
  bool _online = true;
  bool _isOrganiser = false;
  TtsService? _tts;
  StreamSubscription<bool>? _connSub;

  @override
  void initState() {
    super.initState();
    _connSub = GetIt.instance<ConnectivityService>().isOnline$.listen((isOnline) {
      if (!mounted) return;
      setState(() => _online = isOnline);
    });
    _tts = GetIt.instance<TtsService>();
    _initRole();
  }

  Future<void> _initRole() async {
    final isOrg = await GetIt.instance<FirebaseService>().isCurrentUserOrganiser();
    if (!mounted) return;
    setState(() => _isOrganiser = isOrg);
  }

  @override
  void dispose() {
    _tts?.stop();
    _connSub?.cancel();
    super.dispose();
  }

  String _fmtDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString().padLeft(4, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $hh:$mm';
  }

  Future<void> _reportEvent(Event e) async {
    final subject = Uri.encodeComponent('[Report] Event ${e.title ?? ''}');
    final body = Uri.encodeComponent(
      'Event ID: ${e.id ?? widget.eventId}\n'
      'Title: ${e.title ?? ''}\n'
      'Location: ${e.location ?? ''}\n\n'
      'Reason: Hello, I would like to report this event as ',
    );
    const toEmail = 'ecohubsg1@gmail.com';

    if (kIsWeb) {
      final gmailUrl = Uri.parse('https://mail.google.com/mail/?view=cm&fs=1&to=$toEmail&su=$subject&body=$body');
      final ok = await launchUrl(gmailUrl, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open Gmail.')));
      }
      return;
    }

    final gmailUris = <Uri>[
      Uri.parse('gmail://co?to=$toEmail&subject=$subject&body=$body'),
      Uri.parse('googlegmail://co?to=$toEmail&subject=$subject&body=$body'),
    ];
    for (final u in gmailUris) {
      final canOpen = await canLaunchUrl(u);
      if (canOpen) {
        final ok = await launchUrl(u, mode: LaunchMode.externalApplication);
        if (ok) return;
      }
    }
    final mailtoUri = Uri.parse('mailto:$toEmail?subject=$subject&body=$body');
    final ok = await launchUrl(mailtoUri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No email app available.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final texttheme = Theme.of(context).textTheme;
    final svc = GetIt.instance<FirebaseService>();

    return FutureBuilder<Event?>(
      future: svc.getEvent(widget.eventId),
      builder: (context, snapshot) {
        final appBar = AppBar(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          title: const Text('Event Details'),
          actions: [
            if (snapshot.connectionState == ConnectionState.done && snapshot.data != null)
              IconButton(
                tooltip: 'Report',
                icon: const Icon(Icons.flag_outlined),
                onPressed: () => _reportEvent(snapshot.data!),
              ),
            if (snapshot.connectionState == ConnectionState.done && snapshot.data != null)
              IconButton(
                tooltip: 'Listen',
                icon: const Icon(Icons.volume_up_outlined),
                onPressed: () {
                  final e = snapshot.data!;
                  final title = (e.title?.toString().trim() ?? '');
                  final desc = (e.description?.toString().trim() ?? '');
                  final text = 'title: $title, description: $desc';
                  _tts?.speak(text);
                },
              ),
          ],
        );

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(appBar: appBar, body: const Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(appBar: appBar, body: Center(child: Text('Failed to load: ${snapshot.error}')));
        }
        final event = snapshot.data;
        if (event == null) {
          return Scaffold(appBar: appBar, body: const Center(child: Text('Event not found')));
        }

        final currentUid = svc.getCurrentUser()?.uid;
        final canModify = _isOrganiser && (event.authorId == currentUid);

        return Scaffold(
          appBar: appBar,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title?.toString() ?? '',
                  style: TextStyle(
                    fontSize: texttheme.headlineLarge!.fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (canModify)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: _deleting || !_online
                            ? null
                            : () async {
                                final navigator = Navigator.of(context);
                                await navigator.push(
                                  MaterialPageRoute(
                                    builder: (_) => const EditEventScreen(),
                                    settings: RouteSettings(arguments: event),
                                  ),
                                );
                                if (mounted) setState(() {});
                              },
                        icon: Icon(Icons.edit, color: scheme.primary),
                        label: Text('Edit', style: TextStyle(color: scheme.primary)),
                      ),
                      const SizedBox(width: 8),
                      if (_deleting)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(scheme.error),
                          ),
                        )
                      else
                        TextButton.icon(
                          onPressed: !_online
                              ? null
                              : () async {
                                  final navigator = Navigator.of(context);
                                  final messenger = ScaffoldMessenger.maybeOf(context);
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete Event'),
                                      content: const Text('Are you sure you want to delete this event?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                        TextButton(
                                          onPressed: () => Navigator.of(ctx).pop(true),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Theme.of(ctx).colorScheme.onError,
                                            backgroundColor: Theme.of(ctx).colorScheme.error,
                                          ),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm != true) return;
                                  setState(() => _deleting = true);
                                  try {
                                    await svc.deleteEvent(widget.eventId);
                                    navigator.pop(true);
                                  } catch (e) {
                                    if (!mounted) return;
                                    setState(() => _deleting = false);
                                    messenger?.showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
                                  }
                                },
                          icon: Icon(Icons.delete, color: scheme.error),
                          label: Text('Delete', style: TextStyle(color: scheme.error)),
                        ),
                    ],
                  ),
                if (canModify) const SizedBox(height: 8),
                if (event.startDateTime != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      event.endDateTime != null
                          ? '${_fmtDateTime(event.startDateTime!)} — ${_fmtDateTime(event.endDateTime!)}'
                          : _fmtDateTime(event.startDateTime!),
                      style: TextStyle(
                        color: scheme.onSecondaryContainer,
                        fontSize: texttheme.bodyMedium!.fontSize,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                if ((event.location ?? '').trim().isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.place, size: 18, color: scheme.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(event.location!.trim(), style: TextStyle(color: scheme.onSurfaceVariant)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                if ((event.imageBase64 ?? '').isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Image.memory(
                        const Base64Decoder().convert(event.imageBase64!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  event.description?.toString() ?? '',
                  style: TextStyle(fontSize: texttheme.bodyLarge!.fontSize),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
