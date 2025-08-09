import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/event.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:get_it/get_it.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  static const routeName = '/events/create';

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _svc = GetIt.instance<FirebaseService>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  DateTime? _start;
  DateTime? _end;
  bool _submitting = false;
  bool _isOrganiser = false;
  bool _loadingRole = true;
  String? _imageBase64;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initRole();
  }

  Future<void> _initRole() async {
    final isOrg = await _svc.isCurrentUserOrganiser();
    if (!mounted) return;
    setState(() {
      _isOrganiser = isOrg;
      _loadingRole = false;
    });
  }

  Future<void> _pickStart() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _start ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (t == null) return;
    setState(() {
      _start = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  Future<void> _pickEnd() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _end ?? (_start ?? DateTime.now()),
      firstDate: _start ?? DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (t == null) return;
    setState(() {
      _end = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_start == null || _end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end times')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await _svc.createEvent(
        Event(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          location: _locCtrl.text.trim(),
          startDateTime: _start,
          endDateTime: _end,
          imageBase64: _imageBase64,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingRole) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_isOrganiser) {
      return const Scaffold(
        body: Center(child: Text('Only organisers can create events')),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Create Event')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
                validator:
                    (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              if ((_imageBase64 ?? '').isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.memory(
                      const Base64Decoder().convert(_imageBase64!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
                validator:
                    (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locCtrl,
                decoration: const InputDecoration(labelText: 'Location'),
                validator:
                    (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _pickStart,
                      child: Text(
                        _start == null
                            ? 'Pick start'
                            : 'Start: ${_start!.toLocal()}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _pickEnd,
                      child: Text(
                        _end == null ? 'Pick end' : 'End: ${_end!.toLocal()}',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.center,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final XFile? picked = await _picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 85,
                        maxWidth: 2000,
                        maxHeight: 2000,
                      );
                      if (picked == null) return;
                      final bytes = await picked.readAsBytes();
                      setState(() => _imageBase64 = base64Encode(bytes));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to pick image: $e')),
                      );
                    }
                  },
                  icon: const Icon(Icons.add_photo_alternate),
                  label: Text(
                    (_imageBase64 ?? '').isEmpty ? 'Add Image' : 'Change Image',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                ),
                icon:
                    _submitting
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.check),
                label: const Text('Post'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
