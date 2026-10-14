import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../themes/theme.dart';
import 'road_illustration.dart';

/// Kartu navy "Butuh trip tambahan?" di tab Trip (V2.1 Trip tab, keputusan
/// pemilik project 2026-10-10). [available] = driver sudah clock-in
/// (keputusan 2026-10-10; definisi Available Q-B1/K2 belum di DESIGN.md):
/// tombol tambah trip memanggil [onAdd]; selain itu diganti petunjuk
/// clock-in. Teks putih di navy 14,5:1, sky 9,54:1; label navy di cyan
/// 8,63:1.
class MooverExtraTripCard extends StatelessWidget {
  const MooverExtraTripCard({
    super.key,
    required this.available,
    required this.onAdd,
  });

  final bool available;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: MooverColors.navy,
        // V2.1: 26, di antara lg (24) dan kartu; komposisi optik kartu hero.
        borderRadius: BorderRadius.circular(26),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MooverSpace.screen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 14, // V2.1
          children: [
            const SizedBox(height: 120, child: MooverRoadIllustration()),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                Text(
                  'Butuh trip tambahan?',
                  style: textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: MooverColors.surface,
                  ),
                ),
                Text(
                  'Buat trip di luar jadwal hari ini.',
                  style: textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: MooverColors.sky,
                  ),
                ),
              ],
            ),
            if (available)
              FilledButton.icon(
                onPressed: onAdd,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: MooverColors.cyan,
                  foregroundColor: MooverColors.navy,
                  textStyle: textTheme.titleSmall?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                icon: const Icon(LucideIcons.plus),
                label: const Text('Tambah trip baru'),
              )
            else
              // Bukan tombol: driver belum Available. Sky di bidang putih 8%
              // (#1A3869) 7,6:1.
              Container(
                constraints: const BoxConstraints(minHeight: 52),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: MooverSpace.md,
                  vertical: MooverSpace.sm,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x14FFFFFF),
                  borderRadius: BorderRadius.circular(MooverRadius.md),
                ),
                child: Text(
                  'Clock-in untuk menambah trip',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: MooverColors.sky,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
