import 'package:flutter/material.dart';

import '../themes/theme.dart';
import 'spread.dart';

/// Kartu Agenda Hari Ini, diletakkan di header navy Beranda (V2.1,
/// 2026-10-10; menggantikan kartu gradient). Isi: tanggal + pill status
/// clock-in (garis amber), jam berjalan [clock] besar, bar progres jam
/// operasional. Rute tidak ditampilkan (V2.1 Home; keputusan pemilik project
/// 2026-10-10): trip berikutnya ditandai di daftar jadwal. Bidang [fill]
/// putih 8% di atas navy (#1A3869): putih 11,6:1, sky 7,6:1, amber 8,1:1,
/// isi bar cyan 6,9:1 (nonteks). Hanya untuk latar navy.
/// [action] opsional di bawah kartu: tombol "Clock-in" V2.1 (simulasi,
/// keputusan pemilik project 2026-10-11). [clockedIn]: pill status cyan
/// (8,63:1 di navy, 6,9:1 di bidang kartu), bukan amber.
class MooverAgendaCard extends StatelessWidget {
  const MooverAgendaCard({
    super.key,
    required this.date,
    required this.clock,
    required this.tripCount,
    required this.clockInStatus,
    required this.operatingHours,
    required this.shiftProgress,
    this.clockedIn = false,
    this.action,
  });

  final String date;

  /// Jam sekarang, sudah diformat (mis. "09.30.15"). Pemanggil yang
  /// memperbaruinya tiap detik.
  final String clock;
  final int tripCount;
  final String clockInStatus;
  final String operatingHours;

  /// 0–1: posisi waktu sekarang di jam operasional. Dekoratif (teks
  /// [operatingHours] membawa informasinya).
  final double shiftProgress;
  final bool clockedIn;
  final Widget? action;

  /// V2.1: putih 8%, tepi putih 12% (dekoratif).
  static const fill = Color(0x14FFFFFF);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const onCard = MooverColors.surface;
    const muted = MooverColors.sky;
    final pill = clockedIn ? MooverColors.cyan : MooverColors.amber;
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
                decoration: ShapeDecoration(
                  shape: StadiumBorder(side: BorderSide(color: pill)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10, // V2.1: pill ringkas 4×10
                    vertical: MooverSpace.xs,
                  ),
                  child: Text(
                    clockInStatus,
                    style: textTheme.labelMedium?.copyWith(
                      color: pill,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14), // V2.1: gap 14
            // V2.1: 46/w600, tracking −0,02em, tabular (D2). Diperkecil
            // (scaleDown) bila tidak muat: 320dp pada teks 200%. Tanpa
            // liveRegion: tidak diumumkan tiap detik (aria-live off V2.1).
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                clock,
                style: textTheme.displayMedium?.copyWith(
                  fontSize: 46,
                  height: 1,
                  letterSpacing: -0.92,
                  color: onCard,
                  fontWeight: FontWeight.w600,
                  fontFeatures: tabularFigures,
                ),
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
            if (action case final action?) ...[
              const SizedBox(height: 14),
              action,
            ],
          ],
        ),
      ),
    );
  }
}
