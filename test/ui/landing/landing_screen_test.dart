import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moover_driver/ui/core/themes/theme.dart';
import 'package:moover_driver/ui/landing/landing_screen.dart';
import 'package:moover_driver/ui/login/login_screen.dart';

import '../core/design_system_test.dart' show contrast;

Widget app({
  double textScale = 1,
  bool reduceMotion = false,
  bool screenReader = false,
}) => MaterialApp(
  theme: mooverTheme(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(textScale),
      disableAnimations: reduceMotion,
      accessibleNavigation: screenReader,
    ),
    child: child!,
  ),
  home: const LandingScreen(),
);

String title(int i) => LandingScreen.slides[i].$2;

/// Judul slide yang tampil (setelah crossfade selesai).
Future<void> expectSlide(WidgetTester tester, int i) async {
  await tester.pump(); // frame pertama memulai jam crossfade
  await tester.pump(const Duration(seconds: 1));
  for (var j = 0; j < LandingScreen.slides.length; j++) {
    expect(
      find.text(title(j)),
      j == i ? findsOneWidget : findsNothing,
      reason: 'slide $i',
    );
  }
}

Finder dot(int i) => find.byWidgetPredicate(
  (w) => w is Semantics && w.properties.label == 'Slide ${i + 1} dari 3',
);

/// Titik bisa berada di bawah lipatan pada layar pendek: gulir dulu.
Future<void> tapDot(WidgetTester tester, int i) async {
  await tester.ensureVisible(dot(i));
  await tester.tap(dot(i));
}

void main() {
  testWidgets('Login cyan membuka LoginScreen; tanpa Register/Skip/Create', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    for (final t in ['Register', 'Skip', 'Lewati', 'Create an account']) {
      expect(find.text(t), findsNothing, reason: t);
    }
    final login = find.ancestor(
      of: find.text('Login'),
      matching: find.byType(FilledButton),
    );
    final style = tester.widget<FilledButton>(login).style!;
    final bg = style.backgroundColor!.resolve({})!;
    final fg = style.foregroundColor!.resolve({})!;
    expect((bg, fg), (MooverColors.cyan, MooverColors.navy));
    expect(contrast(fg, bg), greaterThanOrEqualTo(4.5));

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  // Lottie dihapus atas keputusan pemilik project (2026-10-10): tes animasi
  // driving.json diganti pemeriksaan ketiadaan.
  test('Lottie dan driving.json sudah tidak ada', () {
    expect(File('assets/animations/driving.json').existsSync(), isFalse);
    expect(File('pubspec.yaml').readAsStringSync(), isNot(contains('lottie')));
  });

  testWidgets('latar navy, status bar terang, teks kontras', (tester) async {
    await tester.pumpWidget(app());
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      MooverColors.navy,
    );
    expect(
      tester
          .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
            find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
          )
          .value,
      SystemUiOverlayStyle.light,
    );
    Color color(String t) => tester.widget<Text>(find.text(t)).style!.color!;
    expect(color(title(0)), MooverColors.surface);
    expect(color(LandingScreen.slides[0].$3), MooverColors.sky);
    for (final t in [title(0), LandingScreen.slides[0].$3]) {
      expect(contrast(color(t), MooverColors.navy), greaterThanOrEqualTo(4.5));
    }
    // Titik aktif (cyan, memanjang) dan nonaktif: nonteks ≥3:1 di navy.
    final dots = tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .map((d) => (d.decoration! as BoxDecoration).color!)
        .toList();
    expect(dots, [MooverColors.cyan, MooverColors.sky, MooverColors.sky]);
    for (final c in dots) {
      expect(contrast(c, MooverColors.navy), greaterThanOrEqualTo(3));
    }
    expect(
      tester.getSize(find.byType(AnimatedContainer).first).width,
      greaterThan(tester.getSize(find.byType(AnimatedContainer).last).width),
    );
    // Kartu ETA dihapus atas keputusan pemilik project (2026-10-10).
    for (final t in [
      'Kantor Pusat',
      '3 penumpang · 12,4 km',
      'ETA',
      '08.26 WIB',
    ]) {
      expect(find.text(t), findsNothing);
    }
  });

  testWidgets('autoplay tiap 4,5 detik, berputar ke awal', (tester) async {
    await tester.pumpWidget(app());
    await expectSlide(tester, 0);
    await tester.pump(LandingScreen.interval - const Duration(seconds: 1));
    await expectSlide(tester, 1);
    await tester.pump(LandingScreen.interval - const Duration(seconds: 1));
    await expectSlide(tester, 2);
    await tester.pump(LandingScreen.interval - const Duration(seconds: 1));
    await expectSlide(tester, 0);
  });

  for (final (name, a) in [
    ('reduced motion', app(reduceMotion: true)),
    ('pembaca layar', app(screenReader: true)),
  ]) {
    testWidgets('tanpa autoplay saat $name; titik tetap berfungsi', (
      tester,
    ) async {
      await tester.pumpWidget(a);
      await tester.pump(LandingScreen.interval);
      await expectSlide(tester, 0);
      await tapDot(tester, 2);
      await expectSlide(tester, 2);
    });
  }

  testWidgets('autoplay berhenti setelah titik disentuh', (tester) async {
    await tester.pumpWidget(app());
    await tapDot(tester, 1);
    await expectSlide(tester, 1);
    await tester.pump(LandingScreen.interval);
    await expectSlide(tester, 1);
  });

  testWidgets('geser slide berpindah dan menghentikan autoplay', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    final photo = find.byType(ClipRRect);
    await tester.fling(photo, const Offset(-300, 0), 1000);
    await expectSlide(tester, 1);
    await tester.fling(photo, const Offset(300, 0), 1000);
    await expectSlide(tester, 0);
    await tester.fling(photo, const Offset(300, 0), 1000);
    await expectSlide(tester, 2);
    await tester.pump(LandingScreen.interval);
    await expectSlide(tester, 2);
  });

  testWidgets('semantik: judul header, titik berstatus, kartu ETA tidak ada', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(app());
    expect(
      tester.getSemantics(find.text(title(0))),
      isSemantics(label: title(0), isHeader: true),
    );
    expect(
      tester.getSemantics(dot(0)),
      isSemantics(
        label: 'Slide 1 dari 3',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(dot(1)),
      isSemantics(label: 'Slide 2 dari 3', isSelected: false),
    );
    expect(find.bySemanticsLabel(RegExp('ETA|Kantor Pusat')), findsNothing);
    expect(find.bySemanticsLabel('Moover'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('tidak overflow di layar 320x568dp, teks 200%', (tester) async {
    tester.view
      ..physicalSize = const Size(960, 1704)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app(textScale: 2));
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -2000),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Login').hitTestable(), findsOneWidget);
    expect(dot(2).hitTestable(), findsOneWidget);
  });

  testWidgets('target sentuh ≥48dp dan kontrol berlabel', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(app());
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
