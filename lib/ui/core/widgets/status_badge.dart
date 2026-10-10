import 'package:flutter/material.dart';

import '../themes/theme.dart';

/// Badge status. Disetujui (D7): selalu teks + warna.
/// Ukuran (tinggi ≥24dp, teks ≥12sp): Usulan aktif (UD3).
/// [label] diisi pemanggil; pemetaan kode status → label (§4.7) belum ada.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.tone});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      // Usulan aktif: 10 horizontal sengaja di luar skala (pill ringkas).
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: MooverSpace.xs,
      ),
      decoration: ShapeDecoration(
        color: tone.background,
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        // labelMedium 12sp (UD3: ≥12sp). w600: pengecualian yang disengaja,
        // bukan peran judul (w700).
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(fontWeight: FontWeight.w600, color: tone.foreground),
      ),
    );
  }
}
