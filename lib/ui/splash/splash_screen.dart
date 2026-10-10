import 'package:flutter/material.dart';

import '../core/themes/theme.dart';
import '../core/widgets/widgets.dart';
import '../landing/landing_screen.dart';

/// Gradient khusus Splash: hitam → biru brand (gaya kartu gelap web). Layar
/// lain memakai permukaan solid.
const splashGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [MooverColors.text, MooverColors.g900, MooverColors.g500],
  stops: [0, 0.6, 1],
);

/// S00 Splash: logo fade + scale 600 ms, total ±1,2 dtk, lalu Landing
/// menggantikan route ini (Back tidak kembali ke Splash). Reduced motion:
/// tanpa animasi dan tanpa jeda.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
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
        pageBuilder: (_, _, _) => const LandingScreen(),
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
    // Logo biru (±#0040A0) di atas gradient hanya 1,1–2,1:1, jadi diberi
    // bidang putih (9,4:1; bidang vs g500 4,38:1). Radius belum ditentukan di DESIGN.md.
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
