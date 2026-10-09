import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:moover_driver/design/theme.dart';
import 'package:moover_driver/screens/landing.dart';
import 'package:moover_driver/screens/login.dart';

Widget app({double textScale = 1, bool reduceMotion = false}) => MaterialApp(
  theme: mooverTheme(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(textScale),
      disableAnimations: reduceMotion,
    ),
    child: child!,
  ),
  home: const LandingPage(),
);

void main() {
  testWidgets('Login membuka LoginPage; tanpa tombol Register', (tester) async {
    await tester.pumpWidget(app());
    expect(find.text('Register'), findsNothing);
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
  });

  test('driving.json terbaca oleh parser lottie', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final c = await AssetLottie('assets/animations/driving.json').load();
    expect(c.duration, greaterThan(Duration.zero));
    expect(c.duration, lessThan(const Duration(seconds: 5)));
  });

  Future<void> loadComposition(WidgetTester tester) async {
    // Muat aset (I/O nyata) lalu biarkan composition terpasang.
    await tester.runAsync(() => Future.delayed(const Duration(seconds: 1)));
    await tester.pump();
  }

  double progress(WidgetTester tester) =>
      tester.widget<RawLottie>(find.byType(RawLottie)).progress;

  testWidgets('animasi sekali lalu diam di frame terakhir', (tester) async {
    await tester.pumpWidget(app());
    await loadComposition(tester);
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.binding.hasScheduledFrame, isTrue, reason: 'tidak jalan');
    expect(progress(tester), inExclusiveRange(0, 1));

    await tester.pump(const Duration(seconds: 5)); // melewati durasi 2 detik
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse, reason: 'masih jalan');
    expect(progress(tester), 1);
  });

  testWidgets('reduced motion: statis di frame pertama', (tester) async {
    await tester.pumpWidget(app(reduceMotion: true));
    await loadComposition(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(progress(tester), 0);
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
  });

  testWidgets('target sentuh ≥48dp dan kontrol berlabel', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(app());
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
