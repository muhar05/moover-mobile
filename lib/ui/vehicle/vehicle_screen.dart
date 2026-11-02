import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/themes/theme.dart';
import '../core/widgets/widgets.dart';
import '../main_menu/mock_data.dart';

/// S19 Informasi Kendaraan (KAK §5.1.10): model, nomor polisi, kapasitas.
/// Dibuka dari Akun (S17). [vehicle] null = "Belum ada kendaraan"
/// (DESIGN.md S19). Foto PLACEHOLDER, dekoratif (model ditulis).
/// ponytail: data MOCK/DEMO [vehicle]; sumber data (default driver atau
/// kendaraan trip aktif) Perlu konfirmasi (Q-B8). Ganti dengan data server
/// saat API Terverifikasi.
class VehicleScreen extends StatelessWidget {
  const VehicleScreen({super.key, required this.vehicle});

  final Vehicle? vehicle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kendaraan',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: switch (vehicle) {
        null => const Center(
          child: EmptyView(
            message: 'Belum ada kendaraan.',
            icon: LucideIcons.car,
          ),
        ),
        final v => ListView(
          padding: EdgeInsets.fromLTRB(
            MooverSpace.screen,
            MooverSpace.sm,
            MooverSpace.screen,
            MooverSpace.xl + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Latar putih: foto PLACEHOLDER berlatar putih.
                  Padding(
                    padding: const EdgeInsets.all(MooverSpace.lg),
                    child: Image.asset(
                      v.image,
                      height: 160,
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                    ),
                  ),
                  const Divider(height: 1),
                  for (final (i, (label, value)) in [
                    ('Model', v.model),
                    ('Nomor polisi', v.plate),
                    ('Kapasitas', v.capacity),
                  ].indexed) ...[
                    if (i > 0) const Divider(height: 1),
                    // Label + nilai dibaca sebagai satu item.
                    MergeSemantics(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: MooverSpace.lg,
                          vertical: 14, // sama dengan baris menu Akun
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 2,
                          children: [
                            Text(
                              label,
                              style: textTheme.bodySmall?.copyWith(
                                color: MooverColors.textMuted,
                              ),
                            ),
                            Text(
                              value,
                              style: textTheme.titleMedium?.copyWith(
                                fontFeatures: tabularFigures,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      },
    );
  }
}
