import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moover/ui/attendance/attendance_screen.dart';
import 'package:moover/ui/core/themes/theme.dart';
import 'package:moover/ui/core/widgets/widgets.dart';

import '../core/design_system_test.dart' show contrast;

Widget app({double textScale = 1}) => MaterialApp(
  theme: mooverTheme(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: const AttendanceScreen(),
);

/// Kanal image_picker (implementasi bawaan di tes). [result] dipanggil
/// untuk tiap pickImage.
void mockPicker(WidgetTester tester, Object? Function() result) =>
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/image_picker'),
      (call) async => call.method == 'pickImage' ? result() : null,
    );

/// Lembar bawah bisa di luar layar tes (800×600): gulir dulu, lalu ketuk.
Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.pump();
  await tester.tap(find.text(text));
  await tester.pump();
}

PrimaryButton primary(WidgetTester tester) =>
    tester.widget<PrimaryButton>(find.byType(PrimaryButton));

void main() {
  testWidgets('awal: bingkai wajah, jam, lokasi simulasi, kirim nonaktif', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    expect(find.text('Posisikan wajah di dalam bingkai'), findsOneWidget);
    expect(find.text('Jam operasional'), findsOneWidget);
    expect(find.text('07.30–16.30'), findsOneWidget);
    expect(find.text('Lokasi simulasi'), findsOneWidget);
    // Radius area Belum ditentukan: tanpa klaim "di dalam area".
    expect(find.textContaining('area'), findsNothing);
    expect(primary(tester).label, 'Ambil foto untuk lanjut');
    expect(primary(tester).onPressed, isNull);
  });

  testWidgets('kamera dibatalkan: tetap tanpa foto', (tester) async {
    mockPicker(tester, () => null);
    await tester.pumpWidget(app());
    await tester.tap(find.byTooltip('Ambil foto'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Foto diambil'), findsNothing);
    expect(primary(tester).onPressed, isNull);
  });

  testWidgets('kamera gagal (izin ditolak): pesan error, bisa coba lagi', (
    tester,
  ) async {
    mockPicker(
      tester,
      () => throw PlatformException(code: 'camera_access_denied'),
    );
    await tester.pumpWidget(app());
    await tester.tap(find.byTooltip('Ambil foto'));
    await tester.pumpAndSettle();
    const msg =
        'Kamera tidak dapat dibuka. Izinkan akses kamera, lalu coba lagi.';
    expect(find.text(msg), findsOneWidget);
    // Amber di bidang kamera (putih 8% di atas navy).
    final bg = Color.alphaBlend(const Color(0x14FFFFFF), MooverColors.navy);
    expect(
      contrast(tester.widget<Text>(find.text(msg)).style!.color!, bg),
      greaterThanOrEqualTo(4.5),
    );
    expect(find.byTooltip('Ambil foto'), findsOneWidget);
  });

  testWidgets(
    'simulasi foto → Ulangi → kirim: busy lalu kembali dengan waktu',
    (tester) async {
      DateTime? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: mooverTheme(),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await Navigator.of(context)
                  .push<DateTime>(
                    MaterialPageRoute(builder: (_) => const AttendanceScreen()),
                  ),
              child: const Text('buka'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('buka'));
      await tester.pumpAndSettle();

      await tapText(tester, 'Simulasi tanpa kamera');
      expect(find.textContaining('Foto diambil · '), findsOneWidget);
      expect(find.bySemanticsLabel('Foto simulasi'), findsOneWidget);
      await tapText(tester, 'Ulangi');
      expect(find.textContaining('Foto diambil'), findsNothing);

      await tapText(tester, 'Simulasi tanpa kamera');
      await tapText(tester, 'Kirim clock-in');
      expect(primary(tester).busy, isTrue); // D10: tidak bisa ditekan ulang
      expect(result, isNull);
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      expect(find.byType(AttendanceScreen), findsNothing);
      expect(result, isNotNull);
      expect(find.textContaining('berhasil'), findsNothing);
    },
  );

  testWidgets('320dp, teks 200%: tanpa overflow, aksi bisa dicapai', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(960, 1704)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(textScale: 2));
    expect(tester.takeException(), isNull);
    await tapText(tester, 'Simulasi tanpa kamera');
    await tester.ensureVisible(find.text('Kirim clock-in'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('target sentuh ≥48dp dan tombol berlabel', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(app());
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    expect(find.bySemanticsLabel('Clock-in'), findsOneWidget);
    handle.dispose();
  });
}
