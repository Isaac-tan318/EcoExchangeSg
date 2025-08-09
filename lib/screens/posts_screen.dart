import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/create_post_screen.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_application_1/widgets/post_widget.dart';

import 'package:flutter_application_1/models/post.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

// ignore: must_be_immutable
class PostsScreen extends StatefulWidget {
  PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  final FirebaseService firebaseService = GetIt.instance<FirebaseService>();
  String _sort = 'New';

  @override
  Widget build(BuildContext context) {
    var scheme = Theme.of(context).colorScheme;
    var texttheme = Theme.of(context).textTheme;
    var nav = Navigator.of(context);

    return Column(
      children: [
        // Create post
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
          child: ElevatedButton(
            onPressed: () {
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
                },
                dropdownMenuEntries: const [
                  DropdownMenuEntry(value: 'New', label: 'New'),
                ],
              ),

              DropdownMenu<String>(
                width: 130,
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
                onSelected: (value) {
                  print('Selected: $value');
                },
                dropdownMenuEntries: const [
                  DropdownMenuEntry(value: 'All time', label: 'All time'),
                  DropdownMenuEntry(value: 'after date', label: 'after date'),
                  DropdownMenuEntry(value: 'before date', label: 'before date'),
                  DropdownMenuEntry(
                    value: 'from date to date',
                    label: 'from date to date',
                  ),
                ],
              ),
            ],
          ),
        ),

        // show posts
        Expanded(
          child: StreamBuilder<List<Post>>(
            stream: firebaseService.getAllPostsAsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              List<Post> posts = List.of(snapshot.data ?? []);
              // Apply client-side sorting for now
              // Only sort by New now
              posts.sort(
                (a, b) => (b.date_posted as DateTime).compareTo(
                  a.date_posted as DateTime,
                ),
              );
              if (posts.isEmpty) {
                return const Center(child: Text('No posts yet'));
              }
              return RefreshIndicator(
                onRefresh: () async {},
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: posts.length,
                  itemBuilder: (BuildContext context, int index) {
                    final post = posts[index];
                    final poster = (post.poster ?? '').toString().trim();
                    final mention = poster.isEmpty ? '' : '@$poster ';
                    return Slide(
                      PostWidget(post),
                      initialReplyTitle: mention,
                      mentionAuthorId: (post.authorId ?? '').toString(),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ignore: must_be_immutable
class Slide extends StatelessWidget {
  final Widget child;
  final String? initialReplyTitle;
  final String? mentionAuthorId;
  const Slide(
    this.child, {
    super.key,
    this.initialReplyTitle,
    this.mentionAuthorId,
  });

  @override
  Widget build(BuildContext context) {
    var nav = Navigator.of(context);

    return Slidable(
      key: const ValueKey(0),

      startActionPane: ActionPane(
        motion: const ScrollMotion(),

        children: [
          SlidableAction(
            onPressed: (context) {
              nav.pushNamed(
                CreatePost.routeName,
                arguments: {
                  'initialTitle': initialReplyTitle ?? '',
                  'mentionAuthorId': mentionAuthorId ?? '',
                },
              );
            },

            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            icon: Icons.reply,
            label: 'Reply',
          ),
        ],
      ),

      child: child,
    );
  }
}
