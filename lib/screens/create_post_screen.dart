import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/models/post.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:flutter_application_1/widgets/post_form.dart';
import 'package:get_it/get_it.dart';

class CreatePost extends StatefulWidget {
  static var routeName = "/createPost";

  const CreatePost({super.key});

  @override
  State<CreatePost> createState() => _CreatePostState();
}

class _CreatePostState extends State<CreatePost> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _submitting = false;

  final FirebaseService firebaseService = GetIt.instance<FirebaseService>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      final initialTitle = (args['initialTitle'] ?? '') as String;
      final mentionAuthorId = (args['mentionAuthorId'] ?? '') as String;
      if (_titleCtrl.text.isEmpty) {
        _titleCtrl.text = initialTitle;
      }
      if (mentionAuthorId.isNotEmpty) {
        // Fetch username and ensure it is prefixed in title
        FirebaseFirestore.instance
            .collection('users')
            .doc(mentionAuthorId)
            .get()
            .then((doc) {
              final uname = doc.data()?['username'];
              if (uname is String && uname.trim().isNotEmpty) {
                final mention = '@${uname.trim()} ';
                if (!_titleCtrl.text.startsWith(mention)) {
                  _titleCtrl.text = '$mention${_titleCtrl.text}';
                }
              }
            })
            .catchError((_) {});
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    final nav = Navigator.of(context);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      await firebaseService.createPost(
        // Using the simple Post model shape in this project
        Post(title: _titleCtrl.text.trim(), description: _descCtrl.text.trim()),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Post created')));
        nav.pushReplacementNamed(HomeScreen.routeName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create post: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    var scheme = Theme.of(context).colorScheme;
    var texttheme = Theme.of(context).textTheme;
    // Navigator instance obtained where needed

    return Scaffold(
      appBar: AppBar(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        title: Text(
          "Create Post",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: texttheme.headlineMedium!.fontSize,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: _submitting ? null : () => _submit(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.tertiaryContainer,
              foregroundColor: scheme.onTertiaryContainer,
            ),
            child:
                _submitting
                    ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          scheme.onTertiaryContainer,
                        ),
                      ),
                    )
                    : const Text("Post"),
          ),
          const SizedBox(width: 20),
        ],
      ),

      // add image
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 15),
        child: ElevatedButton.icon(
          onPressed: () {},

          style: ElevatedButton.styleFrom(
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            padding: EdgeInsets.fromLTRB(15, 15, 15, 15),
          ),
          icon: CircleAvatar(
            backgroundColor: scheme.onPrimaryContainer,
            radius: 14,
            child: CircleAvatar(radius: 12, child: Icon(Icons.add)),
          ),

          label: Text("Add Image"),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      body: PostForm(
        formKey: _formKey,
        titleController: _titleCtrl,
        descriptionController: _descCtrl,
      ),
    );
  }
}
