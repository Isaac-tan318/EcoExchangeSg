import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_application_1/services/connectivity_service.dart';

class OfflineBannerOverlay extends StatefulWidget {
  const OfflineBannerOverlay({super.key});

  @override
  State<OfflineBannerOverlay> createState() => _OfflineBannerOverlayState();
}

class _OfflineBannerOverlayState extends State<OfflineBannerOverlay> {
  bool _online = true;

  @override
  void initState() {
    super.initState();
    // Listen for connectivity changes
    GetIt.instance<ConnectivityService>().isOnline$.listen((isOnline) {
      if (!mounted) return;
      setState(() => _online = isOnline);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_online) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: double.infinity),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off, color: scheme.onErrorContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You are offline. Some features are unavailable.',
                    style: TextStyle(color: scheme.onErrorContainer),
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
