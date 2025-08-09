import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/post.dart';
import 'package:flutter_application_1/services/firebase_service.dart';

import 'package:flutter_application_1/widgets/post_widget.dart';

import 'package:flutter_application_1/models/user.dart';

import 'package:flutter_application_1/screens/settings_screen.dart';
import 'package:flutter_application_1/widgets/stat_card.dart';
import 'package:get_it/get_it.dart';

class ProfileScreen extends StatelessWidget {
  final FirebaseService firebaseService = GetIt.instance<FirebaseService>();

  ProfileScreen({super.key});

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
                    CircleAvatar(
                      radius: 80,
                      backgroundImage: NetworkImage(
                        "data:image/png;base64,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",
                      ),
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
                        ),
                      ),
                      SizedBox(height: 20),

                      Text(
                        "Activity",
                        style: TextStyle(
                          fontSize: texttheme.headlineMedium!.fontSize,
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
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => UserPostWidget(posts[index]),
                    childCount: posts.length,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
