import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/create_post_screen.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_application_1/widgets/post_widget.dart';

import 'package:flutter_application_1/models/post_model.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_application_1/services/connectivity_service.dart';
import 'package:get_it/get_it.dart' as gi;
import 'package:intl/intl.dart';

// ignore: must_be_immutable
class PostsScreen extends StatefulWidget {
  PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  final FirebaseService firebaseService = GetIt.instance<FirebaseService>();
  String _sort = 'New';
  String _timeFilter = 'All time';
  DateTime? _start;
  DateTime? _end;
  bool _online = true;

  @override
  void initState() {
    super.initState();
    gi.GetIt.instance<ConnectivityService>().isOnline$.listen((isOnline) {
      if (!mounted) return;
      setState(() => _online = isOnline);
    });
  }

  String _fmt(DateTime d) {
    // use intl for locale-aware date formatting (e.g., 1 January 2025)
    return DateFormat('d MMMM y').format(d);
  }

  String _timeLabel() {
    switch (_timeFilter) {
      case 'after date':
        return _start != null ? 'After ${_fmt(_start!)}' : 'After: —';
      case 'before date':
        return _end != null ? 'Before ${_fmt(_end!)}' : 'Before: —';
      case 'from date to date':
        if (_start != null && _end != null) {
          return 'From ${_fmt(_start!)} to ${_fmt(_end!)}';
        }
        return 'From: — to —';
      default:
        return 'All time';
    }
  }

  @override
  Widget build(BuildContext context) {
    var scheme = Theme.of(context).colorScheme;
    var texttheme = Theme.of(context).textTheme;
    var nav = Navigator.of(context);

    // Tap anywhere to unfocus (useful when dropdowns grab focus)
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        children: [
          // Create post
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
            child: ElevatedButton(
              onPressed:
                  !_online
                      ? null
                      : () {
                        nav.pushNamed(CreatePost.routeName);
                      },

              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
              ),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: scheme.onPrimaryContainer,
                    radius: 14,
                    child: CircleAvatar(radius: 12, child: Icon(Icons.add)),
                  ),

                  Text(
                    "Create post",
                    style: TextStyle(
                      fontSize: texttheme.headlineSmall!.fontSize,
                      fontFamily: 'Outfit-Regular',
                    ),
                  ),

                  Container(),
                ],
              ),
            ),
          ),

          // Sort posts
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 15, 15, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownMenu<String>(
                  width: 140,
                  menuStyle: MenuStyle(
                    backgroundColor: WidgetStatePropertyAll(
                      scheme.tertiaryContainer,
                    ),
                  ),
                  textStyle: TextStyle(color: scheme.onTertiaryContainer),
                  inputDecorationTheme: InputDecorationTheme(
                    filled: true,
                    fillColor: scheme.tertiaryContainer,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  hintText: 'Sort by',
                  // initialSelection: 'New',
                  initialSelection: _sort,
                  onSelected: (value) {
                    if (value == null) return;
                    setState(() => _sort = value);
                    // Drop focus to avoid lingering caret/keyboard
                    FocusScope.of(context).unfocus();
                  },
                  dropdownMenuEntries: const [
                    DropdownMenuEntry(value: 'New', label: 'New'),
                    DropdownMenuEntry(value: 'Oldest', label: 'Oldest'),
                  ],
                ),

                // filter by date
                DropdownMenu<String>(
                  width: 140,
                  menuStyle: MenuStyle(
                    backgroundColor: WidgetStatePropertyAll(
                      scheme.tertiaryContainer,
                    ),
                  ),
                  textStyle: TextStyle(color: scheme.onTertiaryContainer),
                  inputDecorationTheme: InputDecorationTheme(
                    filled: true,
                    fillColor: scheme.tertiaryContainer,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),

                  hintText: 'Time',
                  initialSelection: _timeFilter,
                  onSelected: (value) async {
                    if (value == null) return;
                    if (value == 'after date') {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _start ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _timeFilter = value;
                          _start = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                          );
                          _end = null;
                        });
                        FocusScope.of(context).unfocus();
                      }
                    } else if (value == 'before date') {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _end ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _timeFilter = value;
                          _end = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                            23,
                            59,
                            59,
                            999,
                          );
                          _start = null;
                        });
                        FocusScope.of(context).unfocus();
                      }
                    } else if (value == 'from date to date') {
                      final startPicked = await showDatePicker(
                        context: context,
                        initialDate: _start ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        helpText: 'Select start date',
                        confirmText: 'Next',
                        cancelText: 'Cancel',
                      );
                      if (startPicked == null) return;
                      final endPicked = await showDatePicker(
                        context: context,
                        initialDate: _end ?? startPicked,
                        firstDate: startPicked,
                        lastDate: DateTime(2100),
                        helpText: 'Select end date',
                        confirmText: 'Apply',
                        cancelText: 'Back',
                      );
                      if (endPicked != null) {
                        setState(() {
                          _timeFilter = value;
                          _start = DateTime(
                            startPicked.year,
                            startPicked.month,
                            startPicked.day,
                          );
                          _end = DateTime(
                            endPicked.year,
                            endPicked.month,
                            endPicked.day,
                            23,
                            59,
                            59,
                            999,
                          );
                        });
                        FocusScope.of(context).unfocus();
                      }
                    } else {
                      setState(() {
                        _timeFilter = 'All time';
                        _start = null;
                        _end = null;
                      });
                      FocusScope.of(context).unfocus();
                    }
                  },
                  dropdownMenuEntries: const [
                    DropdownMenuEntry(value: 'All time', label: 'All time'),
                    DropdownMenuEntry(value: 'after date', label: 'after date'),
                    DropdownMenuEntry(
                      value: 'before date',
                      label: 'before date',
                    ),
                    DropdownMenuEntry(
                      value: 'from date to date',
                      label: 'Date range (start to end)',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Selected time summary
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _timeLabel(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),

          // show posts
          Expanded(
            child: StreamBuilder<List<Post>>(
              stream: firebaseService.getAllPostsAsStream(
                descending: _sort == 'New',
                startDate: _start,
                endDate: _end,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                List<Post> posts = List.of(snapshot.data ?? []);
                // client-side only if author filter is used elsewhere
                if (posts.isEmpty) {
                  return const Center(child: Text('No posts yet'));
                }
                final isLandscape =
                    MediaQuery.of(context).orientation == Orientation.landscape;

                Widget buildPostTile(Post post) {
                  final poster = (post.poster ?? '').toString().trim();
                  final mention = poster.isEmpty ? '' : '@$poster ';
                  return Slide(
                    PostWidget(post),
                    initialReplyTitle: mention,
                    mentionAuthorId: (post.authorId ?? '').toString(),
                    online: _online,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {},
                  child:
                      !isLandscape
                          ? ListView.builder(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            shrinkWrap: true,
                            itemCount: posts.length,
                            itemBuilder: (BuildContext context, int index) {
                              final post = posts[index];
                              return buildPostTile(post);
                            },
                          )
                          : ListView.builder(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            shrinkWrap: true,
                            itemCount: (posts.length + 1) ~/ 2,
                            itemBuilder: (BuildContext context, int rowIndex) {
                              final leftIndex = rowIndex * 2;
                              final rightIndex = leftIndex + 1;
                              final hasRight = rightIndex < posts.length;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 6.0,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: buildPostTile(posts[leftIndex]),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child:
                                          hasRight
                                              ? buildPostTile(posts[rightIndex])
                                              : const SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: must_be_immutable
class Slide extends StatelessWidget {
  final Widget child;
  final String? initialReplyTitle;
  final String? mentionAuthorId;
  final bool online;
  const Slide(
    this.child, {
    super.key,
    this.initialReplyTitle,
    this.mentionAuthorId,
    required this.online,
  });

  @override
  Widget build(BuildContext context) {
    var nav = Navigator.of(context);

    return Slidable(
      startActionPane: ActionPane(
        motion: const ScrollMotion(),

        children: [
          SlidableAction(
            onPressed: (context) {
              if (!online) {
                ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                  const SnackBar(content: Text('Offline: action unavailable')),
                );
                return;
              }
              nav.pushNamed(
                CreatePost.routeName,
                arguments: {
                  'initialTitle': initialReplyTitle ?? '',
                  'mentionAuthorId': mentionAuthorId ?? '',
                },
              );
            },

            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Theme.of(context).colorScheme.onSecondary,
            icon: Icons.reply,
            label: 'Reply',
          ),
        ],
      ),

      child: child,
    );
  }
}
