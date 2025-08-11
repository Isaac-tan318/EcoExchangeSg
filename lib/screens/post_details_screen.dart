import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/post_model.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_application_1/screens/edit_post_screen.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_application_1/services/connectivity_service.dart';
import 'package:flutter_application_1/services/tts_service.dart';
import 'dart:async';
import 'package:flutter_application_1/widgets/nets_qr_widget.dart';

class PostDetailsScreen extends StatefulWidget {
  static const routeName = '/postDetails';
  final String postId;

  const PostDetailsScreen({super.key, required this.postId});

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  bool _deleting = false;
  bool _online = true;
  TtsService? _tts;
  StreamSubscription<bool>? _connSub;

  @override
  void initState() {
    super.initState();
    // subscribe to connectivity updates
    _connSub = GetIt.instance<ConnectivityService>().isOnline$.listen((
      isOnline,
    ) {
      if (!mounted) return;
      setState(() => _online = isOnline);
    });

    // get shared tts service
    _tts = GetIt.instance<TtsService>();
  }

  @override
  void dispose() {
    // stop speech and cancel subscription
    _tts?.stop();
    _connSub?.cancel();
    super.dispose();
  }

  Future<void> _reportPost(Post post) async {
    final subject = Uri.encodeComponent('[Report] Post ${post.title ?? ''}');
    final body = Uri.encodeComponent(
      'Post ID: ${post.id ?? widget.postId}\n'
      'Title: ${post.title ?? ''}\n'
      'Author: ${post.poster ?? ''}\n\n'
      'Reason: Hello, I would like to report this post as ',
    );
    const toEmail = 'ecohubsg1@gmail.com';

    Future<bool> _openGmail() async {
      if (kIsWeb) {
        final url = Uri.parse(
          'https://mail.google.com/mail/?view=cm&fs=1&to=$toEmail&su=$subject&body=$body',
        );
        return launchUrl(url, mode: LaunchMode.externalApplication);
      }
      // Use the Gmail app
      final uris = <Uri>[
        Uri.parse('gmail://co?to=$toEmail&subject=$subject&body=$body'),
        Uri.parse('googlegmail://co?to=$toEmail&subject=$subject&body=$body'),
      ];
      for (final u in uris) {
        if (await canLaunchUrl(u)) {
          if (await launchUrl(u, mode: LaunchMode.externalApplication)) {
            return true;
          }
        }
      }
      return false;
    }

    Future<bool> _openOutlook() async {
      if (kIsWeb) {
        final url = Uri.parse(
          'https://outlook.office.com/mail/deeplink/compose?to=$toEmail&subject=$subject&body=$body',
        );
        return launchUrl(url, mode: LaunchMode.externalApplication);
      }
      final u = Uri.parse(
        'ms-outlook://compose?to=$toEmail&subject=$subject&body=$body',
      );
      if (await canLaunchUrl(u)) {
        return launchUrl(u, mode: LaunchMode.externalApplication);
      }
      return false;
    }

    Future<bool> _openYahoo() async {
      if (kIsWeb) {
        final url = Uri.parse(
          'https://compose.mail.yahoo.com/?to=$toEmail&subject=$subject&body=$body',
        );
        return launchUrl(url, mode: LaunchMode.externalApplication);
      }
      final u = Uri.parse(
        'ymail://mail/compose?to=$toEmail&subject=$subject&body=$body',
      );
      if (await canLaunchUrl(u)) {
        return launchUrl(u, mode: LaunchMode.externalApplication);
      }
      return false;
    }

    Future<bool> _openDefault() async {
      final mailtoUri = Uri.parse(
        'mailto:$toEmail?subject=$subject&body=$body',
      );
      return launchUrl(mailtoUri, mode: LaunchMode.externalApplication);
    }

    // present options to pick an email app
    if (!mounted) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.alternate_email),
                title: const Text('Gmail'),
                onTap: () => Navigator.pop(ctx, 'gmail'),
              ),
              ListTile(
                leading: const Icon(Icons.mail_outline),
                title: const Text('Outlook'),
                onTap: () => Navigator.pop(ctx, 'outlook'),
              ),
              ListTile(
                leading: const Icon(Icons.mark_email_read_outlined),
                title: const Text('Yahoo Mail'),
                onTap: () => Navigator.pop(ctx, 'yahoo'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Default Email (chooser)'),
                onTap: () => Navigator.pop(ctx, 'default'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (choice == null) return;

    bool ok = false;
    if (choice == 'gmail') ok = await _openGmail();
    if (!ok && choice == 'outlook') ok = await _openOutlook();
    if (!ok && choice == 'yahoo') ok = await _openYahoo();
    if (!ok && choice == 'default') ok = await _openDefault();
    // fallback chain if chosen app isn't available
    if (!ok) ok = await _openDefault();
    if (!ok) ok = await _openGmail();
    if (!ok) ok = await _openOutlook();
    if (!ok) ok = await _openYahoo();

    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No email app available.')));
    }
  }

  // get relative time string
  String _relativeTime(DateTime date) {
    final now = DateTime.now();
    var diff = now.difference(date);
    if (diff.isNegative) diff = Duration.zero;
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) {
      final hours = diff.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    }
    if (diff.inDays < 7) {
      final days = diff.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    }
    if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    }
    if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }
    final years = (diff.inDays / 365).floor();
    return '$years ${years == 1 ? 'year' : 'years'} ago';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final texttheme = Theme.of(context).textTheme;
    final service = GetIt.instance<FirebaseService>();

    return FutureBuilder<Post?>(
      future: service.getPost(widget.postId),
      builder: (context, snapshot) {
        final appBar = AppBar(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          title: const Text('Post Details'),
          actions: [
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.data != null)
              IconButton(
                tooltip: 'Report',
                icon: const Icon(Icons.flag_outlined),
                onPressed: () => _reportPost(snapshot.data!),
              ),
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.data != null)
              IconButton(
                tooltip: 'Listen',
                icon: const Icon(Icons.volume_up_outlined),
                onPressed: () {
                  final p = snapshot.data!;
                  final title = (p.title?.toString().trim() ?? '');
                  final desc = (p.description?.toString().trim() ?? '');
                  final text = 'title: $title, description: $desc';
                  _tts?.speak(text);
                },
              ),
          ],
        );

        // show loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: appBar,
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: appBar,
            body: Center(child: Text('Failed to load: ${snapshot.error}')),
          );
        }
        final post = snapshot.data;
        if (post == null) {
          return Scaffold(
            appBar: appBar,
            body: const Center(child: Text('Post not found')),
          );
        }

        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;

        Widget imageWidget = const SizedBox.shrink();
        if ((post.imageBase64 ?? '').isNotEmpty) {
          imageWidget = ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.memory(
                const Base64Decoder().convert(post.imageBase64!),
                fit: BoxFit.cover,
              ),
            ),
          );
        }

        // header segment without image, description is placed differently
        // in portrait vs landscape to preserve original order
        final List<Widget> headerWidgets = [
          Align(
            alignment: Alignment.centerRight,
            // nets qr button
            child: FilledButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  showDragHandle: true,
                  isScrollControlled: true,
                  builder: (ctx) {
                    final scheme = Theme.of(ctx).colorScheme;
                    final textTheme = Theme.of(ctx).textTheme;
                    final isLandscape =
                        MediaQuery.of(ctx).orientation == Orientation.landscape;
                    // common instructions column (without info image; placed conditionally)
                    final instructions = Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Send an award', style: textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                          'Scan the NETS QR to tip the creator. Once paid, tap Award to confirm.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        NETSQR((BuildContext c) async {
                          try {
                            await GetIt.instance<FirebaseService>()
                                .incrementPostAwards(widget.postId);
                            // Also increment the recipient user's awards count
                            final authorId = post.authorId;
                            if (authorId != null &&
                                authorId.toString().isNotEmpty) {
                              await GetIt.instance<FirebaseService>()
                                  .incrementUserAwards(authorId);
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
                                Text(
                                  'Send an award',
                                  style: textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Scan the NETS QR to tip the organiser. Once paid, tap Register to confirm.',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
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
          Text(
            post.title?.toString() ?? '',
            style: TextStyle(
              fontSize: texttheme.headlineLarge!.fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
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
                  _relativeTime(post.date_posted as DateTime),
                  style: TextStyle(
                    color: scheme.onSecondaryContainer,
                    fontSize: texttheme.bodyMedium!.fontSize,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if ((post.poster?.toString().trim() ?? '').isNotEmpty)
                Text(
                  'by ${post.poster}',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              const Spacer(),
              if (post.authorId == service.getCurrentUser()?.uid) ...[
                TextButton.icon(
                  onPressed:
                      _deleting || !_online
                          ? null
                          : () async {
                            final navigator = Navigator.of(context);
                            final updated = await navigator.pushNamed(
                              EditPost.routeName,
                              arguments: {
                                'postId': widget.postId,
                                'post': post,
                              },
                            );
                            if (updated == true && mounted) setState(() {});
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
                    onPressed:
                        !_online
                            ? null
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
                                      'Delete Post',
                                      style: textTheme.titleLarge?.copyWith(
                                        color: scheme.onSurface,
                                      ),
                                    ),
                                    content: Text(
                                      'Are you sure you want to delete this post?',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.of(ctx).pop(false),
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
                                await service.deletePost(widget.postId);
                                // Return to the previous screen instead of the very first (Login)
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
            ],
          ),
          const SizedBox(height: 16),
        ];

        return Scaffold(
          appBar: appBar,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child:
                isLandscape
                    ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((post.imageBase64 ?? '').isNotEmpty)
                          Expanded(child: imageWidget),
                        if ((post.imageBase64 ?? '').isNotEmpty)
                          const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...headerWidgets,
                              Text(
                                post.description?.toString() ?? '',
                                style: TextStyle(
                                  fontSize: texttheme.bodyLarge!.fontSize,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...headerWidgets,
                        if ((post.imageBase64 ?? '').isNotEmpty) ...[
                          const SizedBox(height: 16),
                          imageWidget,
                        ],
                        const SizedBox(height: 16),
                        Text(
                          post.description?.toString() ?? '',
                          style: TextStyle(
                            fontSize: texttheme.bodyLarge!.fontSize,
                          ),
                        ),
                      ],
                    ),
          ),
        );
      },
    );
  }
}
