import 'package:flutter/material.dart';

import '../design/theme.dart';
import '../design/widgets.dart';
import 'landing.dart';

/// Gradient khusus Splash dari token palet Aqua Nebula. Layar lain memakai
/// permukaan solid.
const splashGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [MooverColors.abyss, MooverColors.steel, MooverColors.teal],
  stops: [0, 0.6, 1],
);

/// S00 Splash: logo fade + scale 600 ms, total ±1,2 dtk, lalu Landing
/// menggantikan route ini (Back tidak kembali ke Splash). Reduced motion:
/// tanpa animasi dan tanpa jeda.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  // Satu controller untuk seluruh 1,2 dtk; logo beranimasi di paruh pertama.
  // Ticker, bukan Timer: berhenti bersama dispose.
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final _logo = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.5, curve: Curves.easeOutCubic),
  );
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((s) {
      if (s == AnimationStatus.completed) _goToLanding();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _goToLanding();
      } else {
        _controller.forward();
      }
    });
  }

  void _goToLanding() {
    if (_left || !mounted) return;
    _left = true;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => const LandingPage(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  void dispose() {
    _logo.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ponytail: tinggi 64 dp (lebar ±192 dp, muat di layar 320 dp); ganti
    // bila DESIGN.md menetapkan ukuran logo Splash.
    // Logo biru (±#0040A0) di atas gradient gelap hanya 1,1–3,1:1, jadi
    // diberi bidang putih (9,4:1). Radius belum ditentukan di DESIGN.md.
    Widget logo = const DecoratedBox(
      decoration: BoxDecoration(
        color: MooverColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: MooverLogo(height: 64),
      ),
    );
    if (!MediaQuery.disableAnimationsOf(context)) {
      logo = FadeTransition(
        opacity: _logo,
        child: ScaleTransition(
          scale: Tween(begin: 0.92, end: 1.0).animate(_logo),
          child: logo,
        ),
      );
    }
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: splashGradient),
        child: Center(child: logo),
      ),
    );
  }
}
