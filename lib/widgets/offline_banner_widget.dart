import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_application_1/services/connectivity_service.dart';

class OfflineBannerOverlay extends StatefulWidget {
  final Alignment alignment;
  const OfflineBannerOverlay({
    super.key,
    this.alignment = Alignment.bottomCenter,
  });

  @override
  State<OfflineBannerOverlay> createState() => _OfflineBannerOverlayState();
}

class _OfflineBannerOverlayState extends State<OfflineBannerOverlay> {
  bool _online = true;

  @override
  void initState() {
    super.initState();
    // Listen for connectivity for offline mode handling
    GetIt.instance<ConnectivityService>().isOnline$.listen((isOnline) {
      if (!mounted) return;
      setState(() => _online = isOnline);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_online) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    // Compute margin depending on placement. If centered, use symmetric margin.
    double bottomMargin = 8.0;
    EdgeInsets containerMargin;
    if (widget.alignment == Alignment.bottomCenter) {
      // If there's a BottomNavigationBar in the nearest Scaffold, offset the banner
      // so it sits above it (not overlapping or inside it).
      final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
      final hasBottomNav = scaffold?.bottomNavigationBar != null;
      bottomMargin =
          hasBottomNav ? (8.0 + kBottomNavigationBarHeight + 8.0) : 8.0;
      containerMargin = EdgeInsets.fromLTRB(8, 8, 8, bottomMargin);
    } else {
      containerMargin = const EdgeInsets.all(16);
    }
    return SafeArea(
      child: Align(
        alignment: widget.alignment,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: double.infinity),
          child: Container(
            width: double.infinity,
            margin: containerMargin,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
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
