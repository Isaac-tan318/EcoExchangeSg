import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import 'package:flutter_application_1/models/event.dart';
import 'package:flutter_application_1/services/firebase_service.dart';
import 'package:flutter_application_1/config/app_config.dart';
import 'package:flutter_application_1/services/connectivity_service.dart';
import 'package:flutter_application_1/utils/date_formats.dart';

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
  final _locFocus = FocusNode();

  DateTime? _start;
  DateTime? _end;
  bool _submitting = false;
  bool _isOrganiser = false;
  bool _loadingRole = true;

  String? _imageBase64;
  final ImagePicker _picker = ImagePicker();

  // Map and geocoding
  final MapController _mapController = MapController();
  LatLng? _selectedLatLng;
  static const double _minZoom = 3;
  static const double _maxZoom = 18;

  // Search
  Timer? _debounce;
  List<_PlaceSuggestion> _suggestions = [];
  bool _searching = false;
  bool _webCorsWarned = false;
  static const String? _nominatimProxyBase = null; // optional web proxy
  static String _geoapifyKey = String.fromEnvironment('GEOAPIFY_KEY');
  bool _online = true;

  String _fmt(DateTime dt) => DateFormats.dMonthYHm(dt.toLocal());

  @override
  void initState() {
    super.initState();
    _locFocus.addListener(_onLocFocusChanged);
    _init();
  }

  Future<void> _init() async {
    // Load app config first (so web key can be bundled in assets)
    await AppConfig.load();
    final fromAsset = AppConfig.getString('GEOAPIFY_KEY');
    if ((fromAsset ?? '').isNotEmpty) {
      _geoapifyKey = fromAsset!;
    }
    // Then init role
    final isOrg = await _svc.isCurrentUserOrganiser();
    if (!mounted) return;
    setState(() {
      _isOrganiser = isOrg;
      _loadingRole = false;
    });
    // connectivity
    GetIt.instance<ConnectivityService>().isOnline$.listen((isOnline) {
      if (!mounted) return;
      setState(() => _online = isOnline);
    });
  }

  @override
  void dispose() {
    _locFocus.removeListener(_onLocFocusChanged);
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locCtrl.dispose();
    _locFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onLocFocusChanged() {
    if (_locFocus.hasFocus) {
      // When the field regains focus and has input, re-kick the search debounce
      final q = _locCtrl.text.trim();
      if (q.length >= 3) {
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 10), () {
          if (mounted) _onLocationChanged();
        });
      }
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

  void _onLocationChanged() {
    final q = _locCtrl.text.trim();
    _debounce?.cancel();
    if (q.length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (_online) {
        _searchPlaces(q);
      } else {
        setState(() => _suggestions = []);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offline: address search unavailable.')),
        );
      }
    });
  }

  Future<void> _searchPlaces(String query) async {
    setState(() => _searching = true);
    try {
      Uri uri;
      bool parseGeoapify = false;
      if (kIsWeb && _geoapifyKey.isNotEmpty) {
        final rawUrl =
            'https://api.geoapify.com/v1/geocode/autocomplete?text=${Uri.encodeQueryComponent(query)}&limit=5&apiKey=$_geoapifyKey';
        uri = Uri.parse(rawUrl);
        parseGeoapify = true;
      } else {
        final rawUrl =
            'https://nominatim.openstreetmap.org/search?format=json&addressdetails=1&q=${Uri.encodeQueryComponent(query)}&limit=5';
        if (kIsWeb && _nominatimProxyBase == null) {
          if (!_webCorsWarned && mounted) {
            _webCorsWarned = true;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Address search on Web requires a provider with CORS (e.g., Geoapify) or a proxy.',
                ),
              ),
            );
          }
          setState(() {
            _searching = false;
            _suggestions = [];
          });
          return;
        }
        uri =
            _nominatimProxyBase != null
                ? Uri.parse(
                  '${_nominatimProxyBase!}${Uri.encodeComponent(rawUrl)}',
                )
                : Uri.parse(rawUrl);
      }
      final res = await http.get(
        uri,
        headers: {
          'User-Agent': 'ecoexchange-app/1.0 (+https://example.com)',
          'Accept': 'application/json',
        },
      );
      if (res.statusCode == 200) {
        List<_PlaceSuggestion> suggs;
        if (parseGeoapify) {
          final Map<String, dynamic> data = jsonDecode(res.body);
          final List feats = (data['features'] as List? ?? []);
          suggs =
              feats
                  .map((f) {
                    final props = (f['properties'] as Map?) ?? {};
                    final name =
                        (props['formatted'] ?? props['address_line1'] ?? '')
                            as String;
                    LatLng? pos;
                    try {
                      final geom = (f as Map)['geometry'] as Map?;
                      final coords =
                          (geom?['coordinates'] as List?)?.cast<num>();
                      if (coords != null && coords.length >= 2) {
                        // GeoJSON order: [lon, lat]
                        pos = LatLng(
                          coords[1].toDouble(),
                          coords[0].toDouble(),
                        );
                      }
                    } catch (_) {}
                    if (pos == null) {
                      final lat = (props['lat'] as num?)?.toDouble();
                      final lon = (props['lon'] as num?)?.toDouble();
                      if (lat != null && lon != null) pos = LatLng(lat, lon);
                    }
                    return _PlaceSuggestion(displayName: name, latLng: pos);
                  })
                  .where((s) => s.displayName.isNotEmpty)
                  .toList();
        } else {
          final List data = jsonDecode(res.body) as List;
          suggs =
              data
                  .map((e) {
                    final name = (e['display_name'] ?? '') as String;
                    final lat = double.tryParse(e['lat']?.toString() ?? '');
                    final lon = double.tryParse(e['lon']?.toString() ?? '');
                    return _PlaceSuggestion(
                      displayName: name,
                      latLng:
                          (lat != null && lon != null)
                              ? LatLng(lat, lon)
                              : null,
                    );
                  })
                  .where((s) => s.displayName.isNotEmpty)
                  .toList();
        }
        if (!mounted) return;
        setState(() => _suggestions = suggs);
      } else {
        if (!mounted) return;
        setState(() => _suggestions = []);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _suggestions = []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _reverseGeocode(LatLng latlng) async {
    if (!_online) {
      return;
    }
    if (kIsWeb && _geoapifyKey.isEmpty && _nominatimProxyBase == null) {
      if (!_webCorsWarned && mounted) {
        _webCorsWarned = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Reverse geocoding is unavailable on Web preview due to CORS. Provide GEOAPIFY_KEY or configure a proxy.',
            ),
          ),
        );
      }
      return;
    }
    try {
      Uri uri;
      bool parseGeoapify = false;
      if (kIsWeb && _geoapifyKey.isNotEmpty) {
        final rawUrl =
            'https://api.geoapify.com/v1/geocode/reverse?lat=${latlng.latitude}&lon=${latlng.longitude}&format=json&apiKey=$_geoapifyKey';
        uri = Uri.parse(rawUrl);
        parseGeoapify = true;
      } else {
        final rawUrl =
            'https://nominatim.openstreetmap.org/reverse?format=json&lat=${latlng.latitude}&lon=${latlng.longitude}&addressdetails=1';
        uri =
            _nominatimProxyBase != null
                ? Uri.parse(
                  '${_nominatimProxyBase!}${Uri.encodeComponent(rawUrl)}',
                )
                : Uri.parse(rawUrl);
      }
      final res = await http.get(
        uri,
        headers: {
          'User-Agent': 'ecoexchange-app/1.0 (+https://example.com)',
          'Accept': 'application/json',
        },
      );
      if (res.statusCode == 200) {
        String? addr;
        if (parseGeoapify) {
          final Map<String, dynamic> data = jsonDecode(res.body);
          final results = (data['results'] as List? ?? []);
          if (results.isNotEmpty) {
            final props = results.first as Map<String, dynamic>;
            addr =
                (props['formatted'] ??
                        props['address_line1'] ??
                        props['address_line2'])
                    ?.toString();
          }
        } else {
          final Map<String, dynamic> data = jsonDecode(res.body);
          addr = (data['display_name'] ?? '') as String;
        }
        if (addr != null && addr.isNotEmpty && mounted) {
          setState(() {
            _locCtrl.text = addr!;
            _suggestions = [];
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Couldn't fetch address for that location."),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Reverse geocoding failed: $e')));
      }
    }
  }

  Future<LatLng?> _geocodeOne(String text) async {
    if (!_online) return null;
    try {
      Uri uri;
      bool parseGeoapify = false;
      if (kIsWeb && _geoapifyKey.isNotEmpty) {
        final rawUrl =
            'https://api.geoapify.com/v1/geocode/search?text=${Uri.encodeQueryComponent(text)}&limit=1&apiKey=$_geoapifyKey';
        uri = Uri.parse(rawUrl);
        parseGeoapify = true;
      } else {
        final rawUrl =
            'https://nominatim.openstreetmap.org/search?format=json&addressdetails=1&q=${Uri.encodeQueryComponent(text)}&limit=1';
        if (kIsWeb && _nominatimProxyBase == null) {
          return null;
        }
        uri =
            _nominatimProxyBase != null
                ? Uri.parse(
                  '${_nominatimProxyBase!}${Uri.encodeComponent(rawUrl)}',
                )
                : Uri.parse(rawUrl);
      }
      final res = await http.get(
        uri,
        headers: {
          'User-Agent': 'ecoexchange-app/1.0 (+https://example.com)',
          'Accept': 'application/json',
        },
      );
      if (res.statusCode != 200) return null;
      if (parseGeoapify) {
        final Map<String, dynamic> data = jsonDecode(res.body);
        final List feats = (data['features'] as List? ?? []);
        if (feats.isEmpty) return null;
        final f = feats.first as Map;
        final geom = f['geometry'] as Map?;
        final coords = (geom?['coordinates'] as List?)?.cast<num>();
        if (coords != null && coords.length >= 2) {
          return LatLng(coords[1].toDouble(), coords[0].toDouble());
        }
        final props = (f['properties'] as Map?) ?? {};
        final lat = (props['lat'] as num?)?.toDouble();
        final lon = (props['lon'] as num?)?.toDouble();
        if (lat != null && lon != null) return LatLng(lat, lon);
        return null;
      } else {
        final List data = jsonDecode(res.body) as List;
        if (data.isEmpty) return null;
        final e = data.first as Map;
        final lat = double.tryParse(e['lat']?.toString() ?? '');
        final lon = double.tryParse(e['lon']?.toString() ?? '');
        if (lat != null && lon != null) return LatLng(lat, lon);
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  Future<void> _submit() async {
    if (!_online) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are offline. Please reconnect to post the event.'),
        ),
      );
      return;
    }
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
              // Map moved here: under Description and above Location
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 220,
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter:
                              _selectedLatLng ?? const LatLng(1.3521, 103.8198),
                          initialZoom: 11,
                          minZoom: _minZoom,
                          maxZoom: _maxZoom,
                          onTap: (tapPos, latlng) async {
                            if (_locFocus.hasFocus) _locFocus.unfocus();
                            setState(() {
                              _selectedLatLng = latlng;
                              _suggestions = [];
                            });
                            _mapController.move(
                              latlng,
                              _mapController.camera.zoom,
                            );
                            await _reverseGeocode(latlng);
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName:
                                'com.example.flutter_application_1',
                          ),
                          if (_selectedLatLng != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _selectedLatLng!,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 36,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Column(
                          children: [
                            Material(
                              shape: const CircleBorder(),
                              color: Colors.white,
                              elevation: 2,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () {
                                  final current = _mapController.camera.zoom;
                                  final next =
                                      (current + 1)
                                          .clamp(_minZoom, _maxZoom)
                                          .toDouble();
                                  _mapController.move(
                                    _mapController.camera.center,
                                    next,
                                  );
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(Icons.add, size: 20),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Material(
                              shape: const CircleBorder(),
                              color: Colors.white,
                              elevation: 2,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () {
                                  final current = _mapController.camera.zoom;
                                  final next =
                                      (current - 1)
                                          .clamp(_minZoom, _maxZoom)
                                          .toDouble();
                                  _mapController.move(
                                    _mapController.camera.center,
                                    next,
                                  );
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(Icons.remove, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (!_online)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Offline: map search and reverse lookup are disabled.',
                    style: TextStyle(color: scheme.error),
                  ),
                ),
              if (_locCtrl.text.trim().isNotEmpty)
                Text(
                  'Address: ${_locCtrl.text.trim()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locCtrl,
                focusNode: _locFocus,
                decoration: InputDecoration(
                  labelText: 'Location',
                  suffixIcon:
                      _searching
                          ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                          : (_locCtrl.text.isNotEmpty
                              ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _debounce?.cancel();
                                    _searching = false;
                                    _locCtrl.clear();
                                    _suggestions = [];
                                  });
                                  // Keep keyboard up to continue typing immediately
                                  if (!_locFocus.hasFocus) {
                                    _locFocus.requestFocus();
                                  }
                                },
                              )
                              : null),
                ),
                textInputAction: TextInputAction.search,
                onChanged: (_) => _onLocationChanged(),
                validator:
                    (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              if (_suggestions.isNotEmpty)
                Card(
                  margin: const EdgeInsets.only(top: 8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final s = _suggestions[i];
                        return ListTile(
                          leading: const Icon(Icons.place_outlined),
                          title: Text(
                            s.displayName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () async {
                            // Fill the field first, then close suggestions and unfocus.
                            setState(() {
                              _locCtrl.text = s.displayName;
                              _suggestions = [];
                            });
                            if (_locFocus.hasFocus) {
                              _locFocus.unfocus();
                            }
                            LatLng? target = s.latLng;
                            target ??= await _geocodeOne(s.displayName);
                            if (target != null) {
                              setState(() => _selectedLatLng = target);
                              _mapController.move(target, 15);
                            } else if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Could not locate that address.',
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickStart,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                        _start == null
                            ? 'Pick start'
                            : 'Start: ${_fmt(_start!)}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickEnd,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                        _end == null ? 'Pick end' : 'End: ${_fmt(_end!)}',
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
                onPressed: _submitting || !_online ? null : _submit,
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

class _PlaceSuggestion {
  final String displayName;
  final LatLng? latLng;
  const _PlaceSuggestion({required this.displayName, this.latLng});
}
