import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/post.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_application_1/screens/edit_post_screen.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_application_1/services/connectivity_service.dart';

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

  @override
  void initState() {
    super.initState();
    GetIt.instance<ConnectivityService>().isOnline$.listen((isOnline) {
      if (!mounted) return;
      setState(() => _online = isOnline);
    });
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

    // different uris used by different devices
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No email app available.')));
    }
  }

  String _relativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    return '${diff.inHours} hr. ago';
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
          ],
        );

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

        return Scaffold(
          appBar: appBar,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                                  if (updated == true && mounted)
                                    setState(() {});
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                              scheme.error,
                            ),
                          ),
                        )
                      else
                        TextButton.icon(
                          onPressed: !_online
                              ? null
                              : () async {
                            final navigator = Navigator.of(context);
                            final messenger = ScaffoldMessenger.maybeOf(
                              context,
                            );
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder:
                                  (ctx) => AlertDialog(
                                    title: const Text('Delete Post'),
                                    content: const Text(
                                      'Are you sure you want to delete this post?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.of(ctx).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () => Navigator.of(ctx).pop(true),
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              Theme.of(ctx).colorScheme.onError,
                                          backgroundColor:
                                              Theme.of(ctx).colorScheme.error,
                                        ),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
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
                                SnackBar(content: Text('Failed to delete: $e')),
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
                if ((post.imageBase64 ?? '').isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Image.memory(
                        const Base64Decoder().convert(post.imageBase64!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  post.description?.toString() ?? '',
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
