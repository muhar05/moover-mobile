part of 'trip_detail_screen.dart';

/// Status trip yang sudah lewat (§4.7), urutan chip filter S12.
const pastStatuses = ['Selesai', 'Menunggu Feedback', 'Dibatalkan'];

/// Hari trip. ponytail: diambil dari nomor TRP-YYYYMMDD-NNNN (format mock
/// web, belum Terverifikasi) karena tanggal mock berupa teks; ganti dengan
/// tanggal dari server saat API trip Terverifikasi.
DateTime tripDay(Trip t) => DateTime.parse(t.number.substring(4, 12));

/// Filter S12 (KAK §5.1.8): [query] di asal, tujuan, dan nomor trip;
/// [status] null = semua; [range] inklusif per hari.
List<Trip> filterTrips(
  List<Trip> trips, {
  String query = '',
  String? status,
  DateTimeRange? range,
}) {
  final q = query.trim().toLowerCase();
  return [
    for (final t in trips)
      if ((status == null || statusOf(t).$1 == status) &&
          '${t.route} ${t.number}'.toLowerCase().contains(q) &&
          (range == null ||
              !tripDay(t).isBefore(range.start) &&
                  !tripDay(t).isAfter(range.end)))
        t,
  ];
}

String _shortDate(DateTime d) => formatDate(d).split(', ').last;

/// S12 Trip History (KAK §5.1.8), gaya V2.1 "Trip history": pencarian, chip
/// status dengan jumlah, filter rentang tanggal, kartu per tanggal. Usulan
/// aktif. Dibuka dari bagian Riwayat tab Trip.
/// ponytail: nama bulan di kalender rentang tanggal masih bahasa Inggris
/// (tanpa flutter_localizations; menambahkannya mengubah pubspec, butuh
/// persetujuan).
class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  final _query = TextEditingController();
  String? _status;
  DateTimeRange? _range;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _reset() => setState(() {
    _query.clear();
    _status = null;
    _range = null;
  });

  Future<void> _pickRange(List<Trip> trips) async {
    final days = trips.map(tripDay).toList()..sort();
    final range = await showDateRangePicker(
      context: context,
      firstDate: days.first,
      lastDate: days.last,
      initialDateRange: _range,
      helpText: 'Pilih rentang tanggal',
      cancelText: 'Batal',
      confirmText: 'OK',
      saveText: 'Terapkan',
    );
    if (range != null) setState(() => _range = range);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final trips = pastTrips();
    final shown = filterTrips(
      trips,
      query: _query.text,
      status: _status,
      range: _range,
    );
    final dates = {for (final t in shown) t.date};

    Widget chip(String label, String? status) {
      final selected = _status == status;
      final count = filterTrips(
        trips,
        query: _query.text,
        status: status,
        range: _range,
      ).length;
      // Sama dengan chip Time Log: terpilih navy + putih 14,5:1; tidak: tepi
      // muted 5,76:1 (D9).
      return ChoiceChip(
        label: Text('$label $count'),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => setState(() => _status = status),
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
          'Riwayat trip',
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
          TextField(
            controller: _query,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Cari tempat atau nomor trip',
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
          const SizedBox(height: MooverSpace.md),
          Wrap(
            spacing: MooverSpace.sm,
            runSpacing: MooverSpace.sm,
            children: [
              chip('Semua', null),
              for (final s in pastStatuses) chip(s, s),
            ],
          ),
          const SizedBox(height: MooverSpace.md),
          Row(
            spacing: MooverSpace.sm,
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickRange(trips),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MooverColors.text,
                  ),
                  icon: const Icon(LucideIcons.calendarRange),
                  label: Text(switch (_range) {
                    null => 'Semua tanggal',
                    final r => '${_shortDate(r.start)} – ${_shortDate(r.end)}',
                  }),
                ),
              ),
              if (_range != null)
                IconButton(
                  onPressed: () => setState(() => _range = null),
                  tooltip: 'Hapus filter tanggal',
                  icon: const Icon(LucideIcons.x),
                ),
            ],
          ),
          for (final date in dates) ...[
            const SizedBox(height: MooverSpace.xl),
            MooverSectionHeader(
              date,
              trailing: '${shown.where((t) => t.date == date).length} trip',
            ),
            for (final t in shown.where((t) => t.date == date)) ...[
              const SizedBox(height: MooverSpace.md),
              MooverTripItem(
                time: t.time,
                origin: tripOrigin(t),
                destination: tripDestination(t),
                status: statusOf(t).$1,
                tone: statusOf(t).$2,
                onTap: () => openTrip(context, t),
              ),
            ],
          ],
          if (shown.isEmpty)
            EmptyView(
              icon: LucideIcons.searchX,
              message: 'Tidak ada trip yang cocok dengan filter.',
              action: OutlinedButton(
                onPressed: _reset,
                child: const Text('Reset filter'),
              ),
            ),
        ],
      ),
    );
  }
}

/// S13 Detail Trip & Feedback (KAK §5.1.8), gaya V2.1 "Trip history
/// detail": status + nomor, feedback penumpang (navy) atau catatan status,
/// waktu, rute. Usulan aktif. Data hasil dari [tripResults] (contoh/simulasi).
/// ponytail: "Tampilkan QR" untuk Menunggu Feedback belum ada (Q-B5);
/// nama/foto penumpang, durasi, peta rute, dan kendaraan (Q-B8) V2.1 belum
/// ada di data mock.
class TripSummaryScreen extends StatelessWidget {
  const TripSummaryScreen({super.key, required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (status, tone) = statusOf(trip);
    final result = tripResults[trip.number];
    final muted = textTheme.bodySmall?.copyWith(color: MooverColors.textMuted);
    Widget cell(String label, String value) => MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          Text(label, style: muted),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: tabularFigures,
            ),
          ),
        ],
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ringkasan trip',
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
          spread(
            StatusBadge(label: status, tone: tone),
            Text(
              trip.number,
              style: muted?.copyWith(fontFeatures: tabularFigures),
            ),
          ),
          const SizedBox(height: MooverSpace.md),
          if (result?.rating case final rating?)
            _Feedback(rating: rating, comment: result!.comment)
          else if (status == waitingFeedback.$1)
            const _Note(
              title: 'Menunggu feedback',
              body: 'Penumpang belum mengisi feedback trip ini.',
              tone: StatusTone.warn,
            )
          else if (result?.reason case final reason?)
            _Note(title: 'Alasan pembatalan', body: reason, tone: tone),
          const SizedBox(height: MooverSpace.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18), // V2.1
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 14, // V2.1
                children: [
                  Wrap(
                    spacing: MooverSpace.xl,
                    runSpacing: MooverSpace.md,
                    children: [
                      cell('Tanggal', trip.date),
                      cell('Jemput', trip.time),
                      if (result?.start case final start?) cell('Mulai', start),
                      if (result?.arrival case final arrival?)
                        cell('Tiba', arrival),
                    ],
                  ),
                  const Divider(height: 1),
                  MooverRouteTimeline(
                    origin: tripOrigin(trip),
                    destination: tripDestination(trip),
                  ),
                  if (trip.address case final address?)
                    Text(address, style: muted?.copyWith(height: 1.45)),
                ],
              ),
            ),
          ),
          if (trip.passengers case final passengers?) ...[
            const SizedBox(height: MooverSpace.md),
            _Passengers(passengers),
          ],
        ],
      ),
    );
  }
}

/// Feedback penumpang (V2.1: kartu navy). Sky di navy 9,54:1, putih
/// 14,5:1, bintang amber 10,2:1 (kosong blue500 3,65:1). Bintang dekoratif:
/// nilai dibaca dari teks "N dari 5".
class _Feedback extends StatelessWidget {
  const _Feedback({required this.rating, this.comment});

  final int rating;
  final String? comment;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return MergeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: MooverColors.navy,
          borderRadius: BorderRadius.circular(MooverRadius.lg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18), // V2.1
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: MooverSpace.md,
            children: [
              Text(
                'Feedback penumpang',
                style: textTheme.labelLarge?.copyWith(color: MooverColors.sky),
              ),
              Wrap(
                spacing: MooverSpace.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ExcludeSemantics(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 3, // V2.1
                      children: [
                        for (var i = 1; i <= 5; i++)
                          Icon(
                            LucideIcons.star,
                            size: 20,
                            color: i <= rating
                                ? MooverColors.amber
                                : MooverColors.blue500,
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '$rating dari 5',
                    style: textTheme.titleSmall?.copyWith(
                      color: MooverColors.surface,
                      fontFeatures: tabularFigures,
                    ),
                  ),
                ],
              ),
              if (comment case final comment?)
                Text(
                  '“$comment”',
                  style: textTheme.bodyLarge?.copyWith(
                    color: MooverColors.surface,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Catatan status S13 di bidang tone (teks tone ≥4,5:1, D6).
class _Note extends StatelessWidget {
  const _Note({required this.title, required this.body, required this.tone});

  final String title;
  final String body;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return MergeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tone.background,
          borderRadius: BorderRadius.circular(MooverRadius.card),
        ),
        child: Padding(
          padding: const EdgeInsets.all(MooverSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: MooverSpace.xs,
            children: [
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: tone.foreground,
                ),
              ),
              Text(
                body,
                style: textTheme.bodyMedium?.copyWith(color: tone.foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
