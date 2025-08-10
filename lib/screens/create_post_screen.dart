import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/models/post_model.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:flutter_application_1/widgets/post_form_widget.dart';
import 'package:get_it/get_it.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_1/services/connectivity_service.dart';

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
  String? _imageBase64;
  final ImagePicker _picker = ImagePicker();
  bool _online = true;

  final FirebaseService firebaseService = GetIt.instance<FirebaseService>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to connectivity for offline mode handling
    GetIt.instance<ConnectivityService>().isOnline$.listen((isOnline) {
      if (!mounted) return;
      setState(() => _online = isOnline);
    });
    final args = ModalRoute.of(context)?.settings.arguments;

    // used for reply feature, automatically fills up title with @(user ur replying to)
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

  // submit post

  Future<void> _submit(BuildContext context) async {
    if (!_online) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are offline. Please reconnect to post.'),
        ),
      );
      return;
    }
    final nav = Navigator.of(context);
    if (!_formKey.currentState!.validate()) return;

    // loading state
    setState(() => _submitting = true);
    try {
      await firebaseService.createPost(
        Post(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          imageBase64: _imageBase64,
        ),
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

  // image picker
  Future<void> _pickImage() async {
    if (!_online) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offline: cannot pick images.')),
      );
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
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
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2000,
        maxHeight: 2000,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() => _imageBase64 = base64Encode(bytes));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    var scheme = Theme.of(context).colorScheme;
    var texttheme = Theme.of(context).textTheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
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
            onPressed: _submitting || !_online ? null : () => _submit(context),
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
          onPressed: _pickImage,
          style: ElevatedButton.styleFrom(
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            padding: EdgeInsets.fromLTRB(15, 15, 15, 15),
          ),
          icon: CircleAvatar(
            backgroundColor: scheme.onPrimaryContainer,
            radius: 14,
            child: CircleAvatar(
              radius: 12,
              child: Icon(Icons.add_photo_alternate),
            ),
          ),
          label: Text(_imageBase64 == null ? "Add Image" : "Change Image"),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      body: SafeArea(
        child: LayoutBuilder(
          builder:
              (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child:
                      isLandscape
                          ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_imageBase64 != null &&
                                  _imageBase64!.isNotEmpty)
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: AspectRatio(
                                      aspectRatio: 1,
                                      child: Image.memory(
                                        const Base64Decoder().convert(
                                          _imageBase64!,
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              if (_imageBase64 != null &&
                                  _imageBase64!.isNotEmpty)
                                const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: PostForm(
                                  formKey: _formKey,
                                  titleController: _titleCtrl,
                                  descriptionController: _descCtrl,
                                  imageBase64: _imageBase64,
                                  showImage: false,
                                ),
                              ),
                            ],
                          )
                          : PostForm(
                            formKey: _formKey,
                            titleController: _titleCtrl,
                            descriptionController: _descCtrl,
                            imageBase64: _imageBase64,
                          ),
                ),
              ),
        ),
      ),
    );
  }
}
