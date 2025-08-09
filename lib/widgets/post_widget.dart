import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/post.dart';
import 'package:flutter_application_1/screens/edit_post_screen.dart';
import 'package:flutter_application_1/screens/posts_screen.dart';

class PostWidget extends StatelessWidget {
  Post post;
  PostWidget(this.post);

  @override
  Widget build(BuildContext context) {
    var scheme = Theme.of(context).colorScheme;
    var texttheme = Theme.of(context).textTheme;
    var nav = Navigator.of(context);
    var now = DateTime.now();

    return Container(
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
            post.title,
            style: TextStyle(
              fontSize: texttheme.headlineMedium!.fontSize,
              fontWeight: FontWeight.w100,
            ),
          ),
          SizedBox(height: 15),
          Text(
            post.description,
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
                  "${now.difference(post.date_posted).inHours} hr. ago",
                  style: TextStyle(
                    color: scheme.onSecondaryContainer,
                    fontSize: texttheme.bodyLarge!.fontSize,
                  ),
                ),
              ),
              Expanded(child: Container()),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: scheme.secondaryContainer,
                ),
                padding: EdgeInsets.all(10),
                child: Row(
                  children: [
                    Icon(Icons.thumb_up),
                    SizedBox(width: 10),
                    Text(
                      (post.likes - post.dislikes).toString(),
                      style: TextStyle(fontSize: texttheme.bodyLarge!.fontSize),
                    ),
                    SizedBox(width: 30),
                    Icon(Icons.thumb_down),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class UserPostWidget extends StatelessWidget {
  Post post;
  UserPostWidget(this.post);

  @override
  Widget build(BuildContext context) {
    var scheme = Theme.of(context).colorScheme;
    var texttheme = Theme.of(context).textTheme;
    var nav = Navigator.of(context);
    var now = DateTime.now();

    return Container(
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
                post.title,
                style: TextStyle(
                  fontSize: texttheme.headlineMedium!.fontSize,
                  fontWeight: FontWeight.w100,
                ),
              ),

              Expanded(child: Container()),

              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  nav.pushNamed(EditPost.routeName);
                },
              ),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text('Confirm Delete'),
                          content: Text('Are you sure you want to delete?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text('No'),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.error,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onError,
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('Yes'),
                            ),
                          ],
                        ),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 15),
          Text(
            post.description,
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
                  "${now.difference(post.date_posted).inHours} hr. ago",
                  style: TextStyle(
                    color: scheme.onSecondaryContainer,
                    fontSize: texttheme.bodyLarge!.fontSize,
                  ),
                ),
              ),
              Expanded(child: Container()),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: scheme.secondaryContainer,
                ),
                padding: EdgeInsets.all(10),
                child: Row(
                  children: [
                    Icon(Icons.thumb_up),
                    SizedBox(width: 10),
                    Text(
                      (post.likes - post.dislikes).toString(),
                      style: TextStyle(fontSize: texttheme.bodyLarge!.fontSize),
                    ),
                    SizedBox(width: 30),
                    Icon(Icons.thumb_down),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
