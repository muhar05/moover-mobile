import 'package:flutter/material.dart';

import '../themes/theme.dart';

/// Tiga kolom Masuk / Keluar / Total (V2.1 kartu clock-out, Time log,
/// Bukti kehadiran). Nilai sudah diformat pemanggil. [totalColor] mengikuti
/// status (V2.1: hijau lengkap, merah tidak lengkap); makna status tetap
/// dibawa badge teks di pemanggil (D7). [fill] opsional: bidang #F6F8FC V2.1
/// diganti Ground (token yang ada).
class MooverShiftTimes extends StatelessWidget {
  const MooverShiftTimes({
    super.key,
    required this.clockIn,
    required this.clockOut,
    required this.total,
    this.totalSemanticsLabel,
    this.totalColor = MooverColors.text,
    this.fill = false,
  });

  final String clockIn;
  final String clockOut;
  final String total;

  /// Ucapan [total] untuk pembaca layar (mis. "9 jam 0 menit").
  final String? totalSemanticsLabel;
  final Color totalColor;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    Widget cell(String label, String value, Color color, [String? spoken]) =>
        Expanded(
          // Label + nilai dibaca berurutan: "Masuk, 07.30".
          child: MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2, // V2.1
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: MooverColors.textMuted,
                  ),
                ),
                Text(
                  value,
                  semanticsLabel: spoken,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontFeatures: tabularFigures,
                  ),
                ),
              ],
            ),
          ),
        );
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: MooverSpace.sm,
      children: [
        cell('Masuk', clockIn, MooverColors.text),
        cell('Keluar', clockOut, MooverColors.text),
        cell('Total', total, totalColor, totalSemanticsLabel),
      ],
    );
    if (!fill) return row;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: MooverColors.background,
        borderRadius: BorderRadius.circular(MooverRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14, // V2.1
          vertical: MooverSpace.md,
        ),
        child: row,
      ),
    );
  }
}
