import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/post_model.dart';
import 'package:flutter_application_1/services/firebase_service.dart';

import 'package:flutter_application_1/widgets/post_widget.dart';

import 'package:flutter_application_1/models/user_model.dart';

import 'package:flutter_application_1/screens/settings_screen.dart';
import 'package:flutter_application_1/widgets/stat_card_widget.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:flutter_application_1/services/connectivity_service.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseService firebaseService = GetIt.instance<FirebaseService>();
  final ImagePicker _picker = ImagePicker();
  bool _online = true;
  StreamSubscription<bool>? _connSub;
  // sort and time filters for user's posts
  String _sort = 'New';
  String _timeFilter = 'All time';
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    // subscribe to connectivity updates for offline handling
    _connSub = GetIt.instance<ConnectivityService>().isOnline$.listen((
      isOnline,
    ) {
      if (!mounted) return;
      setState(() => _online = isOnline);
    });
  }

  @override
  void dispose() {
    // clean up subscription
    _connSub?.cancel();
    super.dispose();
  }

  Future<void> _changePfp() async {
    // pick an image from camera or gallery and update the profile picture
    if (!_online) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You are offline. Please reconnect to update your picture.',
          ),
        ),
      );
      return;
    }
    try {
      // show bottom sheet to select image source
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder:
            (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.photo_camera),
                    title: const Text('Camera'),
                    onTap: () => Navigator.pop(ctx, ImageSource.camera),
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Gallery'),
                    onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
      );
      if (source == null) return;
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2000,
        maxHeight: 2000,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final b64 = base64Encode(bytes);
      await firebaseService.updateCurrentUserProfile({'pfp': b64});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update picture: $e')));
    }
  }

  // format dates using intl (e.g., 1 january 2025)
  String _fmt(DateTime d) => DateFormat('d MMMM y').format(d);

  // get label for current time filter selection
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
    // listen to user profile stream
    return StreamBuilder<User>(
      stream: firebaseService.getUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          // log to console so you can copy any firestore index link from the error
          debugPrint('profile stream error: ${snapshot.error}');
          return Center(
            child: Text('Error loading profile: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return Center(child: Text('No user data available'));
        }

        var user = snapshot.data!;
        final username = (user.username?.toString() ?? 'Unknown User');
        final bio = (user.bio?.toString() ?? '');
        final pfpB64 = (user.pfp?.toString() ?? '');
        // decode base64 avatar when available
        ImageProvider? avatar;
        if (pfpB64.isNotEmpty) {
          try {
            avatar = MemoryImage(base64Decode(pfpB64));
          } catch (_) {}
        }

        return CustomScrollView(
          slivers: [
            // username and avatar
            SliverAppBar(
              automaticallyImplyLeading: false,
              expandedHeight: 250.0,
              pinned: true,
              backgroundColor: scheme.primary,

              actions: [
                // open settings
                IconButton(
                  icon: Icon(Icons.settings, color: scheme.onPrimary),
                  tooltip: 'Settings',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
              ],

              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                titlePadding: EdgeInsets.only(bottom: 0),
                title: Container(
                  padding: EdgeInsets.fromLTRB(50, 0, 50, 15),
                  decoration: BoxDecoration(color: scheme.primary),
                  child: Text(
                    username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onPrimary),
                  ),
                ),

                background: Column(
                  children: [
                    SizedBox(height: 20),
                    // profile picture
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 80,
                          backgroundImage: avatar,
                          child:
                              avatar == null
                                  ? const Icon(Icons.person, size: 64)
                                  : null,
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Material(
                            color: scheme.primary,
                            shape: const CircleBorder(),
                            child: IconButton(
                              icon: Icon(Icons.edit, color: scheme.onPrimary),
                              // edit photo button
                              onPressed: _changePfp,
                              tooltip: 'Change photo',
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            SliverList(
              // user bio and activity stats
              delegate: SliverChildListDelegate([
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: scheme.surfaceContainerHighest,
                  ),
                  padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
                  margin: EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bio,
                        style: TextStyle(
                          fontSize: texttheme.bodyLarge!.fontSize,
                          color: scheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 20),
                      // activity section with awards and post count
                      Text(
                        "Activity",
                        style: TextStyle(
                          fontSize: texttheme.headlineMedium!.fontSize,
                          color: scheme.onSurface,
                        ),
                      ),

                      SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          StatCard('Awards', user.awards.toString()),
                          // Showcount of this user's posts
                          FutureBuilder<int>(
                            future: firebaseService.countPosts(
                              authorId: firebaseService.getCurrentUser()?.uid,
                            ),
                            builder: (context, snap) {
                              final countText =
                                  snap.connectionState ==
                                          ConnectionState.waiting
                                      ? '…'
                                      : (snap.data ?? 0).toString();
                              return StatCard('Posts', countText);
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
                // section title for posts
                Padding(
                  padding: const EdgeInsets.only(left: 35, top: 15, bottom: 15),
                  child: Text(
                    "Posts",
                    style: TextStyle(
                      fontSize: texttheme.headlineMedium!.fontSize,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                // controls: sort and time filters for user's posts
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 15, 10),
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
                        initialSelection: _sort,
                        onSelected: (value) {
                          if (value == null) return;
                          setState(() => _sort = value);
                          // drop focus to dismiss keyboard/caret
                          FocusScope.of(context).unfocus();
                        },
                        dropdownMenuEntries: const [
                          DropdownMenuEntry(value: 'New', label: 'New'),
                          DropdownMenuEntry(value: 'Oldest', label: 'Oldest'),
                        ],
                      ),

                      DropdownMenu<String>(
                        width: 160,
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
                            // before date selection
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
                            // date range selection
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
                            // if user picked a start date, show end date picker
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
                          DropdownMenuEntry(
                            value: 'All time',
                            label: 'All time',
                          ),
                          DropdownMenuEntry(
                            value: 'after date',
                            label: 'after date',
                          ),
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

                // selected time summary
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
              ]),
            ),
            // stream the current user's posts from firestore and show them
            StreamBuilder<List<Post>>(
              stream: firebaseService.getAllPostsAsStream(
                authorId: firebaseService.getCurrentUser()?.uid,
                descending: _sort == 'New',
                startDate: _start,
                endDate: _end,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  debugPrint('profile posts stream error: ${snapshot.error}');
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text('Error loading posts: ${snapshot.error}'),
                      ),
                    ),
                  );
                }
                final posts = snapshot.data ?? [];
                if (posts.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: Text('No posts yet')),
                    ),
                  );
                }
                final isLandscape =
                    MediaQuery.of(context).orientation == Orientation.landscape;

                if (!isLandscape) {
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => UserPostWidget(posts[index]),
                      childCount: posts.length,
                    ),
                  );
                }
                // landscape: two posts per row, top-aligned like posts screen
                final rowsCount = (posts.length + 1) ~/ 2;
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, rowIndex) {
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
                          Expanded(child: UserPostWidget(posts[leftIndex])),
                          const SizedBox(width: 12),
                          Expanded(
                            child:
                                hasRight
                                    ? UserPostWidget(posts[rightIndex])
                                    : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    );
                  }, childCount: rowsCount),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
