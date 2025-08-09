import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/post.dart';
import 'package:flutter_application_1/screens/edit_post_screen.dart';
import 'package:flutter_application_1/screens/post_details_screen.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:get_it/get_it.dart';

String _relativeTime(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes} min ago';
  return '${diff.inHours} hr. ago';
}

class PostWidget extends StatelessWidget {
  final Post post;
  PostWidget(this.post);

  @override
  Widget build(BuildContext context) {
    var scheme = Theme.of(context).colorScheme;
    var texttheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () {
        if (post.id == null) return;
        Navigator.of(context).pushNamed(
          PostDetailsScreen.routeName,
          arguments: {'postId': post.id},
        );
      },
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 15, 20, 15),
        margin: EdgeInsets.fromLTRB(20, 0, 20, 15),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.title?.toString() ?? '',
              style: TextStyle(
                fontSize: texttheme.headlineMedium!.fontSize,
                fontWeight: FontWeight.w100,
              ),
            ),
            SizedBox(height: 15),
            Text(
              post.description?.toString() ?? '',
              style: TextStyle(fontSize: texttheme.bodyLarge!.fontSize),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: scheme.secondaryContainer,
                  ),
                  child: Text(
                    _relativeTime(post.date_posted),
                    style: TextStyle(
                      color: scheme.onSecondaryContainer,
                      fontSize: texttheme.bodyLarge!.fontSize,
                    ),
                  ),
                ),
                Expanded(child: Container()),
                // voting removed
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class UserPostWidget extends StatefulWidget {
  final Post post;
  UserPostWidget(this.post);

  @override
  State<UserPostWidget> createState() => _UserPostWidgetState();
}

class _UserPostWidgetState extends State<UserPostWidget> {
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    var scheme = Theme.of(context).colorScheme;
    var texttheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () {
        if (widget.post.id == null) return;
        Navigator.of(context).pushNamed(
          PostDetailsScreen.routeName,
          arguments: {'postId': widget.post.id},
        );
      },
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 15, 20, 15),
        margin: EdgeInsets.fromLTRB(20, 0, 20, 15),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.post.title?.toString() ?? '',
                  style: TextStyle(
                    fontSize: texttheme.headlineMedium!.fontSize,
                    fontWeight: FontWeight.w100,
                  ),
                ),

                Expanded(child: Container()),

                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed:
                      _deleting
                          ? null
                          : () {
                            if (widget.post.id == null) return;
                            Navigator.of(context).pushNamed(
                              EditPost.routeName,
                              arguments: {
                                'postId': widget.post.id,
                                'post': widget.post,
                              },
                            );
                          },
                ),
                _deleting
                    ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(scheme.error),
                      ),
                    )
                    : IconButton(
                      icon: Icon(Icons.delete, color: scheme.error),
                      onPressed: () async {
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
                        if (widget.post.id == null) return;
                        setState(() => _deleting = true);
                        try {
                          await GetIt.instance<FirebaseService>().deletePost(
                            widget.post.id,
                          );
                          if (!mounted) return;
                          // Rely on the posts stream to remove the item; no SnackBar to avoid deactivated context.
                        } catch (e) {
                          if (mounted) {
                            setState(() => _deleting = false);
                            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                              SnackBar(content: Text('Failed to delete: $e')),
                            );
                          }
                        }
                      },
                    ),
              ],
            ),
            SizedBox(height: 15),
            Text(
              widget.post.description?.toString() ?? '',
              style: TextStyle(fontSize: texttheme.bodyLarge!.fontSize),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 15),

            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: scheme.secondaryContainer,
                  ),
                  child: Text(
                    _relativeTime(widget.post.date_posted),
                    style: TextStyle(
                      color: scheme.onSecondaryContainer,
                      fontSize: texttheme.bodyLarge!.fontSize,
                    ),
                  ),
                ),
                Expanded(child: Container()),
                // voting removed
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// voting UI removed
