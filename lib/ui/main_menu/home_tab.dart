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
          ListenableBuilder(
            listenable: Listenable.merge([clockIn, clockOut]),
            builder: (context, _) {
              final inAt = clockIn.value?.at;
              // V2.1: setelah clock-out, kartu agenda diganti ringkasan.
              if ((inAt, clockOut.value?.at) case (final i?, final o?)) {
                return _ClockedOutCard((
                  clockIn: clockIn.value!,
                  clockOut: clockOut.value!,
                ), key: ValueKey((i, o)));
              }
              return MooverAgendaCard(
                date: formatDate(_now),
                clock: formatClock(_now),
                tripCount: tripsToday.length,
                clockInStatus: inAt == null
                    ? 'Belum clock-in hari ini.'
                    : 'Clock-in ${formatHm(inAt)} WIB',
                clockedIn: inAt != null,
                operatingHours: 'Jam operasional 07.30–16.30', // KAK §5.1.2.
                shiftProgress: _shiftProgress(_now),
                action: FilledButton.icon(
                  onPressed: () => _punch(context, out: inAt != null),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: MooverColors.cyan,
                    foregroundColor: MooverColors.navy,
                  ),
                  icon: Icon(
                    inAt == null ? LucideIcons.scanFace : LucideIcons.logOut,
                  ),
                  label: Text(inAt == null ? 'Clock-in' : 'Clock-out'),
                ),
              );
            },
          ),
        ],
      ),
      children: [
        // Kartu jadwal membuka S07/S08 (2026-10-13); status ikut simulasi.
        ListenableBuilder(
          listenable: tripStatus,
          builder: (context, _) => _Section(
            title: 'Jadwal hari ini',
            trailing: '${tripsToday.length} trip',
            children: [
              for (final (i, t) in tripsToday.indexed)
                _TripItem(t, next: i == 0, onTap: () => openTrip(context, t)),
            ],
          ),
        ),
        _Section(
          title: 'Reimburse terakhir',
          children: [_ReimburseItem(reimbursements.first)],
        ),
      ],
    );
  }
}

/// Buka S04 (clock-in atau [out] clock-out); simpan hasilnya. Simulasi
/// tanpa server (D10): pesan menyebut belum terkirim, bukan "berhasil".
Future<void> _punch(BuildContext context, {required bool out}) async {
  final messenger = ScaffoldMessenger.of(context);
  final punch = await Navigator.of(context).push<Punch>(
    MaterialPageRoute(builder: (_) => AttendanceScreen(clockOut: out)),
  );
  if (punch == null) return;
  (out ? clockOut : clockIn).value = punch;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          '${out ? 'Clock-out' : 'Clock-in'} ${formatHm(punch.at)} WIB '
          'tercatat di simulasi (belum dikirim ke server).',
        ),
      ),
    );
}

/// Kartu putih V2.1 "You're clocked out": Masuk / Keluar / Total, status
/// kehadiran (§4.7, V2.1 tidak menampilkannya; ditambah agar Tidak Lengkap
/// terlihat), tautan ke Time Log. Radius V2.1 24 = lg.
class _ClockedOutCard extends StatelessWidget {
  const _ClockedOutCard(this.log, {super.key});

  final TimeLog log;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (status, tone) = attendanceStatus(log);
    final worked = log.clockOut.at.difference(log.clockIn.at);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: MooverColors.surface,
        borderRadius: BorderRadius.circular(MooverRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18), // V2.1
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 14, // V2.1
          children: [
            Row(
              spacing: MooverSpace.md,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: StatusTone.ok.background,
                    borderRadius: BorderRadius.circular(MooverRadius.input),
                  ),
                  child: Icon(
                    LucideIcons.circleCheck,
                    color: StatusTone.ok.foreground,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          'Anda sudah clock-out',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        'Sampai besok, hati-hati di jalan.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: MooverColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: StatusBadge(label: status, tone: tone),
            ),
            MooverShiftTimes(
              clockIn: formatHm(log.clockIn.at),
              clockOut: formatHm(log.clockOut.at),
              total: formatDuration(worked),
              totalColor: tone.foreground,
              fill: true,
            ),
            OutlinedButton(
              onPressed: () => _openTimeLog(context),
              // V2.1: tinggi 48, radius 14, tepi biru muda.
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: MooverColors.primary,
                side: const BorderSide(color: MooverColors.sky, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MooverRadius.input),
                ),
              ),
              child: const Text('Lihat time log'),
            ),
          ],
        ),
      ),
    );
  }
}

void _openTimeLog(BuildContext context) =>
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const TimeLogScreen()));

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
