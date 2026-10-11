part of 'main_menu_screen.dart';

/// S14 Daftar Reimburse (KAK §5.1.16), gaya disamakan dengan tab Trip V2.1
/// (V2.1 tidak punya layar reimburse): judul di Ground, kartu navy aksi
/// Ajukan, filter status, lalu kartu per pengajuan. Usulan aktif. Form S15
/// dan detail S16 belum ada (Q-B6, Q-T1): Ajukan memberi tahu belum tersedia.
/// ponytail: nomor reimburse (S14) belum ada di data mock; tambahkan ke
/// [Reimburse] saat kontrak API reimburse Terverifikasi.
class _ReimburseTab extends StatefulWidget {
  const _ReimburseTab();

  @override
  State<_ReimburseTab> createState() => _ReimburseTabState();
}

class _ReimburseTabState extends State<_ReimburseTab> {
  // Label status reimburse DESIGN.md §4.7; null = semua.
  static const _statuses = ['Diajukan', 'Disetujui', 'Ditolak', 'Dibayar'];
  String? _status;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final items = [
      for (final r in reimbursements)
        if (_status == null || r.status == _status) r,
    ];
    Widget chip(String label, String? status) {
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: MooverSpace.md,
          children: [
            MooverSectionHeader('Pengajuan', trailing: '${items.length} item'),
            Wrap(
              spacing: MooverSpace.sm,
              children: [
                chip('Semua', null),
                for (final s in _statuses) chip(s, s),
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
              onPressed: () => _notYet(context, 'Form reimburse'),
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
