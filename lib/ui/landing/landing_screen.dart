import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/themes/theme.dart';
import '../login/login_screen.dart';

/// S01 Landing (DESIGN.md §6.3, Usulan aktif; KAK §5.1.1). Register tidak
/// ditampilkan: registrasi melalui admin (KAK §5.1.1).
///
/// Keputusan pemilik project 2026-10-10 (belum di DESIGN.md planning):
/// mengikuti halaman Welcome V2.1, tanpa Skip dan "Create an account",
/// ilustrasi Lottie diganti carousel foto autoplay, copy Bahasa Indonesia.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  /// Jeda autoplay V2.1.
  static const interval = Duration(milliseconds: 4500);

  /// (foto, judul, isi). ponytail: foto placeholder Unsplash (lihat
  /// pubspec.yaml); ganti file di assets/images/welcome/ dengan foto milik
  /// perusahaan tanpa mengubah kode selain path ini.
  static const slides = [
    (
      'assets/images/welcome/welcome_1_placeholder_unsplash_vFs-xMp6G7w.jpg',
      'Driver andal untuk setiap perjalanan dinas',
      'Clock-in, ikuti jadwal hari ini, dan laporkan setiap trip dari satu '
          'aplikasi.',
    ),
    (
      'assets/images/welcome/welcome_2_placeholder_unsplash_oh9FVFAWyvk.jpg',
      'Antar-jemput pegawai tanpa repot',
      'Bantu pegawai bepergian dengan aman dan nyaman di setiap perjalanan '
          'dinas.',
    ),
    (
      'assets/images/welcome/welcome_3_placeholder_unsplash_jb-LAz1hGog.jpg',
      'Hari Anda sudah terencana',
      'Lihat tugas, rute, dan penumpang lebih awal, tanpa bolak-balik chat.',
    ),
  ];

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  int _index = 0;
  Timer? _timer;
  // Pengguna menyentuh titik atau menggeser slide: autoplay berhenti.
  bool _stopped = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Autoplay hanya bila tidak ada reduced motion, tidak ada pembaca layar
  // (slide berganti sendiri mengganggu TalkBack), dan layar sedang tampil
  // (TickerMode mati saat tertutup route Login).
  void _syncTimer() {
    final auto =
        !_stopped &&
        !MediaQuery.disableAnimationsOf(context) &&
        !MediaQuery.accessibleNavigationOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (!auto) {
      _timer?.cancel();
      _timer = null;
    } else {
      _timer ??= Timer.periodic(
        LandingScreen.interval,
        (_) => _show(_index + 1),
      );
    }
  }

  void _show(int i) => setState(() => _index = i % LandingScreen.slides.length);

  void _select(int i) {
    _stopped = true;
    _syncTimer();
    _show(i);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final fade = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 600);
    final (image, title, body) = LandingScreen.slides[_index];
    // V2.1: bingkai foto min 240, maks 420; sisanya untuk teks dan tombol.
    final photoHeight = (MediaQuery.sizeOf(context).height * 0.45).clamp(
      240.0,
      420.0,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: MooverColors.navy,
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    MooverSpace.xl,
                    MooverSpace.md,
                    MooverSpace.xl,
                    0,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Image.asset(
                      'assets/brand/moover-logo-reverse.png',
                      height: 30,
                      semanticLabel: 'Moover',
                    ),
                  ),
                ),
                // Geser kiri/kanan untuk berpindah slide; titik di bawah adalah
                // alternatif yang bisa diakses pembaca layar.
                GestureDetector(
                  // Aksi scroll tidak diekspos: titik sudah menjadi kontrolnya.
                  excludeFromSemantics: true,
                  onHorizontalDragEnd: (d) {
                    final v = d.primaryVelocity ?? 0;
                    if (v != 0) _select(_index + (v < 0 ? 1 : -1));
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          MooverSpace.screen,
                          MooverSpace.screen,
                          MooverSpace.screen,
                          0,
                        ),
                        child: SizedBox(
                          height: photoHeight,
                          child: ClipRRect(
                            // 28: radius bingkai foto V2.1, di luar skala.
                            borderRadius: BorderRadius.circular(28),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                AnimatedSwitcher(
                                  duration: fade,
                                  child: Image.asset(
                                    image,
                                    key: ValueKey(image),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    excludeFromSemantics: true,
                                  ),
                                ),
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      stops: const [0.45, 1],
                                      colors: [
                                        MooverColors.navy.withValues(alpha: 0),
                                        MooverColors.navy.withValues(
                                          alpha: 0.85,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          MooverSpace.xl,
                          28, // V2.1, di luar skala
                          MooverSpace.xl,
                          0,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 150),
                          child: AnimatedSwitcher(
                            duration: fade,
                            layoutBuilder: (current, previous) => Stack(
                              alignment: AlignmentDirectional.topStart,
                              children: [...previous, ?current],
                            ),
                            child: Column(
                              key: ValueKey(_index),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 10, // V2.1, di luar skala
                              children: [
                                Semantics(
                                  container: true,
                                  header: true,
                                  child: Text(
                                    title,
                                    style: textTheme.headlineMedium!.copyWith(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                      height: 1.12,
                                      letterSpacing: -0.75,
                                      color: MooverColors.surface,
                                    ),
                                  ),
                                ),
                                Text(
                                  body,
                                  style: textTheme.bodyLarge!.copyWith(
                                    fontSize: 15,
                                    height: 1.55,
                                    color: MooverColors.sky,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  // Kotak sentuh 48 membuat titik pertama tampak sejajar teks.
                  padding: const EdgeInsetsDirectional.only(
                    start: MooverSpace.md,
                    top: MooverSpace.sm,
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < LandingScreen.slides.length; i++)
                        _Dot(
                          index: i,
                          active: i == _index,
                          duration: fade,
                          onTap: () => _select(i),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.only(bottom: MooverSpace.lg),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              MooverSpace.xl,
              MooverSpace.lg,
              MooverSpace.xl,
              MooverSpace.sm,
            ),
            child: FilledButton(
              // Cyan + label navy: 8,63:1.
              style: FilledButton.styleFrom(
                backgroundColor: MooverColors.cyan,
                foregroundColor: MooverColors.navy,
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
              ),
              child: const Text('Login'),
            ),
          ),
        ),
      ),
    );
  }
}

/// Indikator slide. V2.1: aktif 22×6 cyan, nonaktif 6×6. Penyimpangan:
/// nonaktif #3D6CB8 (2,78:1 di navy) diganti sky (9,54:1) agar ≥3:1, dan
/// area sentuh 32 → 48 (D9).
class _Dot extends StatelessWidget {
  const _Dot({
    required this.index,
    required this.active,
    required this.duration,
    required this.onTap,
  });

  final int index;
  final bool active;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: 'Slide ${index + 1} dari ${LandingScreen.slides.length}',
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox.square(
          dimension: 48,
          child: Center(
            child: AnimatedContainer(
              duration: duration,
              width: active ? 22 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? MooverColors.cyan : MooverColors.sky,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
