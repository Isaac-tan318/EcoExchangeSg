import 'package:flutter_application_1/models/post_model.dart';

class User {
  var pfp;
  var username;
  List<Post> posts;
  var bio;
  int awards;

  User({
    this.pfp,
    this.username,
    required this.posts,
    this.bio,
    this.awards = 0,
  });
}
