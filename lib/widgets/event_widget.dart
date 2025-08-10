import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/event.dart';
import 'package:flutter_application_1/utils/date_formats.dart';
import 'dart:convert';

String _fmtDateTime(DateTime dt) => DateFormats.dMonthYHm(dt);

class EventWidget extends StatelessWidget {
  final Event event;
  final Widget? trailing;
  const EventWidget({super.key, required this.event, this.trailing});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final texttheme = Theme.of(context).textTheme;
    final loc = (event.location ?? '').trim();
    final start = event.startDateTime;
    final end = event.endDateTime;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 15),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  event.title ?? 'Untitled',
                  style: TextStyle(
                    fontSize: texttheme.headlineMedium!.fontSize,
                    fontWeight: FontWeight.w100,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          if (loc.isNotEmpty)
            Row(
              children: [
                Icon(Icons.place, size: 18, color: scheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    loc,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          if (loc.isNotEmpty) const SizedBox(height: 8),
          if (start != null)
            Row(
              children: [
                Icon(Icons.access_time, size: 18, color: scheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    end != null
                        ? '${_fmtDateTime(start)} — ${_fmtDateTime(end)}'
                        : _fmtDateTime(start),
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          if ((event.imageBase64 ?? '').isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.memory(
                  const Base64Decoder().convert(event.imageBase64!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if ((event.description ?? '').trim().isNotEmpty)
            Text(
              event.description!,
              style: TextStyle(
                fontSize: texttheme.bodyLarge!.fontSize,
                color: scheme.onSurface,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
