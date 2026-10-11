part of 'main_menu_screen.dart';

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  DateTime _now = DateTime.now();
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    // V2.1: jam berjalan diperbarui tiap detik (setInterval 1000).
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _now = DateTime.now()),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final greet = greeting(_now.hour);
    return _TabPage(
      header: _NavyHeader(
        markTop: 10,
        children: [
          Row(
            spacing: MooverSpace.md,
            children: [
              Expanded(
                // Sapaan + nama dibaca sebagai satu judul.
                child: MergeSemantics(
                  child: Semantics(
                    header: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sapaan sky di navy 9,54:1.
                        Text(
                          '$greet,',
                          style: textTheme.bodyMedium?.copyWith(
                            color: MooverColors.sky,
                          ),
                        ),
                        Text(
                          demoDriverName,
                          style: textTheme.titleLarge?.copyWith(
                            color: MooverColors.surface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // V2.1: avatar 48, ring 2, tepi navy 2.
              const _Avatar(size: 48, ring: 2, border: MooverColors.navy),
            ],
          ),
          ValueListenableBuilder(
            valueListenable: clockInTime,
            builder: (context, inAt, _) => MooverAgendaCard(
              date: formatDate(_now),
              clock: formatClock(_now),
              tripCount: tripsToday.length,
              clockInStatus: inAt == null
                  ? 'Belum clock-in hari ini.'
                  : 'Clock-in ${formatClock(inAt).substring(0, 5)} WIB',
              clockedIn: inAt != null,
              operatingHours: 'Jam operasional 07.30–16.30', // KAK §5.1.2.
              shiftProgress: _shiftProgress(_now),
              // ponytail: clock-out (V2.1 "Shift complete") belum dibuat;
              // tambahkan bersama aturan K7 (Incomplete).
              action: inAt == null
                  ? FilledButton.icon(
                      onPressed: () => _clockIn(context),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: MooverColors.cyan,
                        foregroundColor: MooverColors.navy,
                      ),
                      icon: const Icon(LucideIcons.scanFace),
                      label: const Text('Clock-in'),
                    )
                  : null,
            ),
          ),
        ],
      ),
      children: [
        _Section(
          title: 'Jadwal hari ini',
          trailing: '${tripsToday.length} trip',
          children: [
            for (final (i, t) in tripsToday.indexed) _TripItem(t, next: i == 0),
          ],
        ),
        _Section(
          title: 'Reimburse terakhir',
          children: [_ReimburseItem(reimbursements.first)],
        ),
      ],
    );
  }
}

/// Buka S04; simpan waktu yang dikembalikan. Simulasi tanpa server (D10):
/// pesan menyebut belum terkirim, bukan "berhasil".
Future<void> _clockIn(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final at = await Navigator.of(
    context,
  ).push<DateTime>(MaterialPageRoute(builder: (_) => const AttendanceScreen()));
  if (at == null) return;
  clockInTime.value = at;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          'Clock-in ${formatClock(at).substring(0, 5)} WIB tercatat di '
          'simulasi (belum dikirim ke server).',
        ),
      ),
    );
}

/// Sapaan menurut jam (V2.1: <11 pagi, <15 siang, <19 sore, sisanya malam).
String greeting(int hour) => hour < 11
    ? 'Selamat pagi'
    : hour < 15
    ? 'Selamat siang'
    : hour < 19
    ? 'Selamat sore'
    : 'Selamat malam';

String _two(int n) => n.toString().padLeft(2, '0');

/// Jam berjalan, format D4 dengan detik: "09.05.07".
String formatClock(DateTime t) =>
    '${_two(t.hour)}.${_two(t.minute)}.${_two(t.second)}';

/// Format D4 dengan hari: "Jumat, 9 Okt 2026".
String formatDate(DateTime t) {
  const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', //
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
  return '${days[t.weekday - 1]}, ${t.day} ${months[t.month - 1]} ${t.year}';
}

/// Posisi [now] di jam operasional 07.30–16.30 (KAK §5.1.2), 0–1.
double _shiftProgress(DateTime now) =>
    ((now.hour * 60 + now.minute - 450) / 540).clamp(0, 1);
