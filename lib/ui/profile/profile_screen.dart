import 'package:flutter/material.dart';

import '../core/themes/theme.dart';
import '../core/widgets/widgets.dart';

/// S18 Informasi profil, hanya baca (KAK §5.1.11; keputusan pemilik project
/// 2026-11-02: edit profil dan ubah kata sandi menyusul). Dibuka dari kartu
/// profil dan menu Akun (S17). Gaya baris sama dengan S19.
/// ponytail: data MOCK/DEMO dari pemanggil; field yang boleh diubah dan
/// sumber foto Perlu konfirmasi (Q-B8, Q-B6), jadi tanpa tombol edit dan
/// foto diganti avatar inisial. Ganti dengan data server saat API
/// Terverifikasi.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.name,
    required this.employeeId,
    required this.email,
  });

  final String name;
  final String employeeId;
  final String email;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: MooverColors.textMuted);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Informasi profil',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          MooverSpace.screen,
          MooverSpace.sm,
          MooverSpace.screen,
          MooverSpace.xl + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Center(
            child: MooverAvatar(
              name: name,
              size: 88,
              ring: 3,
              border: MooverColors.background,
            ),
          ),
          const SizedBox(height: MooverSpace.lg),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, (label, value)) in [
                  ('Nama', name),
                  ('Employee ID', employeeId),
                  ('Email', email),
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
                          Text(label, style: muted),
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
          const SizedBox(height: MooverSpace.md),
          Text('Mengubah data profil belum tersedia.', style: muted),
        ],
      ),
    );
  }
}
