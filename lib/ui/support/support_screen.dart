import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/themes/theme.dart';
import '../main_menu/mock_data.dart';

/// Buka [Uri] di aplikasi bawaan (WhatsApp, email, telepon); false = gagal.
/// Tes menggantinya. Paket url_launcher disetujui pemilik project
/// 2026-10-20.
@visibleForTesting
Future<bool> Function(Uri) openExternal = (uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Exception {
    return false; // mis. tidak ada aplikasi yang bisa membuka
  }
};

/// S21 Hubungi Support (KAK §5.1.13): WhatsApp, email, telepon membuka
/// aplikasi bawaan (DESIGN.md S21). Dibuka dari Akun (S17). Gaya baris
/// mengikuti grup menu Akun.
/// ponytail: [contacts] MOCK/DEMO fiktif; kontak asli Perlu konfirmasi
/// (Q-B8). Jam layanan support Belum ditentukan, tidak ditampilkan.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key, required this.contacts});

  final List<SupportContact> contacts;

  Future<void> _open(BuildContext context, SupportContact c) async {
    if (await openExternal(c.uri) || !context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Tidak bisa membuka ${c.label}.')));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const tone = StatusTone.live; // sama dengan grup Bantuan di Akun
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hubungi support',
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
          Text(
            'Pilih cara menghubungi tim support.',
            style: textTheme.bodyMedium?.copyWith(
              color: MooverColors.textMuted,
            ),
          ),
          const SizedBox(height: MooverSpace.md),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, c) in contacts.indexed) ...[
                  if (i > 0) const Divider(height: 1),
                  // Satu tombol bagi pembaca layar: "WhatsApp, +62 ...".
                  MergeSemantics(
                    child: Semantics(
                      button: true,
                      child: InkWell(
                        onTap: () => _open(context, c),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: MooverSpace.lg,
                            vertical: 14, // sama dengan baris menu Akun
                          ),
                          child: Row(
                            spacing: 14, // sama dengan baris menu Akun
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: tone.background,
                                  borderRadius: BorderRadius.circular(
                                    MooverRadius.sm,
                                  ),
                                ),
                                child: Icon(
                                  c.icon,
                                  size: 20,
                                  color: tone.foreground,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  spacing: 1,
                                  children: [
                                    Text(c.label, style: textTheme.titleSmall),
                                    Text(
                                      c.value,
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: MooverColors.textMuted,
                                        fontFeatures: tabularFigures,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                LucideIcons.externalLink,
                                size: 18,
                                color: MooverColors.textMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
