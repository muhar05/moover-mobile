import 'package:flutter/material.dart';

import '../themes/theme.dart';
import 'route_timeline.dart';
import 'spread.dart';

/// Kartu Agenda Hari Ini: satu-satunya blok berwarna di Beranda.
/// Gradient g700 → g900 (sama dengan tombol primary web); kontras terendah
/// di ujung g700: putih 6,61:1, g100 4,61:1. Status clock-in: teks di atas
/// pill g100 13,2:1.
/// Hanya menampilkan status; tidak ada aksi clock-in (aturan belum ada).
class MooverAgendaCard extends StatelessWidget {
  const MooverAgendaCard({
    super.key,
    required this.tripCount,
    required this.nextTime,
    required this.origin,
    required this.destination,
    required this.clockInStatus,
    required this.operatingHours,
  });

  final int tripCount;
  final String nextTime;
  final String origin;
  final String destination;
  final String clockInStatus;
  final String operatingHours;

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [MooverColors.g700, MooverColors.g900],
  );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const onCard = MooverColors.surface;
    const muted = MooverColors.g100;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(MooverRadius.card),
      ),
      // 18 di atas: kompensasi optik line height label; 20 = padding kartu.
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            spread(
              Text(
                'Agenda hari ini',
                style: textTheme.labelLarge?.copyWith(color: muted),
              ),
              Text(
                '$tripCount trip',
                style: textTheme.titleSmall?.copyWith(color: onCard),
              ),
            ),
            const SizedBox(height: MooverSpace.lg),
            MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Berikutnya',
                    style: textTheme.labelMedium?.copyWith(color: muted),
                  ),
                  // Ukuran sama dengan waktu di MooverTripItem.
                  Text(
                    nextTime,
                    style: textTheme.titleLarge?.copyWith(
                      color: onCard,
                      fontFeatures: tabularFigures, // D2
                    ),
                  ),
                  const SizedBox(height: 10),
                  MooverRouteTimeline(
                    origin: origin,
                    destination: destination,
                    onDark: true,
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            // Pemisah dekoratif.
            Padding(
              padding: const EdgeInsets.symmetric(vertical: MooverSpace.lg),
              child: Divider(
                height: 1,
                color: MooverColors.g300.withValues(alpha: 0.5),
              ),
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: MooverSpace.md,
              runSpacing: MooverSpace.sm,
              children: [
                DecoratedBox(
                  decoration: const ShapeDecoration(
                    color: muted,
                    shape: StadiumBorder(),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MooverSpace.md,
                      vertical: 6, // pill ringkas, sama dengan badge
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const ExcludeSemantics(
                          child: Icon(
                            Icons.schedule,
                            size: 18,
                            color: MooverColors.text,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            clockInStatus,
                            style: textTheme.labelLarge?.copyWith(
                              color: MooverColors.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  operatingHours,
                  style: textTheme.bodySmall?.copyWith(
                    color: muted,
                    fontFeatures: tabularFigures,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
