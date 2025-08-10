import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/post.dart';
import 'package:flutter_application_1/services/firebase_service.dart';

import 'package:flutter_application_1/widgets/post_widget.dart';

import 'package:flutter_application_1/models/user.dart';

import 'package:flutter_application_1/screens/settings_screen.dart';
import 'package:flutter_application_1/widgets/stat_card.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:flutter_application_1/services/connectivity_service.dart';
import 'dart:async';

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

  @override
  void initState() {
    super.initState();
    _connSub = GetIt.instance<ConnectivityService>().isOnline$.listen((
      isOnline,
    ) {
      if (!mounted) return;
      setState(() => _online = isOnline);
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }

  Future<void> _changePfp() async {
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
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
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

  @override
  Widget build(BuildContext context) {
    var scheme = Theme.of(context).colorScheme;
    var texttheme = Theme.of(context).textTheme;

    return StreamBuilder<User>(
      stream: firebaseService.getUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
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
        ImageProvider? avatar;
        if (pfpB64.isNotEmpty) {
          try {
            avatar = MemoryImage(base64Decode(pfpB64));
          } catch (_) {}
        }

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              automaticallyImplyLeading: false,
              expandedHeight: 250.0,
              pinned: true,
              backgroundColor: scheme.primary,

              actions: [
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
                    style: TextStyle(color: scheme.onPrimary),
                  ),
                ),

                background: Column(
                  children: [
                    SizedBox(height: 20),
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
                          StatCard('Awards', '1'),
                          // Show Firestore-backed count of this user's posts
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
              ]),
            ),
            // Stream the current user's posts from Firestore and show them
            StreamBuilder<List<Post>>(
              stream: firebaseService.getAllPostsAsStream(
                authorId: firebaseService.getCurrentUser()?.uid,
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

                // Landscape: two posts per row, top-aligned like Posts screen
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
