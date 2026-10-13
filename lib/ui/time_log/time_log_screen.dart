import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/themes/theme.dart';
import '../core/widgets/spread.dart';
import '../core/widgets/widgets.dart';
import '../main_menu/main_menu_screen.dart' show formatClock, formatDate;
import '../main_menu/mock_data.dart';

/// Akhir jam operasional 16.30 dalam menit (KAK §5.1.2).
const shiftEnd = 16 * 60 + 30;
const _shiftMinutes = 9 * 60; // 07.30–16.30

/// KAK §6.8: Lengkap bila clock-out ≥16.30, selain itu Tidak Lengkap (sama
/// dengan mock web). K7 Perlu konfirmasi: clock-in terlambat belum dihitung.
bool isComplete(TimeLog l) =>
    l.clockOut.at.hour * 60 + l.clockOut.at.minute >= shiftEnd;

/// Label status kehadiran DESIGN.md §4.7 + tone (D7: teks + warna).
(String, StatusTone) attendanceStatus(TimeLog l) => isComplete(l)
    ? ('Lengkap', StatusTone.ok)
    : ('Tidak Lengkap', StatusTone.warn);

/// "07.30" (D4 tanpa detik).
String formatHm(DateTime t) => formatClock(t).substring(0, 5);

Duration _worked(TimeLog l) => l.clockOut.at.difference(l.clockIn.at);

/// Durasi ringkas "9j 05m". Format durasi Belum ditentukan (D4 tidak
/// mengatur); ringkas agar tiga kolom muat. Pembaca layar: [_spokenDuration].
String formatDuration(Duration d) =>
    '${d.inHours}j ${(d.inMinutes % 60).toString().padLeft(2, '0')}m';

String _spokenDuration(Duration d) =>
    '${d.inHours} jam ${d.inMinutes % 60} menit';

/// S05 Time Log History (KAK §5.1.3), gaya V2.1 "Time log" (keputusan
/// pemilik project 2026-10-13, belum di DESIGN.md): ringkasan navy, filter
/// status, kartu per hari, sheet Bukti kehadiran. Dibuka dari Beranda dan
/// Akun (DESIGN.md S05). Data MOCK/DEMO: hari ini (simulasi) + riwayat contoh.
/// ponytail: segmen Trips/Time log V2.1 (tab "Activity") tidak dipakai, app
/// memakai 4 tab; filter tanggal (S05) belum ada, tambahkan saat data
/// riwayat datang dari server.
class TimeLogScreen extends StatefulWidget {
  const TimeLogScreen({super.key});

  @override
  State<TimeLogScreen> createState() => _TimeLogScreenState();
}

class _TimeLogScreenState extends State<TimeLogScreen> {
  // null = semua; true = Lengkap; false = Tidak Lengkap.
  bool? _complete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final logs = timeLogs();
    final shown = [
      for (final l in logs)
        if (_complete == null || isComplete(l) == _complete) l,
    ];
    final total = logs.fold(Duration.zero, (sum, l) => sum + _worked(l));

    Widget chip(String label, bool? value) {
      final selected = _complete == value;
      // V2.1: terpilih navy + putih (14,9:1); tidak: tepi muted 5,76:1 (D9).
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => setState(() => _complete = value),
        selectedColor: MooverColors.navy,
        backgroundColor: MooverColors.surface,
        side: BorderSide(
          color: selected ? MooverColors.navy : MooverColors.textMuted,
        ),
        shape: const StadiumBorder(),
        labelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          color: selected ? MooverColors.surface : MooverColors.text,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Time Log',
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
          _Summary(
            days: logs.length,
            complete: logs.where(isComplete).length,
            total: total,
          ),
          const SizedBox(height: 14), // V2.1
          Wrap(
            spacing: MooverSpace.sm,
            runSpacing: MooverSpace.sm,
            children: [
              chip('Semua', null),
              chip('Lengkap', true),
              chip('Tidak Lengkap', false),
            ],
          ),
          const SizedBox(height: 14),
          for (final l in shown) ...[
            _DayCard(l),
            const SizedBox(height: MooverSpace.md),
          ],
          if (shown.isEmpty)
            const EmptyView(message: 'Belum ada hari dengan status ini.'),
        ],
      ),
    );
  }
}

/// Ringkasan navy V2.1: hari tercatat, shift lengkap, total jam. Label sky
/// di navy 9,54:1, nilai putih 14,9:1.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.days,
    required this.complete,
    required this.total,
  });

  final int days;
  final int complete;
  final Duration total;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    Widget cell(String label, String value, [String? spoken]) => Expanded(
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: [
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(color: MooverColors.sky),
            ),
            Text(
              value,
              semanticsLabel: spoken,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: MooverColors.surface,
                fontFeatures: tabularFigures,
              ),
            ),
          ],
        ),
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: MooverColors.navy,
        borderRadius: BorderRadius.circular(MooverRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MooverSpace.lg,
          vertical: 14, // V2.1
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: MooverSpace.sm,
          children: [
            cell('Hari tercatat', '$days'),
            cell('Shift lengkap', '$complete'),
            cell('Total jam', formatDuration(total), _spokenDuration(total)),
          ],
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard(this.log);

  final TimeLog log;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (status, tone) = attendanceStatus(log);
    final complete = isComplete(log);
    final worked = _worked(log);
    return Card(
      // V2.1 radius 22; kartu biasa tetap 20 (keputusan 2026-10-10).
      child: Padding(
        padding: const EdgeInsets.all(MooverSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 14, // V2.1
          children: [
            spread(
              Text(
                formatDate(log.clockIn.at),
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              StatusBadge(label: status, tone: tone),
            ),
            MooverShiftTimes(
              clockIn: formatHm(log.clockIn.at),
              clockOut: formatHm(log.clockOut.at),
              total: formatDuration(worked),
              totalSemanticsLabel: _spokenDuration(worked),
              // V2.1: total merah bila tidak lengkap; err di putih 6,5:1.
              totalColor: complete
                  ? MooverColors.text
                  : StatusTone.err.foreground,
            ),
            // Bar dekoratif: porsi 9 jam operasional. Info dibawa teks.
            ExcludeSemantics(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SizedBox(
                  height: 6,
                  child: ColoredBox(
                    color: StatusTone.neutral.background,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (worked.inMinutes / _shiftMinutes).clamp(
                        0,
                        1,
                      ),
                      child: ColoredBox(
                        // ponytail: V2.1 gradient blue700→cyan / amber
                        // #E39B1B; warna polos token cukup.
                        color: complete
                            ? MooverColors.primary
                            : StatusTone.warn.foreground,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            spread(
              Text(
                complete ? 'Shift penuh' : 'Clock-out sebelum 16.30',
                style: textTheme.bodySmall?.copyWith(
                  color: MooverColors.textMuted,
                ),
              ),
              TextButton.icon(
                onPressed: () => showProof(context, log),
                // V2.1 tinggi 40; dinaikkan ke 48 (D9).
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  backgroundColor: MooverColors.blueTint,
                  foregroundColor: MooverColors.text,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(MooverRadius.sm),
                  ),
                ),
                icon: const Icon(LucideIcons.camera, size: 16),
                label: const Text('Lihat bukti'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sheet Bukti kehadiran (V2.1 "Proof of attendance"): foto clock-in /
/// clock-out, lokasi, jam. Foto null = foto contoh/simulasi.
Future<void> showProof(BuildContext context, TimeLog log) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: MooverColors.surface,
      shape: const RoundedRectangleBorder(
        // V2.1: 28, sama dengan sheet Keluar.
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ProofSheet(log),
    );

class _ProofSheet extends StatefulWidget {
  const _ProofSheet(this.log);

  final TimeLog log;

  @override
  State<_ProofSheet> createState() => _ProofSheetState();
}

class _ProofSheetState extends State<_ProofSheet> {
  bool _out = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final log = widget.log;
    final (status, tone) = attendanceStatus(log);
    final punch = _out ? log.clockOut : log.clockIn;
    final kind = _out ? 'Clock-out' : 'Clock-in';
    final photo = punch.photo;
    final worked = _worked(log);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        MooverSpace.screen,
        0,
        MooverSpace.screen,
        MooverSpace.xl + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: MooverSpace.lg, // V2.1
        children: [
          spread(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Bukti kehadiran',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  formatDate(log.clockIn.at),
                  style: textTheme.bodyMedium?.copyWith(
                    color: MooverColors.textMuted,
                  ),
                ),
              ],
            ),
            StatusBadge(label: status, tone: tone),
          ),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Clock-in')),
              ButtonSegment(value: true, label: Text('Clock-out')),
            ],
            selected: {_out},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _out = s.first),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(MooverRadius.card),
            child: AspectRatio(
              aspectRatio: 16 / 10, // V2.1
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (photo == null)
                    const ColoredBox(
                      color: MooverColors.blueTint,
                      child: Icon(
                        LucideIcons.scanFace,
                        size: 72,
                        color: MooverColors.primary,
                        semanticLabel: 'Foto contoh',
                      ),
                    )
                  else
                    Image.file(
                      File(photo),
                      fit: BoxFit.cover,
                      semanticLabel: 'Foto $kind',
                    ),
                  Positioned(
                    left: MooverSpace.md,
                    bottom: MooverSpace.md,
                    child: DecoratedBox(
                      // V2.1: ink 75%; putih di atasnya ≥7:1 di foto apa pun.
                      decoration: BoxDecoration(
                        color: MooverColors.text.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(MooverSpace.sm),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9, // V2.1
                          vertical: 5,
                        ),
                        child: Text(
                          '$kind · ${formatHm(punch.at)}',
                          style: textTheme.labelMedium?.copyWith(
                            color: MooverColors.surface,
                            fontFeatures: tabularFigures,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Lokasi MOCK. Radius area kantor Belum ditentukan: tanpa klaim
          // "di dalam area kantor" (V2.1).
          Row(
            spacing: 10, // V2.1
            children: [
              const Icon(
                LucideIcons.mapPin,
                size: 18,
                color: MooverColors.primary,
              ),
              Expanded(
                child: Text(
                  'Kantor Pusat (contoh) · lokasi simulasi',
                  style: textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          MooverShiftTimes(
            clockIn: formatHm(log.clockIn.at),
            clockOut: formatHm(log.clockOut.at),
            total: formatDuration(worked),
            totalSemanticsLabel: _spokenDuration(worked),
            totalColor: tone.foreground,
            fill: true,
          ),
          PrimaryButton(
            label: 'Tutup',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
