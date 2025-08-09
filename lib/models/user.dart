import 'package:flutter_application_1/models/post.dart';

class User {
  var pfp;
  var username;
  List<Post> posts;
  var bio;

  User({this.pfp, this.username, required this.posts, this.bio});
}
