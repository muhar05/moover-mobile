import 'package:flutter/material.dart';

import '../design/theme.dart';
import '../design/widgets.dart';
import 'login.dart';

/// Main Menu: bottom navigation 4 tab (DESIGN.md §5.2, Usulan aktif UD1).
/// Isi tab adalah kerangka dengan data MOCK/DEMO; belum ada API Terverifikasi
/// untuk data ini (API_CONTRACT.md). Gaya visual (Clean Bright): usulan
/// pemilik project, belum dicatat di DESIGN.md.
class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  static const _tabs = <MooverNavItem>[
    (label: 'Beranda', icon: Icons.home_outlined, selectedIcon: Icons.home),
    (
      label: 'Trip',
      icon: Icons.directions_car_outlined,
      selectedIcon: Icons.directions_car,
    ),
    (
      label: 'Reimburse',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
    ),
    (label: 'Akun', icon: Icons.person_outline, selectedIcon: Icons.person),
  ];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Judul ada di dalam tiap tab (ikut scroll), bukan AppBar.
      body: SafeArea(
        bottom: false,
        // IndexedStack: state tiap tab (scroll, segmen) tetap saat berpindah.
        child: IndexedStack(
          index: _index,
          children: const [
            _HomeTab(),
            _TripTab(),
            _ReimburseTab(),
            _AccountTab(),
          ],
        ),
      ),
      bottomNavigationBar: MooverBottomNavigation(
        items: _tabs,
        selectedIndex: _index,
        onSelected: (i) => setState(() => _index = i),
      ),
    );
  }
}

// MOCK/DEMO: data contoh untuk kerangka UI, bukan data server. Label status
// dari DESIGN.md §4.7, tone dari Lampiran A.2. Format D4.
typedef _Trip = ({
  String date,
  String time,
  String route,
  String? passengers,
  String status,
  StatusTone tone,
});

typedef _Reimburse = ({
  String category,
  IconData icon,
  String amount,
  String date,
  String status,
  StatusTone tone,
});

const _tripsToday = <_Trip>[
  (
    date: '9 Okt 2026',
    time: '09.30 WIB',
    route: 'Kantor Pusat → Kantor Cabang (contoh)',
    passengers: '2 penumpang',
    status: 'Terjadwal',
    tone: StatusTone.neutral,
  ),
  (
    date: '9 Okt 2026',
    time: '13.00 WIB',
    route: 'Kantor Cabang → Kantor Pusat (contoh)',
    passengers: '1 penumpang',
    status: 'Terjadwal',
    tone: StatusTone.neutral,
  ),
];

const _tripHistory = <_Trip>[
  (
    date: '8 Okt 2026',
    time: '14.00 WIB',
    route: 'Kantor Pusat → Bandara (contoh)',
    passengers: null,
    status: 'Selesai',
    tone: StatusTone.ok,
  ),
  (
    date: '8 Okt 2026',
    time: '08.00 WIB',
    route: 'Kantor Pusat → Kantor Cabang (contoh)',
    passengers: null,
    status: 'Menunggu Feedback',
    tone: StatusTone.warn,
  ),
  (
    date: '7 Okt 2026',
    time: '10.00 WIB',
    route: 'Kantor Cabang → Kantor Pusat (contoh)',
    passengers: null,
    status: 'Dibatalkan',
    tone: StatusTone.err,
  ),
];

// ponytail: data mock menyimpan rute sebagai "Asal → Tujuan"; dipecah di
// sini tanpa mengubah datanya. Hapus saat data trip punya asal/tujuan
// terpisah (kontrak API trip).
List<String> _routeParts(_Trip t) {
  final parts = t.route.split(' → ');
  assert(parts.length == 2, 'rute mock harus "Asal → Tujuan": ${t.route}');
  return parts;
}

String _origin(_Trip t) => _routeParts(t).first;
String _destination(_Trip t) => _routeParts(t).last;

const _reimbursements = <_Reimburse>[
  (
    category: 'Tol',
    icon: Icons.toll_outlined,
    amount: 'Rp 45.000',
    date: '8 Okt 2026',
    status: 'Diajukan',
    tone: StatusTone.neutral,
  ),
  (
    category: 'BBM',
    icon: Icons.local_gas_station_outlined,
    amount: 'Rp 300.000',
    date: '6 Okt 2026',
    status: 'Disetujui',
    tone: StatusTone.info,
  ),
  (
    category: 'Parkir',
    icon: Icons.local_parking_outlined,
    amount: 'Rp 20.000',
    date: '3 Okt 2026',
    status: 'Dibayar',
    tone: StatusTone.ok,
  ),
  (
    category: 'Lainnya',
    icon: Icons.receipt_outlined,
    amount: 'Rp 75.000',
    date: '1 Okt 2026',
    status: 'Ditolak',
    tone: StatusTone.err,
  ),
];

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _TabPage(
      header: Semantics(
        header: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo,',
              style: textTheme.titleMedium?.copyWith(
                color: MooverColors.textMuted,
              ),
            ),
            Text(
              demoDriverName,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      children: [
        const _TodaySummary(),
        _Section(
          title: 'Jadwal hari ini',
          trailing: '${_tripsToday.length} trip',
          card: false,
          children: [for (final t in _tripsToday) _TripItem(t)],
        ),
        _Section(
          title: 'Reimburse terakhir',
          children: [_ReimburseItem(_reimbursements.first)],
        ),
      ],
    );
  }
}

/// Satu-satunya blok berwarna di Beranda: fokus agenda hari ini.
/// Putih di atas steel 8,76:1; mist di atas steel 6,60:1.
class _TodaySummary extends StatelessWidget {
  const _TodaySummary();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final next = _tripsToday.first;
    const onCard = MooverColors.surface;
    const muted = MooverColors.mist;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: MooverColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Agenda hari ini',
              style: textTheme.labelLarge?.copyWith(color: muted),
            ),
            const SizedBox(height: 4),
            Text(
              '${_tripsToday.length} trip',
              style: textTheme.headlineSmall?.copyWith(
                color: onCard,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Berikutnya ${next.time}',
              style: textTheme.titleSmall?.copyWith(
                color: onCard,
                fontFeatures: tabularFigures, // D2
              ),
            ),
            const SizedBox(height: 8),
            MooverRouteTimeline(
              origin: _origin(next),
              destination: _destination(next),
              onDark: true,
              style: textTheme.bodyMedium,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: onCard.withValues(alpha: 0.2)),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ExcludeSemantics(
                  child: Icon(Icons.schedule, size: 20, color: muted),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Belum clock-in hari ini.',
                        style: textTheme.bodyMedium?.copyWith(color: onCard),
                      ),
                      // KAK §5.1.2.
                      Text(
                        'Jam operasional 07.30–16.30',
                        style: textTheme.bodySmall?.copyWith(
                          color: muted,
                          fontFeatures: tabularFigures,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TripTab extends StatefulWidget {
  const _TripTab();

  @override
  State<_TripTab> createState() => _TripTabState();
}

class _TripTabState extends State<_TripTab> {
  bool _history = false;

  @override
  Widget build(BuildContext context) {
    final dates = {for (final t in _tripHistory) t.date};
    return _TabPage(
      title: 'Trip',
      children: [
        // DESIGN.md §5.2: segmen "Hari ini" (S06) dan "Riwayat" (S12).
        SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: false, label: Text('Hari ini')),
            ButtonSegment(value: true, label: Text('Riwayat')),
          ],
          selected: {_history},
          onSelectionChanged: (s) => setState(() => _history = s.single),
        ),
        if (!_history)
          _Section(
            title: 'Jadwal hari ini',
            trailing: '${_tripsToday.length} trip',
            card: false,
            children: [for (final t in _tripsToday) _TripItem(t)],
          )
        else
          // Riwayat dikelompokkan per tanggal (urutan data).
          for (final date in dates)
            _Section(
              title: date,
              trailing:
                  '${_tripHistory.where((t) => t.date == date).length} trip',
              card: false,
              children: [
                for (final t in _tripHistory.where((t) => t.date == date))
                  _TripItem(t),
              ],
            ),
      ],
    );
  }
}

class _ReimburseTab extends StatelessWidget {
  const _ReimburseTab();

  @override
  Widget build(BuildContext context) => _TabPage(
    title: 'Reimburse',
    children: [
      _Section(
        title: 'Pengajuan',
        trailing: '${_reimbursements.length} item',
        children: [for (final r in _reimbursements) _ReimburseItem(r)],
      ),
    ],
  );
}

class _AccountTab extends StatelessWidget {
  const _AccountTab();

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    // DESIGN.md S02: Login dimasuki dari Landing atau logout. Tidak ada sesi
    // tersimpan yang perlu dihapus.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final initials = demoDriverName.split(' ').map((w) => w[0]).join();
    return _TabPage(
      title: 'Akun',
      children: [
        Row(
          children: [
            ExcludeSemantics(
              child: CircleAvatar(
                radius: 32,
                backgroundColor: MooverColors.mist,
                foregroundColor: MooverColors.abyss,
                child: Text(
                  initials,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    demoDriverName,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Employee ID: $demoEmployeeId',
                    style: textTheme.bodyMedium?.copyWith(
                      color: MooverColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: () => _logout(context),
          icon: const Icon(Icons.logout),
          label: const Text('Keluar'),
        ),
      ],
    );
  }
}

/// Kerangka tab: judul besar (atau [header]), banner "Data contoh" (D10),
/// lalu konten dengan jarak lega.
class _TabPage extends StatelessWidget {
  const _TabPage({this.title, this.header, required this.children});

  final String? title;
  final Widget? header;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
    children: [
      header ??
          Semantics(
            header: true,
            child: Text(
              title!,
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
      const SizedBox(height: 16),
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: const MockDataBanner(),
      ),
      const SizedBox(height: 24),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 28,
        children: children,
      ),
    ],
  );
}

/// Judul bagian + baris-baris yang dipisah hairline. [card]: baris dibungkus
/// satu kartu (Reimburse); false: langsung di latar halaman (trip).
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    this.trailing,
    this.card = true,
    required this.children,
  });

  final String title;
  final String? trailing;
  final bool card;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, child) in children.indexed) ...[
          if (i > 0)
            Divider(height: 1, indent: card ? 16 : 0, endIndent: card ? 16 : 0),
          child,
        ],
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: card ? 12 : 4,
      children: [
        MooverSectionHeader(title, trailing: trailing),
        card ? Card(child: rows) : rows,
      ],
    );
  }
}

/// Baris yang sejajar kiri-kanan bila muat, turun ke baris baru bila tidak
/// (teks 200% di layar 320dp).
Widget _spread(Widget start, Widget end) => Wrap(
  alignment: WrapAlignment.spaceBetween,
  crossAxisAlignment: WrapCrossAlignment.center,
  spacing: 8,
  runSpacing: 6,
  children: [start, end],
);

class _TripItem extends StatelessWidget {
  const _TripItem(this.trip);

  final _Trip trip;

  @override
  Widget build(BuildContext context) => MooverTripItem(
    time: trip.time,
    origin: _origin(trip),
    destination: _destination(trip),
    status: trip.status,
    tone: trip.tone,
    passengers: trip.passengers,
  );
}

class _ReimburseItem extends StatelessWidget {
  const _ReimburseItem(this.item);

  final _Reimburse item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: CircleAvatar(
              radius: 20,
              backgroundColor: MooverColors.background,
              foregroundColor: MooverColors.primary,
              child: Icon(item.icon, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 4,
              children: [
                _spread(
                  Text(
                    item.category,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    item.amount,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: tabularFigures, // D2
                    ),
                  ),
                ),
                _spread(
                  Text(
                    item.date,
                    style: textTheme.bodySmall?.copyWith(
                      color: MooverColors.textMuted,
                    ),
                  ),
                  StatusBadge(label: item.status, tone: item.tone),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
