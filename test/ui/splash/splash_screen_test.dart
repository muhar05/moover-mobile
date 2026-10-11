import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moover/ui/core/themes/theme.dart';
import 'package:moover/ui/core/widgets/widgets.dart';
import 'package:moover/ui/landing/landing_screen.dart';
import 'package:moover/ui/splash/splash_screen.dart';

class NavCount extends NavigatorObserver {
  int replaces = 0;
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      replaces++;
}

Widget app(NavCount nav, {bool reduceMotion = false}) => MaterialApp(
  theme: mooverTheme(),
  navigatorObservers: [nav],
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
    child: child!,
  ),
  home: const SplashScreen(),
);

double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

void main() {
  testWidgets('logo berlabel di tengah, di atas bidang putih', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(app(NavCount()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600)); // fade selesai
    expect(find.byType(MooverLogo), findsOneWidget);
    expect(find.bySemanticsLabel('Moover'), findsOneWidget);

    final screen = tester.getSize(find.byType(SplashScreen));
    final logo = tester.getRect(find.byType(MooverLogo));
    expect(logo.center.dx, closeTo(screen.width / 2, 1));
    expect(logo.center.dy, closeTo(screen.height / 2, 1));
    // Bidang putih langsung di belakang logo, bukan gradient gelap.
    final plate = tester.widget<DecoratedBox>(
      find
          .ancestor(
            of: find.byType(MooverLogo),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect((plate.decoration as BoxDecoration).color, MooverColors.surface);
    handle.dispose();
  });

  testWidgets('background gradient biru Splash memenuhi layar', (tester) async {
    await tester.pumpWidget(app(NavCount()));
    final box = find.byWidgetPredicate(
      (w) =>
          w is DecoratedBox &&
          w.decoration == const BoxDecoration(gradient: splashGradient),
    );
    expect(box, findsOneWidget);
    expect(tester.getSize(box), tester.getSize(find.byType(SplashScreen)));
    expect(splashGradient.colors, const [
      Color(0xFF0B1730),
      Color(0xFF06275C),
      Color(0xFF0A84D8),
    ]);
    // Warna logo terbanyak ±#0040A0 di atas bidang putih.
    expect(
      contrast(const Color(0xFF0040A0), MooverColors.surface),
      greaterThanOrEqualTo(4.5),
    );
    // Bidang putih tetap menonjol dari warna gradient paling terang.
    expect(
      contrast(MooverColors.surface, splashGradient.colors.last),
      greaterThanOrEqualTo(3),
    );
  });

  testWidgets(
    'lanjut ke Landing sekali setelah ±1,2 dtk; Back tidak ke Splash',
    (tester) async {
      final nav = NavCount();
      await tester.pumpWidget(app(nav));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1150));
      expect(find.byType(LandingScreen), findsNothing);

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.byType(LandingScreen), findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing);
      expect(nav.replaces, 1);

      // Back sistem: tidak ada route di bawah Landing.
      expect(
        tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
        isFalse,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(SplashScreen), findsNothing);

      // Kembali dari background tidak memutar ulang Splash.
      tester.binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.paused)
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byType(SplashScreen), findsNothing);
      expect(nav.replaces, 1);
    },
  );

  testWidgets('reduced motion: tanpa animasi, tanpa jeda, navigasi sekali', (
    tester,
  ) async {
    final nav = NavCount();
    await tester.pumpWidget(app(nav, reduceMotion: true));
    // Hanya pembungkus logo di dalam Splash; transisi route dan FAB Scaffold
    // bukan animasi logo.
    Finder logoWrap(Type t) => find.descendant(
      of: find.byType(SplashScreen),
      matching: find.ancestor(
        of: find.byType(MooverLogo),
        matching: find.byType(t),
      ),
    );
    expect(logoWrap(FadeTransition), findsNothing);
    expect(logoWrap(ScaleTransition), findsNothing);
    await tester.pump(); // post-frame: navigasi
    await tester.pump(); // transisi Duration.zero
    expect(find.byType(LandingScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);

    await tester.pump(const Duration(seconds: 3));
    expect(nav.replaces, 1);
  });

  testWidgets('dilepas di tengah animasi: tidak navigasi, ticker bersih', (
    tester,
  ) async {
    final nav = NavCount();
    await tester.pumpWidget(app(nav));
    await tester.pump(const Duration(milliseconds: 300));
    // flutter_test menggagalkan test bila ticker/timer masih aktif.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    expect(nav.replaces, 0);
  });
}
