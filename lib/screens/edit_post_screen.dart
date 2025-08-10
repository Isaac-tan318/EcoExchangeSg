import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_application_1/models/post_model.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:flutter_application_1/widgets/post_form_widget.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_application_1/services/connectivity_service.dart';
import 'package:image_picker/image_picker.dart';

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
  String? _imageBase64; // working image (can change/remove)
  final ImagePicker _picker = ImagePicker();
  bool _removeImage = false;

  final _service = GetIt.instance<FirebaseService>();

  // get the info of the original post to autofill
  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(
      text: widget.initial.title?.toString() ?? '',
    );
    _descCtrl = TextEditingController(
      text: widget.initial.description?.toString() ?? '',
    );
  _imageBase64 = widget.initial.imageBase64;
    // subscribe to connectivity for offline mode handling
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
    // validation
    if (!_formKey.currentState!.validate()) return;

    // sending to firebase
    setState(() => _saving = true);
    try {
      await _service.updatePost(
        widget.postId,
        Post(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          imageBase64: _removeImage ? '' : _imageBase64,
        ),
        removeImage: _removeImage,
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
      setState(() {
        _imageBase64 = base64Encode(bytes);
        _removeImage = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  void _removeImageNow() {
    setState(() {
      _imageBase64 = null;
      _removeImage = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final texttheme = Theme.of(context).textTheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
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
        // submit button
        actions: [
          ElevatedButton(
            onPressed: _saving || !_online ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.tertiaryContainer,
              foregroundColor: scheme.onTertiaryContainer,
            ),
            // loading state
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
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
      // load working image if exists
      final imageWidget =
        (_imageBase64 != null && _imageBase64!.isNotEmpty)
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        // square aspect ratio
                        aspectRatio: 1,
                        child: Image.memory(
                          const Base64Decoder().convert(
              _imageBase64!,
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                    : const SizedBox.shrink();

            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 40),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child:
                // responsive layout
                    isLandscape
                        ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // display image and margin if it exists
                            if (_imageBase64 != null &&
                                _imageBase64!.isNotEmpty)
                              Expanded(child: imageWidget),
                            if (_imageBase64 != null &&
                                _imageBase64!.isNotEmpty)
                              const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              // fields
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
            );
              },
            ),
          ),
          if (_saving)
            Positioned.fill(
              child: AbsorbPointer(
                absorbing: true,
                child: Container(
                  color: Colors.black45,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: (_saving || !_online) ? null : _pickImage,
              icon: const Icon(Icons.photo),
              label: Text(
                (_imageBase64 ?? '').isEmpty ? 'Add Image' : 'Change Image',
              ),
            ),
            const SizedBox(width: 10),
            if ((_imageBase64 ?? '').isNotEmpty)
              ElevatedButton.icon(
                onPressed: (_saving || !_online) ? null : _removeImageNow,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                icon: const Icon(Icons.delete_forever),
                label: const Text('Remove Image'),
              ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
