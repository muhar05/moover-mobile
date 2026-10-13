part of 'trip_detail_screen.dart';

/// S08 Active Trip (KAK §5.1.5), layar penuh tanpa bottom nav (UD1), gaya
/// V2.1 "Active trip". Back kembali ke Beranda tanpa mengakhiri trip (UD1).
/// Simulasi tanpa server (keputusan pemilik project 2026-10-13).
/// ponytail: peta, ETA, jarak, dan lalu lintas V2.1 diganti placeholder
/// (sumber peta Q-T6, GPS hilang Q-T4/Q-T5, butuh dependency). Tambah tujuan
/// (S09) belum ada: alurnya Perlu konfirmasi (Q-B4).
class ActiveTripScreen extends StatelessWidget {
  const ActiveTripScreen({super.key, required this.active});

  final ActiveTrip active;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final trip = active.trip;
    final muted = textTheme.bodySmall?.copyWith(color: MooverColors.textMuted);
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Area peta V2.1: placeholder, teks muted di blueTint 5,58:1.
          Container(
            color: MooverColors.blueTint,
            padding: EdgeInsets.fromLTRB(
              MooverSpace.lg,
              MediaQuery.paddingOf(context).top + MooverSpace.sm,
              MooverSpace.lg,
              MooverSpace.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: MooverSpace.lg,
              children: [
                Row(
                  spacing: MooverSpace.md,
                  children: [
                    IconButton.filled(
                      onPressed: () => Navigator.of(context).maybePop(),
                      tooltip: 'Kembali ke Beranda',
                      style: IconButton.styleFrom(
                        backgroundColor: MooverColors.surface,
                        foregroundColor: MooverColors.text,
                      ),
                      icon: const Icon(LucideIcons.arrowLeft),
                    ),
                    Flexible(
                      child: Text(
                        trip.number,
                        style: textTheme.labelLarge?.copyWith(
                          fontFeatures: tabularFigures,
                        ),
                      ),
                    ),
                  ],
                ),
                const Icon(
                  LucideIcons.map,
                  size: 40,
                  color: MooverColors.primary,
                ),
                Text(
                  'Peta rute belum tersedia.',
                  textAlign: TextAlign.center,
                  style: muted,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MooverSpace.screen,
              MooverSpace.lg,
              MooverSpace.screen,
              MooverSpace.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: MooverSpace.md,
              children: [
                spread(
                  StatusBadge(label: onTrip.$1, tone: onTrip.$2),
                  Text(
                    'Mulai ${formatHm(active.startedAt)} WIB',
                    style: muted?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFeatures: tabularFigures,
                    ),
                  ),
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(MooverSpace.lg),
                    child: MergeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 2,
                        children: [
                          // V2.1 "CURRENT DESTINATION": tag live 6,9:1.
                          Text(
                            'Tujuan saat ini',
                            style: textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: StatusTone.live.foreground,
                            ),
                          ),
                          Text(
                            tripDestination(trip),
                            style: textTheme.titleSmall?.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (trip.address case final address?)
                            Text(address, style: muted),
                        ],
                      ),
                    ),
                  ),
                ),
                if (trip.passengers case final passengers?)
                  _Passengers(passengers),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _ActionBar(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text('Tambah tujuan belum tersedia.'),
                  ),
                ),
              style: OutlinedButton.styleFrom(
                foregroundColor: MooverColors.primary,
              ),
              icon: const Icon(LucideIcons.mapPinPlus),
              label: const Text('Tujuan'),
            ),
          ),
          Expanded(
            flex: 2, // V2.1: 1fr 1.4fr
            child: FilledButton.icon(
              onPressed: () => _end(context),
              icon: const Icon(LucideIcons.flag),
              label: const Text('Akhiri trip'),
            ),
          ),
        ],
      ),
    );
  }

  /// D8: sheet konfirmasi End Trip (V2.1), lalu S10 (KAK §6.1).
  Future<void> _end(BuildContext context) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: MooverColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _EndSheet(active),
    );
    if (ok != true || !context.mounted) return;
    setTripStatus(active.trip, waitingFeedback, (
      start: '${formatHm(active.startedAt)} WIB',
      arrival: '${formatHm(DateTime.now())} WIB',
      rating: null,
      comment: null,
      reason: null,
    ));
    activeTrip.value = null;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => QrFeedbackScreen(trip: active.trip),
      ),
    );
  }
}

class _EndSheet extends StatefulWidget {
  const _EndSheet(this.active);

  final ActiveTrip active;

  @override
  State<_EndSheet> createState() => _EndSheetState();
}

class _EndSheetState extends State<_EndSheet> {
  // V2.1: centang "semua penumpang sudah turun" sebelum mengakhiri.
  // Wajib/tidaknya Perlu konfirmasi (bukan aturan KAK).
  bool _dropped = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final trip = widget.active.trip;
    Widget row(String label, String value) => MergeSemantics(
      child: spread(
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(color: MooverColors.textMuted),
        ),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontFeatures: tabularFigures,
          ),
        ),
      ),
    );
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        MooverSpace.screen,
        0,
        MooverSpace.screen,
        MooverSpace.xl + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: MooverSpace.md,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Akhiri trip ini?',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            'Pastikan semua penumpang sudah diantar.',
            style: textTheme.bodyMedium?.copyWith(
              color: MooverColors.textMuted,
            ),
          ),
          row('Trip', trip.number),
          row(
            'Mulai → sekarang',
            '${formatHm(widget.active.startedAt)} → '
                '${formatHm(DateTime.now())}',
          ),
          if (trip.passengers case final passengers?)
            row('Penumpang', passengers),
          CheckboxListTile(
            value: _dropped,
            onChanged: (v) => setState(() => _dropped = v!),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: const Text('Semua penumpang sudah turun'),
          ),
          Row(
            spacing: 10, // V2.1
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MooverColors.text,
                  ),
                  child: const Text('Belum'),
                ),
              ),
              Expanded(
                child: FilledButton(
                  onPressed: _dropped
                      ? () => Navigator.pop(context, true)
                      : null,
                  child: const Text('Akhiri'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// S10 QR Feedback (KAK §5.1.7), layar penuh (UD1). Tidak ada judul
/// "selesai/berhasil" (D10): trip diakhiri di simulasi, belum di server.
/// ponytail: QR asli butuh dependency + isi QR Perlu konfirmasi (Q-B5,
/// Q-T3); di sini placeholder ikon. Kecerahan layar dan buka ulang QR juga
/// Q-B5/Q-T3.
class QrFeedbackScreen extends StatelessWidget {
  const QrFeedbackScreen({super.key, required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodyMedium?.copyWith(color: MooverColors.textMuted);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(MooverSpace.screen),
          children: [
            Semantics(
              header: true,
              child: Text(
                'Feedback penumpang',
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: MooverSpace.sm),
            Text(
              'Minta penumpang memindai QR ini untuk mengisi feedback trip.',
              textAlign: TextAlign.center,
              style: muted,
            ),
            const SizedBox(height: MooverSpace.xl),
            Center(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: MooverColors.surface,
                  borderRadius: BorderRadius.circular(MooverRadius.card),
                  border: Border.all(color: MooverColors.hairline),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: MooverSpace.sm,
                  children: [
                    const Icon(
                      LucideIcons.qrCode,
                      size: 96,
                      color: MooverColors.text,
                    ),
                    Text('QR contoh', style: muted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: MooverSpace.lg),
            Text(
              trip.number,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontFeatures: tabularFigures,
              ),
            ),
            const SizedBox(height: MooverSpace.sm),
            Center(
              child: StatusBadge(
                label: waitingFeedback.$1,
                tone: waitingFeedback.$2,
              ),
            ),
            const SizedBox(height: MooverSpace.lg),
            Text(
              'Trip diakhiri di simulasi (belum dikirim ke server).',
              textAlign: TextAlign.center,
              style: muted,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _ActionBar(
        children: [
          Expanded(
            child: FilledButton(
              // S10 → S03: kembali ke Main Menu (route pertama).
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: const Text('Selesai'),
            ),
          ),
        ],
      ),
    );
  }
}
