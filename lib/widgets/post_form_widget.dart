import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_application_1/widgets/textfield_widget.dart';

class PostForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final String? imageBase64;
  final bool showImage;

  const PostForm({
    super.key,
    required this.formKey,
    required this.titleController,
    required this.descriptionController,
    this.imageBase64,
    this.showImage = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final texttheme = Theme.of(context).textTheme;

    return Form(
      key: formKey,
      child: Container(
        margin: const EdgeInsets.all(15),
        padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: scheme.surfaceContainerHigh,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BorderlessField(
              child: TextFormField(
                controller: titleController,
                maxLines: null,
                style: TextStyle(fontSize: texttheme.headlineLarge!.fontSize),
                decoration: const InputDecoration.collapsed(
                  hintText: 'Add post title',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Title is required';
                  }
                  if (v.trim().length < 3) {
                    return 'Title must be at least 3 characters';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 10),
            if (showImage &&
                imageBase64 != null &&
                imageBase64!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.memory(
                    // Base64 decode
                    const Base64Decoder().convert(imageBase64!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            BorderlessField(
              child: TextFormField(
                controller: descriptionController,
                maxLines: null,
                decoration: const InputDecoration.collapsed(
                  hintText: 'Add description',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Description is required';
                  }
                  if (v.trim().length < 10) {
                    return 'Description must be at least 10 characters';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
