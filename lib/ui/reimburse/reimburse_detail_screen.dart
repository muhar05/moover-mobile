import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/themes/theme.dart';
import '../core/widgets/spread.dart';
import '../core/widgets/widgets.dart';
import '../main_menu/main_menu_screen.dart' show formatDate;
import '../time_log/time_log_screen.dart' show formatHm;
import 'reimburse_form_screen.dart';
import 'reimburse_store.dart';

/// Format D4 tanpa hari: "8 Okt 2026".
String shortDate(DateTime d) => formatDate(d).split(', ').last;

/// Buka S15 baru/ajukan ulang; setelah tersimpan beri tahu tanpa klaim
/// "berhasil" (D10: belum dikonfirmasi server).
Future<void> openReimburseForm(
  BuildContext context, {
  Reimbursement? resubmit,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final number = await Navigator.of(context).push<String>(
    MaterialPageRoute(builder: (_) => ReimburseFormScreen(resubmit: resubmit)),
  );
  if (number == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          number.isEmpty
              ? 'Pengajuan ulang disimpan di perangkat (belum dikirim ke '
                    'server).'
              : '$number disimpan di perangkat (belum dikirim ke server).',
        ),
      ),
    );
}

/// S16 Detail & Timeline Reimburse (KAK §5.1.16, §6.4). Usulan aktif.
/// Data dari SQLite perangkat (keputusan pemilik project 2026-10-14).
/// ponytail: bukti transfer contoh tanpa file; buka gambar/PDF bukti
/// menyusul saat API U22 Terverifikasi. Notifikasi status: Q-T2.
class ReimburseDetailScreen extends StatelessWidget {
  const ReimburseDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: reimburseStore,
    builder: (context, _) => switch (reimburseStore.byId(id)) {
      final r? => _build(context, r),
      null => const Scaffold(
        body: EmptyView(message: 'Pengajuan tidak ditemukan.'),
      ),
    },
  );

  Widget _build(BuildContext context, Reimbursement r) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodyMedium?.copyWith(color: MooverColors.textMuted);
    final d = r.draft;
    Widget row(String label, String value) => MergeSemantics(
      child: spread(
        Text(label, style: muted),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontFeatures: tabularFigures,
          ),
        ),
      ),
    );
    final note = r.status == ReimburseStatus.rejected ? rejectionNote(r) : null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detail reimburse',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          MooverSpace.screen,
          MooverSpace.sm,
          MooverSpace.screen,
          MooverSpace.xl,
        ),
        children: [
          spread(
            StatusBadge(label: r.status.label, tone: r.status.tone),
            Text(
              r.number,
              style: textTheme.bodySmall?.copyWith(
                color: MooverColors.textMuted,
                fontFeatures: tabularFigures,
              ),
            ),
          ),
          const SizedBox(height: MooverSpace.md),
          if (note != null) ...[
            RejectionNote(note),
            const SizedBox(height: MooverSpace.md),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18), // sama dengan kartu S07
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: MooverSpace.md,
                children: [
                  MergeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: MooverSpace.xs,
                      children: [
                        Text(d.category.label, style: muted),
                        Text(
                          formatRupiah(d.amount),
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontFeatures: tabularFigures,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  row('Tanggal', shortDate(d.date)),
                  row('Trip terkait', d.tripNumber ?? '–'),
                  MergeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: MooverSpace.xs,
                      children: [
                        Text('Keterangan', style: muted),
                        Text(d.description, style: textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: MooverSpace.xl),
          const MooverSectionHeader('Foto nota'),
          const SizedBox(height: MooverSpace.md),
          ReceiptPhoto(d.receiptPhoto),
          if (r.transfer case final t?) ...[
            const SizedBox(height: MooverSpace.xl),
            const MooverSectionHeader('Bukti transfer'),
            const SizedBox(height: MooverSpace.md),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(MooverSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: MooverSpace.sm,
                  children: [
                    row('Tanggal transfer', shortDate(t.date)),
                    row('Nominal transfer', formatRupiah(t.amount)),
                    row(
                      'Bukti',
                      t.proof == null ? 'Contoh (tanpa file)' : 'Terlampir',
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: MooverSpace.xl),
          const MooverSectionHeader('Timeline'),
          const SizedBox(height: MooverSpace.md),
          for (final (i, e) in r.timeline.reversed.indexed)
            _Step(e, last: i == r.timeline.length - 1),
        ],
      ),
      bottomNavigationBar: r.status == ReimburseStatus.rejected
          ? DecoratedBox(
              decoration: const BoxDecoration(
                color: MooverColors.surface,
                border: Border(top: BorderSide(color: MooverColors.hairline)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    MooverSpace.lg,
                    MooverSpace.md,
                    MooverSpace.lg,
                    MooverSpace.screen,
                  ),
                  child: FilledButton.icon(
                    onPressed: () => openReimburseForm(context, resubmit: r),
                    icon: const Icon(LucideIcons.pencil),
                    label: const Text('Perbaiki & ajukan ulang'),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

/// Catatan penolakan (KAK §5.5.2): err di errBg.
class RejectionNote extends StatelessWidget {
  const RejectionNote(this.note, {super.key});

  final String note;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final fg = StatusTone.err.foreground;
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.all(MooverSpace.lg),
        decoration: BoxDecoration(
          color: StatusTone.err.background,
          borderRadius: BorderRadius.circular(MooverRadius.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: MooverSpace.md,
          children: [
            Icon(LucideIcons.circleAlert, color: fg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: MooverSpace.xs,
                children: [
                  Text(
                    'Catatan penolakan',
                    style: textTheme.titleSmall?.copyWith(color: fg),
                  ),
                  Text(
                    note,
                    style: textTheme.bodyMedium?.copyWith(
                      color: MooverColors.text,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Satu tahap timeline: titik tone status + garis ke tahap berikutnya.
class _Step extends StatelessWidget {
  const _Step(this.entry, {required this.last});

  final TimelineEntry entry;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: MooverColors.textMuted);
    final tone = entry.status.tone;
    return MergeSemantics(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: MooverSpace.md,
          children: [
            Column(
              children: [
                const SizedBox(height: MooverSpace.xs),
                Container(
                  width: 14,
                  height: 14,
                  decoration: ShapeDecoration(
                    color: tone.foreground, // titik ≥3:1 di latar (D9)
                    shape: const CircleBorder(),
                  ),
                ),
                if (!last)
                  const Expanded(
                    child: VerticalDivider(
                      width: 14,
                      thickness: 2,
                      color: MooverColors.hairline,
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: MooverSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      entry.status.label,
                      style: textTheme.titleSmall?.copyWith(
                        color: tone.foreground,
                      ),
                    ),
                    Text(
                      '${shortDate(entry.at)}, ${formatHm(entry.at)} WIB · '
                      '${entry.actor}',
                      style: muted?.copyWith(fontFeatures: tabularFigures),
                    ),
                    if (entry.note case final note?)
                      Text(note, style: textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
