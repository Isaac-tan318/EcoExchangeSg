import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/event.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_application_1/services/connectivity_service.dart';

class EditEventScreen extends StatefulWidget {
  const EditEventScreen({super.key});

  static const routeName = '/events/edit';

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _svc = GetIt.instance<FirebaseService>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  DateTime? _start;
  DateTime? _end;
  bool _saving = false;
  bool _online = true;
  late Event _event;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to connectivity changes
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
    }
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

  Future<void> _save() async {
    if (!_online) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are offline. Please reconnect to save.')),
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
      };
      await _svc.updateEvent(_event.id!, data);
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Event')),
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
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _saving || !_online ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                ),
                icon:
                    _saving
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.save),
                label: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
