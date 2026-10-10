import 'package:flutter/material.dart';

import '../themes/theme.dart';
import 'route_timeline.dart';
import 'status_badge.dart';

/// Kartu trip V2.1 (2026-10-10): kartu putih bertepi hairline (tema Card),
/// kolom waktu 54dp (ikut skala teks) dengan garis pemisah, lalu badge
/// (+ "Berikutnya" bila [next]), rute ([MooverRouteTimeline]), penumpang
/// (opsional, muted 6,13:1 di putih). Dibaca TalkBack sebagai satu item.
/// ponytail: pemisah V2 putus-putus diganti garis solid hairline; tambahkan
/// CustomPainter bila diminta. Chip "NEXT" V2 dipindah ke kolom kanan
/// sebagai badge info: "Berikutnya" tidak muat di kolom 54dp.
class MooverTripItem extends StatelessWidget {
  const MooverTripItem({
    super.key,
    required this.time,
    required this.origin,
    required this.destination,
    required this.status,
    required this.tone,
    this.passengers,
    this.next = false,
  });

  final String time;
  final String origin;
  final String destination;
  final String status;
  final StatusTone tone;
  final String? passengers;
  final bool next;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Card(
        child: Padding(
          // V2.1: 14 14 14 16.
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 14,
              children: [
                // 54 isi (V2.1) + 8 jarak ke garis; ikut skala teks agar
                // "09.30" tidak terpotong di tengah angka.
                Container(
                  width: MediaQuery.textScalerOf(context).scale(62),
                  padding: const EdgeInsets.only(right: MooverSpace.sm),
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: MooverColors.hairline),
                    ),
                  ),
                  child: Text(
                    time,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFeatures: tabularFigures, // D2
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 10, // komposisi optik badge–rute–penumpang
                    children: [
                      Wrap(
                        spacing: MooverSpace.sm,
                        runSpacing: 6,
                        children: [
                          if (next)
                            const StatusBadge(
                              label: 'Berikutnya',
                              tone: StatusTone.info,
                            ),
                          StatusBadge(label: status, tone: tone),
                        ],
                      ),
                      MooverRouteTimeline(
                        origin: origin,
                        destination: destination,
                      ),
                      if (passengers != null)
                        Text(
                          passengers!,
                          style: textTheme.bodySmall?.copyWith(
                            color: MooverColors.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
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
