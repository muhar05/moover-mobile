import 'package:flutter/material.dart';

import '../themes/theme.dart';
import 'route_timeline.dart';
import 'status_badge.dart';

/// Item trip tanpa kartu: langsung di latar halaman, dipisah hairline oleh
/// pemanggil. Hierarki: waktu (+ badge, turun baris bila tidak muat), rute
/// ([MooverRouteTimeline]), penumpang (opsional, muted 4,54:1 di latar). Dibaca TalkBack sebagai satu
/// item.
class MooverTripItem extends StatelessWidget {
  const MooverTripItem({
    super.key,
    required this.time,
    required this.origin,
    required this.destination,
    required this.status,
    required this.tone,
    this.passengers,
  });

  final String time;
  final String origin;
  final String destination;
  final String status;
  final StatusTone tone;
  final String? passengers;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: MooverSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: MooverSpace.sm,
              runSpacing: 6,
              children: [
                Text(
                  time,
                  style: textTheme.titleLarge?.copyWith(
                    fontFeatures: tabularFigures, // D2
                  ),
                ),
                StatusBadge(label: status, tone: tone),
              ],
            ),
            // 10/6: komposisi optik waktu–rute–penumpang (sama dengan Agenda).
            const SizedBox(height: 10),
            MooverRouteTimeline(origin: origin, destination: destination),
            if (passengers != null) ...[
              const SizedBox(height: 6),
              Text(
                passengers!,
                style: textTheme.bodyMedium?.copyWith(
                  color: MooverColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
