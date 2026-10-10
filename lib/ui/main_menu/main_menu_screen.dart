import 'package:flutter/material.dart';

import '../core/themes/theme.dart';
import '../core/widgets/widgets.dart';
import '../login/login_screen.dart';
import 'mock_data.dart';

/// Main Menu: bottom navigation 4 tab (DESIGN.md §5.2, Usulan aktif UD1).
/// Isi tab adalah kerangka dengan data MOCK/DEMO; belum ada API Terverifikasi
/// untuk data ini (API_CONTRACT.md). Gaya visual (Clean Bright): usulan
/// pemilik project, belum dicatat di DESIGN.md.
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
              // Sapaan sengaja tidak tebal (tema: titleMedium w700).
              style: textTheme.titleMedium?.copyWith(
                color: MooverColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(demoDriverName, style: textTheme.headlineMedium),
          ],
        ),
      ),
      children: [
        MooverAgendaCard(
          tripCount: tripsToday.length,
          nextTime: tripsToday.first.time,
          origin: tripOrigin(tripsToday.first),
          destination: tripDestination(tripsToday.first),
          clockInStatus: 'Belum clock-in hari ini.',
          operatingHours: 'Jam operasional 07.30–16.30', // KAK §5.1.2.
        ),
        _Section(
          title: 'Jadwal hari ini',
          trailing: '${tripsToday.length} trip',
          card: false,
          children: [for (final t in tripsToday) _TripItem(t)],
        ),
        _Section(
          title: 'Reimburse terakhir',
          children: [_ReimburseItem(reimbursements.first)],
        ),
      ],
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
            children: [for (final t in tripsToday) _TripItem(t)],
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
    final initials = demoDriverName.split(' ').map((w) => w[0]).join();
    return _TabPage(
      title: 'Akun',
      children: [
        Row(
          children: [
            ExcludeSemantics(
              child: CircleAvatar(
                radius: 32,
                backgroundColor: MooverColors.g100,
                foregroundColor: MooverColors.text,
                child: Text(initials, style: textTheme.titleLarge),
              ),
            ),
            const SizedBox(width: MooverSpace.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(demoDriverName, style: textTheme.titleLarge),
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

/// Kerangka tab: judul besar (atau [header]), lalu konten dengan jarak lega.
/// Banner "Data contoh" (D10) dihapus atas keputusan pemilik project
/// (2026-10-10); DESIGN.md belum diperbarui.
class _TabPage extends StatelessWidget {
  const _TabPage({this.title, this.header, required this.children});

  final String? title;
  final Widget? header;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(
      MooverSpace.screen,
      MooverSpace.lg,
      MooverSpace.screen,
      MooverSpace.xl,
    ),
    children: [
      header ??
          Semantics(
            header: true,
            child: Text(
              title!,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
      const SizedBox(height: MooverSpace.xl),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        // 28: jarak antarbagian, sengaja di antara xl dan xxl.
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
            Divider(
              height: 1,
              indent: card ? MooverSpace.lg : 0,
              endIndent: card ? MooverSpace.lg : 0,
            ),
          child,
        ],
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: card ? MooverSpace.md : MooverSpace.xs,
      children: [
        MooverSectionHeader(title, trailing: trailing),
        card ? Card(child: rows) : rows,
      ],
    );
  }
}

class _TripItem extends StatelessWidget {
  const _TripItem(this.trip);

  final Trip trip;

  @override
  Widget build(BuildContext context) => MooverTripItem(
    time: trip.time,
    origin: tripOrigin(trip),
    destination: tripDestination(trip),
    status: trip.status,
    tone: trip.tone,
    passengers: trip.passengers,
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
