part of 'main_menu_screen.dart';

/// S14 Daftar Reimburse (KAK §5.1.16), gaya disamakan dengan tab Trip V2.1
/// (V2.1 tidak punya layar reimburse): judul di Ground, kartu navy aksi
/// Ajukan, filter status, lalu kartu per pengajuan. Usulan aktif. Ajukan →
/// S15, kartu → S16; data SQLite perangkat (keputusan pemilik project
/// 2026-10-14).
class _ReimburseTab extends StatefulWidget {
  const _ReimburseTab();

  @override
  State<_ReimburseTab> createState() => _ReimburseTabState();
}

class _ReimburseTabState extends State<_ReimburseTab> {
  // null = semua.
  ReimburseStatus? _status;

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: reimburseStore, builder: _build);

  Widget _build(BuildContext context, Widget? _) {
    final textTheme = Theme.of(context).textTheme;
    final all = reimburseStore.items;
    final items = [
      for (final r in all ?? <Reimbursement>[])
        if (_status == null || r.status == _status) r,
    ];
    Widget chip(String label, ReimburseStatus? status) {
      final selected = _status == status;
      // Terpilih: putih di primary 8,62:1; tidak: tepi muted 5,76:1 (D9).
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _status = status),
        selectedColor: MooverColors.primary,
        backgroundColor: MooverColors.surface,
        checkmarkColor: MooverColors.surface,
        side: BorderSide(
          color: selected ? MooverColors.primary : MooverColors.textMuted,
        ),
        shape: const StadiumBorder(),
        labelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: selected ? MooverColors.surface : MooverColors.text,
        ),
      );
    }

    return _TabPage(
      title: 'Reimburse',
      subtitle: 'Pengajuan biaya tol, parkir, BBM, dan lainnya.',
      children: [
        const _SubmitCard(),
        if (reimburseStore.failed)
          ErrorView(
            message: 'Data reimburse tidak dapat dimuat.',
            onRetry: reimburseStore.load,
          )
        else if (all == null)
          // D10: skeleton saat memuat.
          Semantics(
            label: 'Memuat pengajuan',
            child: Column(
              spacing: MooverSpace.md,
              children: [
                for (var i = 0; i < 3; i++) const SkeletonBox(height: 88),
              ],
            ),
          )
        else if (all.isEmpty)
          EmptyView(
            message: 'Belum ada pengajuan',
            action: OutlinedButton(
              onPressed: () => openReimburseForm(context),
              child: const Text('Ajukan'),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: MooverSpace.md,
            children: [
              MooverSectionHeader(
                'Pengajuan',
                trailing: '${items.length} item',
              ),
              Wrap(
                spacing: MooverSpace.sm,
                children: [
                  chip('Semua', null),
                  for (final s in ReimburseStatus.values) chip(s.label, s),
                ],
              ),
              for (final r in items) _ReimburseItem(r),
              if (items.isEmpty)
                const EmptyView(
                  message: 'Belum ada pengajuan dengan status ini.',
                ),
            ],
          ),
      ],
    );
  }
}

/// Kartu navy aksi Ajukan (pola kartu trip tambahan V2.1). Putih di navy
/// 14,5:1, sky 9,54:1, label navy di cyan 8,63:1, ikon cyan di bidang putih
/// 8% (#1A3869) 6,9:1.
class _SubmitCard extends StatelessWidget {
  const _SubmitCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: MooverColors.navy,
        borderRadius: BorderRadius.circular(26), // sama dengan kartu trip
      ),
      child: Padding(
        padding: const EdgeInsets.all(MooverSpace.screen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 14,
          children: [
            Row(
              spacing: 14,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0x14FFFFFF),
                    borderRadius: BorderRadius.circular(MooverRadius.md),
                  ),
                  child: const Icon(
                    LucideIcons.receiptText,
                    color: MooverColors.cyan,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: MooverSpace.xs,
                    children: [
                      Text(
                        'Ada biaya perjalanan?',
                        style: textTheme.titleLarge?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: MooverColors.surface,
                        ),
                      ),
                      Text(
                        'Ajukan dengan foto nota.', // KAK §5.1.15
                        style: textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                          color: MooverColors.sky,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            FilledButton.icon(
              onPressed: () => openReimburseForm(context),
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
              label: const Text('Ajukan reimburse'),
            ),
          ],
        ),
      ),
    );
  }
}
