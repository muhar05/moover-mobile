import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moover/ui/core/themes/theme.dart';
import 'package:moover/ui/core/widgets/widgets.dart';
import 'package:moover/ui/main_menu/mock_data.dart';
import 'package:moover/ui/time_log/time_log_screen.dart';

import '../core/design_system_test.dart' show contrast;

Widget app({double textScale = 1}) => MaterialApp(
  theme: mooverTheme(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: const TimeLogScreen(),
);

TimeLog day(int inH, int inM, int outH, int outM) => (
  clockIn: (at: DateTime(2030, 1, 2, inH, inM), photo: null),
  clockOut: (at: DateTime(2030, 1, 2, outH, outM), photo: null),
);

Finder cards() => find.byType(Card);

/// Layar tinggi agar ListView membangun semua kartu.
void tall(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(1200, 4000)
    ..devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() => clockIn.value = clockOut.value = null);

  test('status KAK §6.8: Lengkap bila clock-out ≥16.30', () {
    expect(attendanceStatus(day(9, 0, 16, 30)), ('Lengkap', StatusTone.ok));
    expect(attendanceStatus(day(7, 0, 17, 5)).$1, 'Lengkap');
    expect(attendanceStatus(day(7, 30, 16, 29)), (
      'Tidak Lengkap',
      StatusTone.warn,
    ));
    expect(formatDuration(const Duration(hours: 9, minutes: 5)), '9j 05m');
    expect(formatHm(DateTime(2030, 1, 2, 7, 5)), '07.05');
  });

  testWidgets('ringkasan, kartu per hari, filter status', (tester) async {
    tall(tester);
    await tester.pumpWidget(app());
    // Data contoh: 3 hari, 2 lengkap, 9j00 + 6j35 + 9j00.
    expect(find.text('Hari tercatat'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('24j 35m'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('24j 35m')),
      isSemantics(label: 'Total jam\n24 jam 35 menit'),
    );
    expect(cards(), findsNWidgets(3));
    expect(find.text('Clock-out sebelum 16.30'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Tidak Lengkap'));
    await tester.pump();
    expect(cards(), findsOneWidget);
    expect(
      find.descendant(of: cards(), matching: find.text('6j 35m')),
      findsOneWidget,
    );
    // Total tidak lengkap merah (V2.1), status tetap dibawa badge teks.
    expect(
      tester.widget<Text>(find.text('6j 35m')).style!.color,
      StatusTone.err.foreground,
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Lengkap'));
    await tester.pump();
    expect(cards(), findsNWidgets(2));
    expect(find.text('Clock-out sebelum 16.30'), findsNothing);
  });

  testWidgets('hari ini (simulasi) masuk di atas setelah clock-out', (
    tester,
  ) async {
    tall(tester);
    clockIn.value = (at: DateTime(2030, 1, 3, 7, 10), photo: null);
    expect(timeLogs(), hasLength(3)); // belum clock-out: belum dihitung

    clockOut.value = (at: DateTime(2030, 1, 3, 15, 0), photo: null);
    await tester.pumpWidget(app());
    expect(cards(), findsNWidgets(4));
    expect(find.text('4'), findsOneWidget);
    final first = cards().first;
    expect(
      find.descendant(of: first, matching: find.text('07.10')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: first, matching: find.text('Tidak Lengkap')),
      findsOneWidget,
    );
  });

  testWidgets('Lihat bukti: sheet, tab clock-in/out, tanpa klaim area', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('Lihat bukti').first);
    await tester.pumpAndSettle();
    expect(find.text('Bukti kehadiran'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Bukti kehadiran')),
      isSemantics(isHeader: true),
    );
    expect(find.text('Clock-in · 07.30'), findsOneWidget);
    expect(find.bySemanticsLabel('Foto contoh'), findsOneWidget);
    // Radius area kantor Belum ditentukan.
    expect(find.textContaining('area'), findsNothing);
    expect(find.textContaining('simulasi'), findsOneWidget);

    await tester.tap(find.text('Clock-out').last);
    await tester.pumpAndSettle();
    expect(find.text('Clock-out · 16.30'), findsOneWidget);
    expect(find.text('Clock-in · 07.30'), findsNothing);

    await tester.ensureVisible(find.text('Tutup'));
    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();
    expect(find.text('Bukti kehadiran'), findsNothing);
  });

  testWidgets('320dp, teks 200%: daftar dan sheet tanpa overflow', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(960, 1704)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(textScale: 2));
    expect(tester.takeException(), isNull);
    // Gulir sampai akhir daftar (kartu bawah dibangun malas).
    await tester.drag(find.byType(ListView), const Offset(0, -5000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final proof = find.text('Lihat bukti').last;
    await tester.ensureVisible(proof);
    await tester.pumpAndSettle();
    await tester.tap(proof);
    await tester.pumpAndSettle();
    expect(find.text('Bukti kehadiran'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Tutup'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('target sentuh ≥48dp dan kontrol berlabel', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(app());
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await tester.tap(find.text('Lihat bukti').first);
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  test('kontras warna Time Log ≥4,5:1', () {
    for (final (fg, bg) in [
      (MooverColors.surface, MooverColors.navy), // chip terpilih, nilai
      (MooverColors.sky, MooverColors.navy), // label ringkasan
      (StatusTone.err.foreground, MooverColors.surface), // total kurang
      (MooverColors.text, MooverColors.blueTint), // Lihat bukti
      (MooverColors.textMuted, MooverColors.background), // label kolom isi
      // Stempel foto: ink 75% di atas foto terang (kasus terburuk putih).
      (
        MooverColors.surface,
        Color.alphaBlend(
          MooverColors.text.withValues(alpha: 0.75),
          MooverColors.surface,
        ),
      ),
    ]) {
      expect(contrast(fg, bg), greaterThanOrEqualTo(4.5), reason: '$fg/$bg');
    }
  });

  testWidgets('MooverShiftTimes: nilai dari parameter, dibaca berurutan', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: mooverTheme(),
        home: const Scaffold(
          body: MooverShiftTimes(
            clockIn: '06.01',
            clockOut: '18.02',
            total: '12j 01m',
            totalSemanticsLabel: '12 jam 1 menit',
            totalColor: Color(0xFF123456),
          ),
        ),
      ),
    );
    expect(
      tester.getSemantics(find.text('06.01')),
      isSemantics(label: 'Masuk\n06.01'),
    );
    expect(
      tester.getSemantics(find.text('12j 01m')),
      isSemantics(label: 'Total\n12 jam 1 menit'),
    );
    expect(
      tester.widget<Text>(find.text('12j 01m')).style!.color,
      const Color(0xFF123456),
    );
  });
}
