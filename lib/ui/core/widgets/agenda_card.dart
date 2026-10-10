import 'package:flutter/material.dart';

import '../themes/theme.dart';
import 'route_timeline.dart';
import 'spread.dart';

/// Kartu Agenda Hari Ini, diletakkan di header navy Beranda (V2.1,
/// 2026-10-10; menggantikan kartu gradient). Isi: tanggal + pill status
/// clock-in (garis amber), waktu trip berikutnya besar, rute, bar progres
/// jam operasional. Bidang [fill] putih 8% di atas navy (#1A3869): putih
/// 11,6:1, sky 7,6:1, amber 8,1:1, isi bar cyan 6,9:1 (nonteks). Hanya
/// untuk latar navy.
/// Hanya menampilkan status; tidak ada aksi clock-in (aturan belum ada).
/// ponytail: jam berjalan (detik) dan tombol "Clock in" di header V2 tidak
/// dibuat: tanpa alur clock-in jam hanya dekorasi. Tambahkan saat aturan
/// clock-in diputuskan (Q-B*).
class MooverAgendaCard extends StatelessWidget {
  const MooverAgendaCard({
    super.key,
    required this.date,
    required this.tripCount,
    required this.nextTime,
    required this.origin,
    required this.destination,
    required this.clockInStatus,
    required this.operatingHours,
    required this.shiftProgress,
  });

  final String date;
  final int tripCount;
  final String nextTime;
  final String origin;
  final String destination;
  final String clockInStatus;
  final String operatingHours;

  /// 0–1: posisi waktu sekarang di jam operasional. Dekoratif (teks
  /// [operatingHours] membawa informasinya).
  final double shiftProgress;

  /// V2.1: putih 8%, tepi putih 12% (dekoratif).
  static const fill = Color(0x14FFFFFF);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const onCard = MooverColors.surface;
    const muted = MooverColors.sky;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        border: Border.all(color: const Color(0x1FFFFFFF)),
        borderRadius: BorderRadius.circular(MooverRadius.card),
      ),
      // 18: padding kartu dalam header V2.1.
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            spread(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Agenda hari ini',
                    style: textTheme.titleSmall?.copyWith(color: onCard),
                  ),
                  Text(
                    date,
                    style: textTheme.bodyMedium?.copyWith(color: muted),
                  ),
                ],
              ),
              DecoratedBox(
                decoration: const ShapeDecoration(
                  shape: StadiumBorder(
                    side: BorderSide(color: MooverColors.amber),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10, // V2.1: pill ringkas 4×10
                    vertical: MooverSpace.xs,
                  ),
                  child: Text(
                    clockInStatus,
                    style: textTheme.labelMedium?.copyWith(
                      color: MooverColors.amber,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14), // V2.1: gap 14
            MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Berikutnya',
                    style: textTheme.labelLarge?.copyWith(color: muted),
                  ),
                  // V2.1: angka besar w600, tabular. displaySmall 36, bukan
                  // 46 HTML: "09.30" harus muat 320dp pada teks 200%.
                  Text(
                    nextTime,
                    style: textTheme.displaySmall?.copyWith(
                      color: onCard,
                      fontWeight: FontWeight.w600,
                      fontFeatures: tabularFigures, // D2
                    ),
                  ),
                  const SizedBox(height: MooverSpace.md),
                  MooverRouteTimeline(
                    origin: origin,
                    destination: destination,
                    onDark: true,
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Bar progres: track putih 14%, isi cyan. ponytail: V2.1 memakai
            // gradient blue500 → cyan; cyan polos cukup sebagai indikator.
            ExcludeSemantics(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SizedBox(
                  height: 6,
                  child: ColoredBox(
                    color: onCard.withValues(alpha: 0.14),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: shiftProgress.clamp(0, 1),
                      child: const ColoredBox(color: MooverColors.cyan),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            spread(
              Text(
                operatingHours,
                style: textTheme.bodySmall?.copyWith(
                  color: muted,
                  fontFeatures: tabularFigures,
                ),
              ),
              Text(
                '$tripCount trip',
                style: textTheme.titleSmall?.copyWith(color: onCard),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
