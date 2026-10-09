import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moover_driver/design/theme.dart';
import 'package:moover_driver/screens/login.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

const notConnected =
    'Masuk belum tersedia: aplikasi belum terhubung ke server.';

Widget app({double textScale = 1}) => MaterialApp(
  theme: mooverTheme(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: const LoginPage(),
);

void main() {
  testWidgets('Masuk dengan field kosong menampilkan validasi per field', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('Masuk'));
    await tester.pump();
    expect(find.text('Employee ID wajib diisi.'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi.'), findsOneWidget);
    expect(find.text(notConnected), findsNothing);

    await tester.enterText(find.byType(TextFormField).first, 'DRV001');
    await tester.pump();
    expect(find.text('Employee ID wajib diisi.'), findsNothing);
    expect(find.text('Kata sandi wajib diisi.'), findsOneWidget);
  });

  testWidgets('Masuk dengan field terisi tidak berpura-pura berhasil', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.enterText(find.byType(TextFormField).first, 'DRV001');
    await tester.enterText(find.byType(TextFormField).last, 'rahasia');
    await tester.tap(find.text('Masuk'));
    await tester.pump();
    expect(find.text(notConnected), findsOneWidget);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('kata sandi bisa ditampilkan dan disembunyikan', (tester) async {
    await tester.pumpWidget(app());
    bool obscured() =>
        tester.widget<TextField>(find.byType(TextField).last).obscureText;
    expect(obscured(), isTrue);
    await tester.tap(find.byTooltip('Tampilkan kata sandi'));
    await tester.pump();
    expect(obscured(), isFalse);
    await tester.tap(find.byTooltip('Sembunyikan kata sandi'));
    await tester.pump();
    expect(obscured(), isTrue);
  });

  testWidgets('tidak overflow di layar 320x568dp, teks 200%, dengan error', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(960, 1704)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app(textScale: 2));
    await tester.tap(find.text('Masuk'), warnIfMissed: false);
    await tester.pump();
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -2000),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('label field ≥4,5:1 terhadap latar layar (hitungan WCAG)', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    final bg = mooverTheme().scaffoldBackgroundColor;
    Future<void> check(String state) async {
      await tester.pumpAndSettle();
      for (final label in ['Employee ID', 'Kata sandi']) {
        final fg = tester
            .widget<RichText>(
              find.descendant(
                of: find.text(label),
                matching: find.byType(RichText),
              ),
            )
            .text
            .style!
            .color!;
        expect(
          contrast(fg, bg),
          greaterThanOrEqualTo(4.5),
          reason: '$label $state $fg',
        );
      }
    }

    await check('normal');
    await tester.tap(find.byType(TextFormField).first);
    await check('fokus (Employee ID), normal (Kata sandi)');
    await tester.enterText(find.byType(TextFormField).first, 'DRV001');
    await tester.tap(find.byType(TextFormField).last);
    await check('mengambang tanpa fokus (Employee ID), fokus (Kata sandi)');
    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.tap(find.text('Masuk'));
    await check('error');
  });

  testWidgets('target sentuh ≥48dp dan kontrol berlabel', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(app());
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
