import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/themes/theme.dart';
import '../core/widgets/widgets.dart';
import '../main_menu/mock_data.dart';

/// S20 Bantuan & FAQ (KAK §5.1.12): pencarian + daftar accordion
/// (DESIGN.md S20). Dibuka dari Akun (S17). Pencarian mencocokkan
/// pertanyaan dan jawaban, tanpa membedakan huruf besar/kecil.
/// ponytail: [faqs] MOCK/DEMO; konten asli Perlu konfirmasi (Q-B8). Ganti
/// dengan data server saat API Terverifikasi.
class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key, required this.faqs});

  final List<Faq> faqs;

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final q = _query.text.trim().toLowerCase();
    final shown = [
      for (final f in widget.faqs)
        if ('${f.question}\n${f.answer}'.toLowerCase().contains(q)) f,
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bantuan & FAQ',
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
          // Sama dengan pencarian Riwayat trip (S12).
          TextField(
            controller: _query,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Cari pertanyaan',
              prefixIcon: const Icon(LucideIcons.search),
              suffixIcon: _query.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () => setState(_query.clear),
                      tooltip: 'Hapus pencarian',
                      icon: const Icon(LucideIcons.x),
                    ),
            ),
          ),
          const SizedBox(height: MooverSpace.lg),
          if (shown.isEmpty)
            const EmptyView(
              icon: LucideIcons.searchX,
              message: 'Tidak ada pertanyaan yang cocok.',
            )
          else
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final (i, f) in shown.indexed) ...[
                    if (i > 0) const Divider(height: 1),
                    // ExpansionTile: semantik buka/tutup bawaan. Garis tepi
                    // bawaan dimatikan; pemisah memakai Divider.
                    ExpansionTile(
                      key: ValueKey(f.question),
                      shape: const Border(),
                      collapsedShape: const Border(),
                      iconColor: MooverColors.textMuted,
                      collapsedIconColor: MooverColors.textMuted,
                      title: Text(f.question, style: textTheme.titleSmall),
                      childrenPadding: const EdgeInsets.fromLTRB(
                        MooverSpace.lg,
                        0,
                        MooverSpace.lg,
                        MooverSpace.lg,
                      ),
                      expandedAlignment: Alignment.centerLeft,
                      children: [
                        Text(
                          f.answer,
                          style: textTheme.bodyMedium?.copyWith(
                            color: MooverColors.textMuted,
                          ),
                        ),
                      ],
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
