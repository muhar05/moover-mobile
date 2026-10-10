import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/themes/theme.dart';
import '../core/widgets/widgets.dart';
import '../login/login_screen.dart';
import 'mock_data.dart';

/// Main Menu: bottom navigation 4 tab (DESIGN.md §5.2, Usulan aktif UD1).
/// Isi tab adalah kerangka dengan data MOCK/DEMO; belum ada API Terverifikasi
/// untuk data ini (API_CONTRACT.md). Gaya visual V2.1 (keputusan pemilik
/// project 2026-10-10), belum dicatat di DESIGN.md: Beranda dan Akun
/// memakai header navy, Trip dan Reimburse judul besar di latar Ground.
class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
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
      // Judul ada di dalam tiap tab (ikut scroll), bukan AppBar. Tanpa
      // SafeArea: header navy sampai ke status bar; jarak atas di _TabPage.
      // IndexedStack: state tiap tab (scroll, segmen) tetap saat berpindah.
      body: IndexedStack(
        index: _index,
        children: const [
          _HomeTab(),
          _TripTab(),
          _ReimburseTab(),
          _AccountTab(),
        ],
      ),
      bottomNavigationBar: MooverBottomNavigation(
        items: _tabs,
        selectedIndex: _index,
        onSelected: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _TabPage(
      header: _NavyHeader(
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
                          'Halo,',
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
          MooverAgendaCard(
            date: tripsToday.first.date,
            tripCount: tripsToday.length,
            nextTime: tripsToday.first.time,
            origin: tripOrigin(tripsToday.first),
            destination: tripDestination(tripsToday.first),
            clockInStatus: 'Belum clock-in hari ini.',
            operatingHours: 'Jam operasional 07.30–16.30', // KAK §5.1.2.
            shiftProgress: _shiftProgress(TimeOfDay.now()),
          ),
        ],
      ),
      children: [
        _Section(
          title: 'Jadwal hari ini',
          trailing: '${tripsToday.length} trip',
          card: false,
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

/// Posisi [now] di jam operasional 07.30–16.30 (KAK §5.1.2), 0–1.
double _shiftProgress(TimeOfDay now) =>
    ((now.hour * 60 + now.minute - 450) / 540).clamp(0, 1);

class _TripTab extends StatefulWidget {
  const _TripTab();

  @override
  State<_TripTab> createState() => _TripTabState();
}

class _TripTabState extends State<_TripTab> {
  bool _history = false;

  @override
  Widget build(BuildContext context) {
    final dates = {for (final t in tripHistory) t.date};
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
            trailing: '${tripsToday.length} trip',
            card: false,
            children: [
              for (final (i, t) in tripsToday.indexed)
                _TripItem(t, next: i == 0),
            ],
          )
        else
          // Riwayat dikelompokkan per tanggal (urutan data).
          for (final date in dates)
            _Section(
              title: date,
              trailing:
                  '${tripHistory.where((t) => t.date == date).length} trip',
              card: false,
              children: [
                for (final t in tripHistory.where((t) => t.date == date))
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
        trailing: '${reimbursements.length} item',
        children: [for (final r in reimbursements) _ReimburseItem(r)],
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
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _TabPage(
      // V2.1 Settings: judul putih di navy, kartu profil menumpang 52dp di
      // tepi bawah header.
      header: _NavyHeader(
        overlap: Card(
          // Bayangan V2.1 (dekoratif): kartu berada di atas dua latar.
          elevation: 8,
          shadowColor: MooverColors.navy.withValues(alpha: 0.3),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(MooverRadius.lg)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(MooverSpace.lg),
            child: Row(
              spacing: 14,
              children: [
                const _Avatar(size: 64, ring: 3, border: MooverColors.surface),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        demoDriverName,
                        style: textTheme.titleMedium?.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
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
          ),
        ),
        children: [
          Semantics(
            header: true,
            child: Text(
              'Akun',
              style: _titleStyle(context)
                  ?.copyWith(color: MooverColors.surface),
            ),
          ),
        ],
      ),
      children: [
        // V2.1 "Log out": tint err + label err (5,86:1), tinggi 52. Varian
        // destructive umum tetap Belum ditentukan; gaya ini khusus logout.
        FilledButton.icon(
          onPressed: () => _logout(context),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: StatusTone.err.background,
            foregroundColor: StatusTone.err.foreground,
            textStyle: textTheme.titleSmall?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          icon: const Icon(Icons.logout),
          label: const Text('Keluar'),
        ),
      ],
    );
  }
}

/// V2.1: judul halaman 28/w800, tracking −0,02em.
TextStyle? _titleStyle(BuildContext context) =>
    Theme.of(context).textTheme.headlineMedium
        ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.56);

/// Jarak atas konten di bawah status bar (V2.1: 52 ≈ status bar + 20).
double _topInset(BuildContext context) =>
    MediaQuery.paddingOf(context).top + MooverSpace.screen;

/// Kerangka tab: judul besar di latar (atau [header] navy), lalu konten
/// dengan jarak lega. Banner "Data contoh" (D10) dihapus atas keputusan
/// pemilik project (2026-10-10); DESIGN.md belum diperbarui.
class _TabPage extends StatelessWidget {
  const _TabPage({this.title, this.header, required this.children});

  final String? title;
  final Widget? header;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.only(bottom: MooverSpace.xl),
    children: [
      header ??
          Padding(
            padding: EdgeInsets.fromLTRB(
              MooverSpace.screen,
              _topInset(context),
              MooverSpace.screen,
              0,
            ),
            child: Semantics(
              header: true,
              child: Text(title!, style: _titleStyle(context)),
            ),
          ),
      Padding(
        // 22: jarak header–konten V2.1.
        padding: const EdgeInsets.fromLTRB(
          MooverSpace.screen,
          22,
          MooverSpace.screen,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          // 28: jarak antarbagian, sengaja di antara xl dan xxl.
          spacing: 28,
          children: children,
        ),
      ),
    ],
  );
}

/// Header navy V2.1 sampai ke status bar (ikon status bar terang). Tanpa
/// [overlap]: sudut bawah radius 32 (Beranda). Dengan [overlap]: widget itu
/// menumpang 52dp di tepi bawah header (kartu profil Akun).
/// ponytail: watermark logo 10% di header V2 tidak dibuat (dekoratif).
class _NavyHeader extends StatelessWidget {
  const _NavyHeader({required this.children, this.overlap});

  final List<Widget> children;
  final Widget? overlap;

  static const overlapExtent = 52.0;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Stack(
      children: [
        Positioned.fill(
          bottom: overlap == null ? 0 : overlapExtent,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: MooverColors.navy,
              borderRadius: overlap == null
                  ? const BorderRadius.vertical(bottom: Radius.circular(32))
                  : null,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            MooverSpace.screen,
            _topInset(context),
            MooverSpace.screen,
            overlap == null ? MooverSpace.screen : 0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 18, // V2.1: jarak isi header
            children: [...children, ?overlap],
          ),
        ),
      ],
    ),
  );
}

/// Avatar inisial driver dengan ring gradient blue700 → cyan (V2.1) dan tepi
/// [border]. Dekoratif (nama ditulis di sebelahnya); inisial blue700 di
/// blueTint 6,67:1. Foto driver: Belum ditentukan (tidak ada data).
class _Avatar extends StatelessWidget {
  const _Avatar({required this.size, required this.ring, required this.border});

  final double size;
  final double ring;
  final Color border;

  @override
  Widget build(BuildContext context) {
    final initials = demoDriverName.split(' ').map((w) => w[0]).join();
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(ring),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [MooverColors.blue700, MooverColors.cyan],
          ),
        ),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: MooverColors.blueTint,
            border: Border.all(color: border, width: 2),
          ),
          child: FittedBox(
            child: Text(
              initials,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: MooverColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Judul bagian + baris-baris. [card]: baris dibungkus satu kartu dan
/// dipisah hairline (Reimburse); false: tiap baris sudah kartu sendiri
/// (trip V2.1), ditumpuk dengan jarak.
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
      spacing: card ? 0 : MooverSpace.md,
      children: [
        for (final (i, child) in children.indexed) ...[
          if (card && i > 0)
            const Divider(
              height: 1,
              indent: MooverSpace.lg,
              endIndent: MooverSpace.lg,
            ),
          child,
        ],
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: MooverSpace.md,
      children: [
        MooverSectionHeader(title, trailing: trailing),
        card ? Card(child: rows) : rows,
      ],
    );
  }
}

class _TripItem extends StatelessWidget {
  const _TripItem(this.trip, {this.next = false});

  final Trip trip;
  final bool next;

  @override
  Widget build(BuildContext context) => MooverTripItem(
    time: trip.time,
    origin: tripOrigin(trip),
    destination: tripDestination(trip),
    status: trip.status,
    tone: trip.tone,
    passengers: trip.passengers,
    next: next,
  );
}

class _ReimburseItem extends StatelessWidget {
  const _ReimburseItem(this.item);

  final Reimburse item;

  @override
  Widget build(BuildContext context) => MooverReimburseItem(
    category: item.category,
    icon: item.icon,
    amount: item.amount,
    date: item.date,
    status: item.status,
    tone: item.tone,
  );
}
