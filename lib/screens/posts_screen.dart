import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/create_post_screen.dart';
import 'package:flutter_application_1/widgets/post_widget.dart';

import 'package:flutter_application_1/models/post.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

// ignore: must_be_immutable
class PostsScreen extends StatelessWidget {
  var posts = [
    Post(
      title: "Post title",
      description:
          "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in",
      likes: 100,
      dislikes: 1,
      poster: "John doe",
      date_posted: DateTime.now().subtract(Duration(days: 1)),
    ),
    Post(
      title: "Post title",
      description:
          "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in",
      likes: 100,
      dislikes: 1,
      poster: "John doe",
      date_posted: DateTime.now().subtract(Duration(days: 1)),
    ),
    Post(
      title: "Post title",
      description:
          "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in",
      likes: 100,
      dislikes: 1,
      poster: "John doe",
      date_posted: DateTime.now().subtract(Duration(days: 1)),
    ),
  ];

  PostsScreen({super.key});

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
                onSelected: (value) {},
                dropdownMenuEntries: const [
                  DropdownMenuEntry(value: 'New', label: 'New'),
                  DropdownMenuEntry(value: 'Likes', label: 'Likes'),
                  DropdownMenuEntry(value: 'Controversy', label: 'Controversy'),
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
          child: RefreshIndicator(
            onRefresh: () {
              return Future.value();
            },
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: posts.length,
              itemBuilder: (BuildContext context, int index) {
                var post = posts[index];
                return Slide(PostWidget(post));
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ignore: must_be_immutable
class Slide extends StatelessWidget {
  Widget child;
  Slide(this.child, {super.key});

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
              nav.pushNamed(CreatePost.routeName);
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
