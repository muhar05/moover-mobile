import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../attendance/attendance_screen.dart';
import '../core/themes/theme.dart';
import '../core/widgets/spread.dart';
import '../core/widgets/widgets.dart';
import '../login/login_screen.dart';
import '../time_log/time_log_screen.dart';
import '../trip/trip_detail_screen.dart';
import 'mock_data.dart';

part 'account_tab.dart';
part 'home_tab.dart';
part 'reimburse_tab.dart';
part 'trip_tab.dart';

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
  // Ikon Lucide (gaya garis V2.1, keputusan pemilik project 2026-10-11).
  // Lucide tidak punya varian berisi: tab terpilih = garis lebih tebal (500)
  // + warna primary + pill.
  static const _tabs = <MooverNavItem>[
    (
      label: 'Beranda',
      icon: LucideIcons.house,
      selectedIcon: LucideIcons.house500,
    ),
    (label: 'Trip', icon: LucideIcons.car, selectedIcon: LucideIcons.car500),
    (
      label: 'Reimburse',
      icon: LucideIcons.receiptText,
      selectedIcon: LucideIcons.receiptText500,
    ),
    (label: 'Akun', icon: LucideIcons.user, selectedIcon: LucideIcons.user500),
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
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // UD1 (Usulan aktif): banner trip berjalan di atas bottom nav,
          // semua tab.
          ListenableBuilder(
            listenable: activeTrip,
            builder: (context, _) => switch (activeTrip.value) {
              final active? => _ActiveTripBanner(active.trip),
              null => const SizedBox.shrink(),
            },
          ),
          MooverBottomNavigation(
            items: _tabs,
            selectedIndex: _index,
            onSelected: (i) => setState(() => _index = i),
          ),
        ],
      ),
    );
  }
}

/// Banner "Trip berjalan · Lanjutkan" (UD1): satu target sentuh ke S08.
/// Navy + putih 14,9:1, tujuan sky 9,54:1.
class _ActiveTripBanner extends StatelessWidget {
  const _ActiveTripBanner(this.trip);

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: MooverColors.navy,
      child: InkWell(
        onTap: () => openTrip(context, trip),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MooverSpace.screen,
            vertical: MooverSpace.md,
          ),
          child: Row(
            spacing: MooverSpace.md,
            children: [
              const Icon(LucideIcons.carFront, color: MooverColors.cyan),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trip berjalan · Lanjutkan',
                      style: textTheme.titleSmall?.copyWith(
                        color: MooverColors.surface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Ke ${tripDestination(trip)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: MooverColors.sky,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, color: MooverColors.surface),
            ],
          ),
        ),
      ),
    );
  }
}

/// Layar S18–S21 dan S05 belum ada (Q-B8 Perlu konfirmasi): menu memberi
/// tahu belum tersedia, bukan navigasi palsu.
void _notYet(BuildContext context, String what) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text('$what belum tersedia.')));

/// V2.1: judul halaman 28/w800, tracking −0,02em.
TextStyle? _titleStyle(BuildContext context) =>
    Theme.of(context).textTheme.headlineMedium
        ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.56);

/// Jarak atas konten di bawah status bar (V2.1: 52 ≈ status bar + 20).
double _topInset(BuildContext context) =>
    MediaQuery.paddingOf(context).top + MooverSpace.screen;

/// Kerangka tab: judul besar di latar + [subtitle] muted opsional (atau
/// [header] sendiri), lalu konten dengan jarak lega. Banner "Data contoh" (D10) dihapus atas keputusan
/// pemilik project (2026-10-10); DESIGN.md belum diperbarui.
class _TabPage extends StatelessWidget {
  const _TabPage({
    this.title,
    this.subtitle,
    this.header,
    required this.children,
  });

  final String? title;
  final String? subtitle;
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6, // V2.1 (tab Trip)
              children: [
                // container: subjudul tidak ikut dibaca sebagai judul.
                Semantics(
                  container: true,
                  header: true,
                  child: Text(title!, style: _titleStyle(context)),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: MooverColors.textMuted),
                  ),
              ],
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
/// menumpang 52dp di tepi bawah header (kartu profil Akun). Watermark tanda
/// Moover 10% (V2.1, dekoratif) di kanan atas, terpotong bidang navy.
class _NavyHeader extends StatelessWidget {
  const _NavyHeader({
    required this.children,
    required this.markTop,
    this.overlap,
  });

  final List<Widget> children;
  final double markTop;
  final Widget? overlap;

  static const overlapExtent = 52.0;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Stack(
        children: [
          Positioned.fill(
            bottom: overlap == null ? 0 : overlapExtent,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: MooverColors.navy,
                borderRadius: overlap == null
                    ? const BorderRadius.vertical(bottom: Radius.circular(32))
                    : null,
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -70,
                    top: markTop,
                    width: 260,
                    child: const MooverMark(opacity: 0.10),
                  ),
                ],
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

/// Judul bagian + kartu-kartu (trip, reimburse) ditumpuk dengan jarak.
class _Section extends StatelessWidget {
  const _Section({required this.title, this.trailing, required this.children});

  final String title;
  final String? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: MooverSpace.md,
    children: [
      MooverSectionHeader(title, trailing: trailing),
      ...children,
    ],
  );
}

class _TripItem extends StatelessWidget {
  const _TripItem(
    this.trip, {
    this.next = false,
    this.history = false,
    this.onTap,
  });

  final Trip trip;
  final bool next;
  final bool history;
  final VoidCallback? onTap;

  @override
  // V2.1: jadwal hari ini = tujuan + alamat (Home); [history] = rute asal →
  // tujuan tanpa alamat (Trip history), juga untuk trip hari ini yang sudah
  // diakhiri/dibatalkan.
  Widget build(BuildContext context) {
    // Status simulasi Start/Cancel/End menimpa status mock (2026-10-13).
    final (status, tone) = statusOf(trip);
    return MooverTripItem(
      time: trip.time,
      origin: history ? tripOrigin(trip) : null,
      destination: tripDestination(trip),
      address: history ? null : trip.address,
      status: status,
      tone: tone,
      passengers: trip.passengers,
      next: next,
      onTap: onTap,
    );
  }
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
