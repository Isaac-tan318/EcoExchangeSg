import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_application_1/models/event_model.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_application_1/services/connectivity_service.dart';
import 'package:flutter_application_1/utils/date_formats.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditEventScreen extends StatefulWidget {
  const EditEventScreen({super.key});

  static const routeName = '/events/edit';

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final firebaseService = GetIt.instance<FirebaseService>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  DateTime? _start;
  DateTime? _end;
  bool _saving = false;
  bool _online = true;
  late Event _event;
  String? _imageBase64;
  final ImagePicker _picker = ImagePicker();
  bool _removeImage = false;

  String _fmt(DateTime dt) => DateFormats.dMonthYHm(dt.toLocal());

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to connectivity for offline mode handling
    GetIt.instance<ConnectivityService>().isOnline$.listen((isOnline) {
      if (!mounted) return;
      setState(() => _online = isOnline);
    });
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is Event) {
      _event = args;
      _titleCtrl.text = _event.title ?? '';
      _descCtrl.text = _event.description ?? '';
      _locCtrl.text = _event.location ?? '';
      _start = _event.startDateTime;
      _end = _event.endDateTime;
      _imageBase64 = _event.imageBase64;
    }
  }

  // start and end date and time picker
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

  // submit to firebase
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
      final data = <String, dynamic>{
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'location': _locCtrl.text.trim(),
        if (_start != null) 'startDateTime': _start,
        if (_end != null) 'endDateTime': _end,
        if (_removeImage) 'imageBase64': FieldValue.delete(),
        if (!_removeImage && _imageBase64 != null && _imageBase64!.isNotEmpty)
          'imageBase64': _imageBase64,
      };
      await firebaseService.updateEvent(_event.id!, data);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
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
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
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
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Event')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: isLandscape
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_imageBase64 != null && _imageBase64!.isNotEmpty)
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Image.memory(
                                  const Base64Decoder().convert(_imageBase64!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        if (_imageBase64 != null && _imageBase64!.isNotEmpty)
                          const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: _EventFormFields(
                            titleCtrl: _titleCtrl,
                            descCtrl: _descCtrl,
                            locCtrl: _locCtrl,
                            start: _start,
                            end: _end,
                            onPickStart: _pickStart,
                            onPickEnd: _pickEnd,
                            onSave: _save,
                            saving: _saving,
                            online: _online,
                            scheme: scheme,
                            fmt: _fmt,
                          ),
                        ),
                      ],
                    )
                  : _EventFormFields(
                      titleCtrl: _titleCtrl,
                      descCtrl: _descCtrl,
                      locCtrl: _locCtrl,
                      start: _start,
                      end: _end,
                      onPickStart: _pickStart,
                      onPickEnd: _pickEnd,
                      onSave: _save,
                      saving: _saving,
                      online: _online,
                      scheme: scheme,
                      fmt: _fmt,
                    ),
            ),
          ),
          if (_saving)
            Positioned.fill(
              child: AbsorbPointer(
                absorbing: true,
                child: Container(
                  color: Colors.black45,
                  child: const Center(child: CircularProgressIndicator()),
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

class _EventFormFields extends StatelessWidget {
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final TextEditingController locCtrl;
  final DateTime? start;
  final DateTime? end;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final VoidCallback onSave;
  final bool saving;
  final bool online;
  final ColorScheme scheme;
  final String Function(DateTime) fmt;

  const _EventFormFields({
    required this.titleCtrl,
    required this.descCtrl,
    required this.locCtrl,
    required this.start,
    required this.end,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onSave,
    required this.saving,
    required this.online,
    required this.scheme,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: titleCtrl,
          decoration: const InputDecoration(labelText: 'Title'),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: descCtrl,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Description'),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: locCtrl,
          decoration: const InputDecoration(labelText: 'Location'),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onPickStart,
                child: Text(
                  start == null ? 'Pick start' : 'Start: ${fmt(start!)}',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: onPickEnd,
                child: Text(end == null ? 'Pick end' : 'End: ${fmt(end!)}'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: saving || !online ? null : onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
          ),
          icon:
              saving
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.save),
          label: const Text('Save'),
        ),
      ],
    );
  }
}
