import 'package:flutter/material.dart';

class SettingsButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final TextTheme textTheme;
  final ColorScheme scheme;

  const SettingsButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.textTheme,
    required this.scheme,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.surfaceContainerHighest,
        foregroundColor: scheme.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          // side: BorderSide(color: scheme.outline),
        ),
        padding: const EdgeInsets.symmetric(vertical: 18),
        alignment: Alignment.centerLeft,
      ),
      onPressed: onPressed,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 16.0),
            child: Icon(icon),
          ),
          Text(
            label,
            style: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
          ),
        ],
      ),
    );
  }
}
