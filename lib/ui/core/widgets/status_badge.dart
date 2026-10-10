import 'package:flutter/material.dart';

import '../themes/theme.dart';

/// Badge status. Disetujui (D7): selalu teks + warna.
/// Ukuran (tinggi ≥24dp, teks ≥12sp): Usulan aktif (UD3).
/// [label] diisi pemanggil; pemetaan kode status → label (§4.7) belum ada.
///
/// V2.1 (keputusan pemilik project 2026-10-10, "ikuti HTML"): 13/w800,
/// padding 6×12, menggantikan pengecualian w600. Tone [StatusTone.live]
/// diberi titik cyan 7dp; titik dekoratif (cyan di cyanTint <3:1), makna
/// tetap dibawa teks.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.tone});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: const EdgeInsets.symmetric(
        horizontal: MooverSpace.md,
        vertical: 6, // V2.1: pill ringkas
      ),
      decoration: ShapeDecoration(
        color: tone.background,
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tone == StatusTone.live) ...[
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: MooverColors.cyan,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: tone.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
