import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/post.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:flutter_application_1/widgets/post_form.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_application_1/services/connectivity_service.dart';

class EditPost extends StatefulWidget {
  static const routeName = '/editPost';
  final String postId;
  final Post initial;

  const EditPost({super.key, required this.postId, required this.initial});

  @override
  State<EditPost> createState() => _EditPostState();
}

class _EditPostState extends State<EditPost> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  bool _saving = false;
  bool _online = true;

  final _service = GetIt.instance<FirebaseService>();

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(
      text: widget.initial.title?.toString() ?? '',
    );
    _descCtrl = TextEditingController(
      text: widget.initial.description?.toString() ?? '',
    );
    // Subscribe to connectivity changes
    GetIt.instance<ConnectivityService>().isOnline$.listen((isOnline) {
      if (!mounted) return;
      setState(() => _online = isOnline);
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_online) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are offline. Please reconnect to save.'),
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _service.updatePost(
        widget.postId,
        Post(title: _titleCtrl.text.trim(), description: _descCtrl.text.trim()),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Post updated')));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final texttheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        title: Text(
          'Edit Post',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: texttheme.headlineMedium!.fontSize,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: _saving || !_online ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.tertiaryContainer,
              foregroundColor: scheme.onTertiaryContainer,
            ),
            child:
                _saving
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Save'),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: PostForm(
        formKey: _formKey,
        titleController: _titleCtrl,
        descriptionController: _descCtrl,
        imageBase64: widget.initial.imageBase64,
      ),
    );
  }
}
