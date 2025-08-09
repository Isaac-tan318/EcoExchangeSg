import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/post.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_application_1/screens/edit_post_screen.dart';
import 'dart:convert';

class PostDetailsScreen extends StatefulWidget {
  static const routeName = '/postDetails';
  final String postId;

  const PostDetailsScreen({super.key, required this.postId});

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  bool _deleting = false;

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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        title: const Text('Post Details'),
      ),
      body: FutureBuilder<Post?>(
        future: service.getPost(widget.postId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load: ${snapshot.error}'));
          }
          final post = snapshot.data;
          if (post == null) {
            return const Center(child: Text('Post not found'));
          }

          // Directly show the poster's username stored on the post
          return SingleChildScrollView(
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
                            _deleting
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
                          onPressed: () async {
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
                              navigator.popUntil((route) => route.isFirst);
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
          );
        },
      ),
    );
  }
}
