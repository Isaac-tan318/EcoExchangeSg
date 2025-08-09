import 'package:flutter_application_1/models/post.dart';
import 'package:flutter_application_1/screens/posts_screen.dart';

class User {
  var pfp;
  var username;
  List<Post> posts;
  var likes;
  var bio;

  User({this.pfp, this.username, required this.posts, this.likes, this.bio});
}
