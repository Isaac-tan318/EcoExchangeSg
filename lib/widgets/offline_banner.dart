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
  // If there's a BottomNavigationBar in the nearest Scaffold, offset the banner
  // so it sits above it (not overlapping or inside it).
  final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
  final hasBottomNav = scaffold?.bottomNavigationBar != null;
  final bottomMargin = hasBottomNav
    ? (8.0 + kBottomNavigationBarHeight + 8.0) // base 8 + nav height + extra spacing
    : 8.0;
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: double.infinity),
          child: Container(
            width: double.infinity,
      margin: EdgeInsets.fromLTRB(8, 8, 8, bottomMargin),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                Icon(Icons.wifi_off, color: scheme.onErrorContainer, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You are offline. Some features are unavailable.',
                    style: TextStyle(
                      color: scheme.onErrorContainer,
                      fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                    ),
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
