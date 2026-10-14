import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moover/ui/attendance/attendance_screen.dart';
import 'package:moover/ui/core/themes/theme.dart';
import 'package:moover/ui/core/widgets/widgets.dart';
import 'package:moover/ui/main_menu/mock_data.dart' show Punch;

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

/// Kanal paket camera (implementasi bawaan di tes): satu kamera depan.
/// [create] melempar = izin ditolak; [calls] mencatat nama metode.
List<String> fakeCamera(
  WidgetTester tester, {
  Object? Function()? create,
  String photo = '/tmp/selfie.jpg',
}) {
  final calls = <String>[];
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/camera'),
    (call) async {
      calls.add(call.method);
      switch (call.method) {
        case 'availableCameras':
          return [
            {'name': 'back', 'lensFacing': 'back', 'sensorOrientation': 90},
            {'name': 'front', 'lensFacing': 'front', 'sensorOrientation': 270},
          ];
        case 'create':
          calls.add('create:${(call.arguments as Map)['cameraName']}');
          return create?.call() ?? {'cameraId': 1};
        case 'initialize':
          // Kamera asli mengirim event "initialized" lewat kanal per kamera.
          scheduleMicrotask(
            () => messenger.handlePlatformMessage(
              'flutter.io/cameraPlugin/camera1',
              const StandardMethodCodec().encodeMethodCall(
                const MethodCall('initialized', {
                  'previewWidth': 640.0,
                  'previewHeight': 480.0,
                  'exposureMode': 'auto',
                  'exposurePointSupported': false,
                  'focusMode': 'auto',
                  'focusPointSupported': false,
                }),
              ),
              (_) {},
            ),
          );
          return null;
        case 'takePicture':
          return photo;
      }
      return null;
    },
  );
  addTearDown(
    () => messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/camera'),
      null,
    ),
  );
  return calls;
}

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

  testWidgets('kamera depan tampil di bingkai; jepret → foto, kamera dilepas', (
    tester,
  ) async {
    final calls = fakeCamera(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    // Di dalam layar app (bukan aplikasi kamera bawaan), kamera depan.
    expect(find.byType(CameraPreview), findsOneWidget);
    expect(calls, contains('create:front'));
    expect(find.textContaining('Foto diambil'), findsNothing);
    expect(primary(tester).onPressed, isNull);

    // Preview memenuhi kotak kamera; oval panduan di tengah, di dalamnya.
    final preview = tester.getRect(
      find
          .ancestor(
            of: find.byType(CameraPreview),
            matching: find.byType(FittedBox),
          )
          .first,
    );
    final box = tester.getRect(
      find
          .ancestor(
            of: find.byType(CameraPreview),
            matching: find.byType(Stack),
          )
          .first,
    );
    expect(preview, box);
    final oval = tester.getRect(
      find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            w.decoration is ShapeDecoration &&
            (w.decoration as ShapeDecoration).shape is OvalBorder,
      ),
    );
    expect(oval.center.dx, closeTo(preview.center.dx, 0.5));
    expect(preview.contains(oval.topLeft), isTrue);
    expect(preview.contains(oval.bottomRight), isTrue);
    expect(oval.width, lessThan(preview.width / 2));
    // Teks di atas preview: lapisan gelap, terbaca walau gambar putih penuh.
    final scrim = tester
        .widget<ColoredBox>(
          find
              .ancestor(
                of: find.text('Posisikan wajah di dalam bingkai'),
                matching: find.byType(ColoredBox),
              )
              .first,
        )
        .color;
    final onWhite = Color.alphaBlend(scrim, MooverColors.surface);
    for (final c in [MooverColors.sky, MooverColors.amber]) {
      expect(contrast(c, onWhite), greaterThanOrEqualTo(4.5));
    }

    await tester.tap(find.byTooltip('Ambil foto'));
    await tester.pumpAndSettle();
    expect(calls, contains('takePicture'));
    expect(find.textContaining('Foto diambil · '), findsOneWidget);
    expect(find.bySemanticsLabel('Foto clock-in Anda'), findsOneWidget);
    expect(find.byType(CameraPreview), findsNothing);
    expect(calls.last, 'dispose');
    expect(primary(tester).onPressed, isNotNull);

    // Ulangi: kamera dibuka lagi.
    await tapText(tester, 'Ulangi');
    await tester.pumpAndSettle();
    expect(find.byType(CameraPreview), findsOneWidget);
    expect(calls.where((c) => c == 'initialize'), hasLength(2));
  });

  testWidgets('kamera gagal (izin ditolak): pesan error, bisa coba lagi', (
    tester,
  ) async {
    var deny = true;
    final calls = fakeCamera(
      tester,
      create: () => deny
          ? throw PlatformException(code: 'CameraAccessDenied')
          : {'cameraId': 1},
    );
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.byType(CameraPreview), findsNothing);
    const msg =
        'Kamera tidak dapat dibuka. Izinkan akses kamera, lalu coba lagi.';
    expect(find.text(msg), findsOneWidget);
    // Amber di bidang kamera (putih 8% di atas navy).
    final bg = Color.alphaBlend(const Color(0x14FFFFFF), MooverColors.navy);
    expect(
      contrast(tester.widget<Text>(find.text(msg)).style!.color!, bg),
      greaterThanOrEqualTo(4.5),
    );
    // Ketuk tombol jepret = buka kamera lagi (mis. setelah izin diberikan).
    deny = false;
    await tester.tap(find.byTooltip('Ambil foto'));
    await tester.pumpAndSettle();
    expect(find.text(msg), findsNothing);
    expect(find.byType(CameraPreview), findsOneWidget);
    expect(calls, isNot(contains('takePicture')));
  });

  testWidgets(
    'simulasi foto → Ulangi → kirim: busy lalu kembali dengan waktu',
    (tester) async {
      Punch? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: mooverTheme(),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await Navigator.of(context)
                  .push<Punch>(
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

  testWidgets('mode clock-out: judul, tombol, peringatan sebelum 16.30', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: mooverTheme(),
        home: const AttendanceScreen(clockOut: true),
      ),
    );
    final now = DateTime.now();
    expect(find.text('Clock-out'), findsOneWidget);
    await tapText(tester, 'Simulasi tanpa kamera');
    expect(primary(tester).label, 'Kirim clock-out');
    // KAK §6.8: clock-out sebelum 16.30 = Tidak Lengkap; diberi tahu dulu.
    final early = now.hour * 60 + now.minute < 16 * 60 + 30;
    expect(
      find.textContaining('Tidak Lengkap'),
      early ? findsOneWidget : findsNothing,
    );
  });
}
