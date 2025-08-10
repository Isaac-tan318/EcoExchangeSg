// core libs
import 'dart:async';
import 'dart:convert';

// platform and ui
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
// app models, services, utils, and widgets
import 'package:flutter_application_1/models/event_model.dart';
import 'package:flutter_application_1/screens/edit_event_screen.dart';
import 'package:flutter_application_1/utils/date_formats.dart';
import 'package:flutter_application_1/services/connectivity_service.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:flutter_application_1/services/tts_service.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_application_1/widgets/nets_qr_widget.dart';

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
  // listen to connectivity to handle offline mode
    _connSub = GetIt.instance<ConnectivityService>().isOnline$.listen((
      isOnline,
    ) {
      if (!mounted) return;
      setState(() => _online = isOnline);
    });
  // get shared tts instance
    _tts = GetIt.instance<TtsService>();
  // check if current user can modify this event
    _initRole();
  }

  Future<void> _initRole() async {
  // check if current user is an organiser
    final isOrg =
        await GetIt.instance<FirebaseService>().isCurrentUserOrganiser();
    if (!mounted) return;
    setState(() => _isOrganiser = isOrg);
  }

  @override
  void dispose() {
  // stop any ongoing speech and clean up subscriptions
    _tts?.stop();
    _connSub?.cancel();
    super.dispose();
  }

  // friendly date time for chips
  String _fmtDateTime(DateTime dt) => DateFormats.dMonthYHm(dt);

  Future<void> _reportEvent(Event e) async {
  // build email subject and body to report events
    final subject = Uri.encodeComponent('[Report] Event ${e.title ?? ''}');
    final body = Uri.encodeComponent(
      'Event ID: ${e.id ?? widget.eventId}\n'
      'Title: ${e.title ?? ''}\n'
      'Location: ${e.location ?? ''}\n\n'
      'Reason: Hello, I would like to report this event as ',
    );
    const toEmail = 'ecohubsg1@gmail.com';

  // on web use gmail compose
    if (kIsWeb) {
      final gmailUrl = Uri.parse(
        'https://mail.google.com/mail/?view=cm&fs=1&to=$toEmail&su=$subject&body=$body',
      );
      final ok = await launchUrl(
        gmailUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!ok && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open Gmail.')));
      }
      return;
    }

  // deeplink for mobile
    final gmailUris = <Uri>[
      Uri.parse('gmail://co?to=$toEmail&subject=$subject&body=$body'),
      Uri.parse('googlegmail://co?to=$toEmail&subject=$subject&body=$body'),
    ];
    for (final gmailUri in gmailUris) {
      final canOpen = await canLaunchUrl(gmailUri);
      if (canOpen) {
        final ok = await launchUrl(
          gmailUri,
          mode: LaunchMode.externalApplication,
        );
        if (ok) return;
      }
    }
  // fallback to default mail app
    final mailtoUri = Uri.parse('mailto:$toEmail?subject=$subject&body=$body');
    final ok = await launchUrl(mailtoUri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No email app available.')));
    }
  }

  @override
  Widget build(BuildContext context) {
  // theme and services
    final scheme = Theme.of(context).colorScheme;
    final texttheme = Theme.of(context).textTheme;
    final svc = GetIt.instance<FirebaseService>();

  // load the event for details
  return FutureBuilder<Event?>(
      future: svc.getEvent(widget.eventId),
      builder: (context, snapshot) {
        final appBar = AppBar(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          title: const Text('Event Details'),
          actions: [
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.data != null)
              IconButton(
                tooltip: 'Report',
                icon: const Icon(Icons.flag_outlined),
                onPressed: () => _reportEvent(snapshot.data!),
              ),
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.data != null)
              IconButton(
                tooltip: 'Listen',
                icon: const Icon(Icons.volume_up_outlined),
                onPressed: () {
          // speak the title and description
                  final eventData = snapshot.data!;
                  final title = (eventData.title?.toString().trim() ?? '');
                  final desc = (eventData.description?.toString().trim() ?? '');
                  final text = 'title: $title, description: $desc';
                  _tts?.speak(text);
                },
              ),
          ],
        );

    // loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: appBar,
            body: const Center(child: CircularProgressIndicator()),
          );
        }
    // error state
        if (snapshot.hasError) {
          return Scaffold(
            appBar: appBar,
            body: Center(child: Text('Failed to load: ${snapshot.error}')),
          );
        }
    // not found state
        final event = snapshot.data;
        if (event == null) {
          return Scaffold(
            appBar: appBar,
            body: const Center(child: Text('Event not found')),
          );
        }

    // make sure have permission to edit/delete
        final currentUid = svc.getCurrentUser()?.uid;
        final canModify = _isOrganiser && (event.authorId == currentUid);

    // layout orientation
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;

    // event image if present
        Widget imageWidget = const SizedBox.shrink();
        if ((event.imageBase64 ?? '').isNotEmpty) {
          imageWidget = ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.memory(
                const Base64Decoder().convert(event.imageBase64!),
                fit: BoxFit.cover,
              ),
            ),
          );
        }

    // right-side details column
        Widget detailsColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () {
          // open award modal with nets qr
                  showModalBottomSheet(
                    context: context,
                    showDragHandle: true,
                    isScrollControlled: true,
                    builder: (ctx) {
                      final scheme = Theme.of(ctx).colorScheme;
                      final textTheme = Theme.of(ctx).textTheme;
                      final isLandscape =
                          MediaQuery.of(ctx).orientation ==
                          Orientation.landscape;
            // short instructions and qr component
                      final instructions = Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Send an award', style: textTheme.titleLarge),
                          const SizedBox(height: 8),
                          Text(
                            'Scan the NETS QR to tip the organiser. Once paid, tap Register to confirm.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          NETSQR((BuildContext c) async {
                            try {
                // update awards for event and organiser
                              await GetIt.instance<FirebaseService>()
                                  .incrementEventAwards(widget.eventId);
                              // Also increment the organiser's user awards
                              final recipientId = event.authorId;
                              if (recipientId != null &&
                                  recipientId.toString().isNotEmpty) {
                                await GetIt.instance<FirebaseService>()
                                    .incrementUserAwards(recipientId);
                              }
                              if (mounted) Navigator.of(ctx).pop();
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Thanks for your award!'),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to record award: $e'),
                                ),
                              );
                            }
                          }),
                        ],
                      );
            // adapt layout for landscape
                      Widget content;
                      if (isLandscape) {
                        content = Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: NETSQR((_) {}, showInfoImage: false),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ...instructions.children,
                                  const SizedBox(height: 12),
                                  Image.asset(
                                    'assets/images/netsQrInfo.png',
                                    width: 420,
                                    fit: BoxFit.contain,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      } else {
                        content = instructions;
                      }
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        child: content,
                      );
                    },
                  );
                },
                icon: const Icon(Icons.card_giftcard),
                label: const Text('Award'),
              ),
            ),
            const SizedBox(height: 8),
      // event title
            Text(
              event.title?.toString() ?? '',
              style: TextStyle(
                fontSize: texttheme.headlineLarge!.fontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
      // edit and delete actions for organisers
            if (canModify)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed:
                        _deleting || !_online
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
                    label: Text(
                      'Edit',
                      style: TextStyle(color: scheme.primary),
                    ),
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
                      onPressed:
                          !_online
                              ? null
                              // confirm delete event
                              : () async {
                                final navigator = Navigator.of(context);
                                final messenger = ScaffoldMessenger.maybeOf(
                                  context,
                                );
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) {
                                    final scheme = Theme.of(ctx).colorScheme;
                                    final textTheme = Theme.of(ctx).textTheme;
                                    return AlertDialog(
                                      backgroundColor:
                                          scheme.surfaceContainerHigh,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: Text(
                                        'Delete Event',
                                        style: textTheme.titleLarge?.copyWith(
                                          color: scheme.onSurface,
                                        ),
                                      ),
                                      content: Text(
                                        'Are you sure you want to delete this event?',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.of(ctx).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed:
                                              () => Navigator.of(ctx).pop(true),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: scheme.error,
                                            foregroundColor: scheme.onError,
                                          ),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                                if (confirm != true) return;
                                setState(() => _deleting = true);
                                try {
                                  await svc.deleteEvent(widget.eventId);
                                  navigator.pop(true);
                                } catch (e) {
                                  if (!mounted) return;
                                  setState(() => _deleting = false);
                                  messenger?.showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to delete: $e'),
                                    ),
                                  );
                                }
                              },
                      icon: Icon(Icons.delete, color: scheme.error),
                      label: Text(
                        'Delete',
                        style: TextStyle(color: scheme.error),
                      ),
                    ),
                ],
              ),
            if (canModify) const SizedBox(height: 8),
      // date time chip
            if (event.startDateTime != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
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
      // location row
            if ((event.location ?? '').trim().isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.place, size: 18, color: scheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      event.location!.trim(),
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
      // description text
            Text(
              event.description?.toString() ?? '',
              style: TextStyle(fontSize: texttheme.bodyLarge!.fontSize),
            ),
          ],
        );

        return Scaffold(
          appBar: appBar,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child:
        // adapt layout for landscape and portrait
        isLandscape
                    ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((event.imageBase64 ?? '').isNotEmpty)
                          Expanded(child: imageWidget),
                        if ((event.imageBase64 ?? '').isNotEmpty)
                          const SizedBox(width: 16),
                        Expanded(flex: 2, child: detailsColumn),
                      ],
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        detailsColumn,
                        if ((event.imageBase64 ?? '').isNotEmpty) ...[
                          const SizedBox(height: 16),
                          imageWidget,
                        ],
                      ],
                    ),
          ),
        );
      },
    );
  }
}
