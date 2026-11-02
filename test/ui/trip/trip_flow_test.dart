import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:moover/ui/core/themes/theme.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:moover/ui/core/widgets/widgets.dart';
import 'package:moover/ui/main_menu/main_menu_screen.dart';
import 'package:moover/ui/main_menu/mock_data.dart';
import 'package:moover/ui/trip/trip_detail_screen.dart';
import 'package:moover/ui/trip/trip_store.dart';

import '../core/design_system_test.dart' show contrast;

Widget app({Widget home = const MainMenuScreen(), double textScale = 1}) =>
    MaterialApp(
      theme: mooverTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: home,
    );

final first = tripsToday.first;

Future<void> tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

/// Beranda → kartu jadwal pertama → S07.
Future<void> openFirst(WidgetTester tester) async {
  await tester.pumpWidget(app());
  await tap(tester, find.byType(MooverTripItem).first);
}

/// S07 → Mulai trip → dialog Mulai → S08.
Future<void> start(WidgetTester tester) async {
  await tap(tester, find.text('Mulai trip'));
  expect(find.text('Mulai trip?'), findsOneWidget); // D8
  await tap(tester, find.widgetWithText(FilledButton, 'Mulai'));
}

String statusOnHome(WidgetTester tester) =>
    tester.widget<MooverTripItem>(find.byType(MooverTripItem).first).status;

void main() {
  setUp(() {
    tripStatus.value = {};
    activeTrip.value = null;
  });

  testWidgets('alur Start → S08 → Back → banner → End → S10 → Beranda', (
    tester,
  ) async {
    await openFirst(tester);
    expect(find.byType(TripDetailScreen), findsOneWidget);
    expect(find.text(first.number), findsOneWidget);
    expect(find.text('Terjadwal'), findsOneWidget);

    // Dialog D8 bisa dibatalkan tanpa mengubah status.
    await tap(tester, find.text('Mulai trip'));
    await tap(tester, find.text('Batal'));
    expect(activeTrip.value, isNull);

    await start(tester);
    expect(find.byType(ActiveTripScreen), findsOneWidget);
    // Tone On Trip = indigo seperti web (keputusan 2026-10-13).
    expect(
      tester.widget<StatusBadge>(find.byType(StatusBadge)).tone,
      StatusTone.indigo,
    );
    expect(find.text('Dalam Perjalanan'), findsOneWidget);
    expect(activeTrip.value?.trip.number, first.number);

    // UD1: Back ke Beranda (bukan S07), trip tetap berjalan, banner tampil.
    await tap(tester, find.byTooltip('Kembali ke Beranda'));
    expect(find.byType(MainMenuScreen), findsOneWidget);
    expect(find.byType(TripDetailScreen), findsNothing);
    expect(statusOnHome(tester), 'Dalam Perjalanan');
    expect(find.text('Trip berjalan · Lanjutkan'), findsOneWidget);
    // Banner tampil di semua tab.
    await tester.tap(find.text('Akun'));
    await tester.pumpAndSettle();
    expect(find.text('Trip berjalan · Lanjutkan'), findsOneWidget);

    await tap(tester, find.text('Trip berjalan · Lanjutkan'));
    expect(find.byType(ActiveTripScreen), findsOneWidget);

    // Sheet End: "Akhiri" nonaktif sampai dicentang; "Belum" kembali.
    await tap(tester, find.text('Akhiri trip'));
    expect(find.text('Akhiri trip ini?'), findsOneWidget);
    final end = find.widgetWithText(FilledButton, 'Akhiri');
    expect(tester.widget<FilledButton>(end).onPressed, isNull);
    await tap(tester, find.text('Belum'));
    expect(activeTrip.value, isNotNull);

    await tap(tester, find.text('Akhiri trip'));
    await tap(tester, find.byType(CheckboxListTile));
    await tap(tester, end);
    expect(find.byType(QrFeedbackScreen), findsOneWidget);
    expect(find.text(first.number), findsOneWidget);
    expect(activeTrip.value, isNull);
    // D10: tanpa klaim berhasil.
    expect(
      find.textContaining(RegExp('berhasil', caseSensitive: false)),
      findsNothing,
    );

    await tap(tester, find.text('Selesai'));
    expect(find.byType(MainMenuScreen), findsOneWidget);
    expect(find.text('Trip berjalan · Lanjutkan'), findsNothing);
    await tester.tap(find.text('Beranda'));
    await tester.pumpAndSettle();
    expect(statusOnHome(tester), 'Menunggu Feedback');

    // Trip yang sudah diakhiri tidak bisa dimulai lagi.
    await tap(tester, find.byType(MooverTripItem).first);
    expect(find.text('Mulai trip'), findsNothing);
    expect(find.text('Batalkan'), findsNothing);
  });

  testWidgets('satu trip berjalan: trip lain tidak bisa dimulai', (
    tester,
  ) async {
    activeTrip.value = (trip: first, startedAt: DateTime(2030));
    setTripStatus(first, onTrip);
    await tester.pumpWidget(app());
    await tap(tester, find.byType(MooverTripItem).at(1));
    final startButton = find.ancestor(
      of: find.text('Mulai trip'),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );
    expect(tester.widget<ButtonStyleButton>(startButton).onPressed, isNull);
    expect(
      find.text('Akhiri trip yang sedang berjalan sebelum memulai trip ini.'),
      findsOneWidget,
    );

    // Trip yang berjalan langsung membuka S08.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tap(tester, find.byType(MooverTripItem).first);
    expect(find.byType(ActiveTripScreen), findsOneWidget);
  });

  testWidgets('Cancel Trip wajib alasan, lalu Dibatalkan', (tester) async {
    await openFirst(tester);
    await tap(tester, find.text('Batalkan'));
    expect(find.text('Batalkan trip ini?'), findsOneWidget);
    for (final r in cancelReasons) {
      expect(find.text(r), findsOneWidget);
    }
    final confirm = find.widgetWithText(FilledButton, 'Batalkan trip');
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

    await tap(tester, find.text('Jadwal berubah'));
    await tap(tester, confirm);
    expect(find.byType(TripDetailScreen), findsNothing);
    expect(statusOnHome(tester), 'Dibatalkan');
    expect(find.textContaining('simulasi'), findsOneWidget);
    expect(activeTrip.value, isNull);
  });

  testWidgets('320dp + teks 200%: S07, S08, S10 tanpa overflow', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(960, 1704)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final active = (trip: first, startedAt: DateTime(2030, 1, 1, 9, 5));
    for (final screen in <Widget>[
      TripDetailScreen(trip: first),
      ActiveTripScreen(active: active),
      QrFeedbackScreen(trip: first),
    ]) {
      await tester.pumpWidget(app(home: screen, textScale: 2));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '${screen.runtimeType}');
    }
    // Sheet End juga muat.
    await tester.pumpWidget(
      app(home: ActiveTripScreen(active: active), textScale: 2),
    );
    await tap(tester, find.text('Akhiri trip'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('S10: QR asli berisi nomor trip, kontras tinggi', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(app(home: QrFeedbackScreen(trip: first)));
    expect(find.byType(QrImageView), findsOneWidget);
    expect(
      find.bySemanticsLabel('QR feedback trip ${first.number}'),
      findsOneWidget,
    );
    // Isi QR: gambar painter layar == gambar QR acuan dari nomor trip.
    final painter =
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: find.byType(QrImageView),
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter!
            as QrPainter;
    final reference = QrPainter(
      data: first.number,
      version: QrVersions.auto,
      errorCorrectionLevel: painter.errorCorrectionLevel,
      gapless: painter.gapless,
      eyeStyle: painter.eyeStyle,
      dataModuleStyle: painter.dataModuleStyle,
    );
    final (got, want) = (await tester.runAsync(
      () async => (
        (await painter.toImageData(200))!.buffer.asUint8List(),
        (await reference.toImageData(200))!.buffer.asUint8List(),
      ),
    ))!;
    expect(got, want);
    expect(painter.eyeStyle.color, MooverColors.text);
    expect(painter.dataModuleStyle.color, MooverColors.text);
    expect(
      contrast(MooverColors.text, MooverColors.surface),
      greaterThanOrEqualTo(4.5),
    );
    handle.dispose();
  });

  testWidgets('target sentuh, label, semantik', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(app(home: TripDetailScreen(trip: first)));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    expect(
      tester.getSemantics(find.text('Waktu jemput')),
      isSemantics(label: 'Waktu jemput\n${first.time}'),
    );

    activeTrip.value = (trip: first, startedAt: DateTime(2030, 1, 1, 9, 5));
    await tester.pumpWidget(
      app(home: ActiveTripScreen(active: activeTrip.value!)),
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    expect(find.text('Mulai 09.05 WIB'), findsOneWidget);

    await tester.pumpWidget(app());
    expect(
      find.bySemanticsLabel(RegExp('^Trip berjalan · Lanjutkan')),
      findsOneWidget,
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('peta rute S07/S08: OSM + atribusi, dekoratif, fallback', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    // Tile yang tertunda dari tes lain (zona waktu palsu) jangan dipakai
    // ulang: harus dimuat, dan gagal, lagi.
    imageCache.clear();
    await tester.pumpWidget(app(home: TripDetailScreen(trip: first)));
    await tester.pumpAndSettle();
    final map = find.byType(FlutterMap);
    expect(map, findsOneWidget);
    final (origin, destination) = tripPoints[first.number]!;
    expect(
      tester
          .widget<PolylineLayer>(find.byType(PolylineLayer))
          .polylines
          .single
          .points,
      [origin, destination],
    );
    expect(
      tester.widget<TileLayer>(find.byType(TileLayer)).urlTemplate,
      contains('tile.openstreetmap.org'),
    );
    expect(find.text('© OpenStreetMap'), findsOneWidget);
    // Isi peta tidak dibaca TalkBack (rute sudah ada sebagai teks).
    expect(
      find.ancestor(of: map, matching: find.byType(ExcludeSemantics)),
      findsWidgets,
    );
    // Tile tidak bisa diambil di tes (HTTP 400): catatan tampil, detail tetap.
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    }
    expect(
      find.text('Peta tidak dapat dimuat. Periksa koneksi internet.'),
      findsOneWidget,
    );
    expect(find.text('Waktu jemput'), findsOneWidget);

    await tester.pumpWidget(
      app(
        home: ActiveTripScreen(
          active: (trip: first, startedAt: DateTime(2030, 1, 1, 9, 5)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.text('Peta rute belum tersedia.'), findsNothing);

    // Trip tanpa titik peta: tanpa peta.
    final noPoints = tripHistory.first;
    expect(tripPoints[noPoints.number], isNull);
    await tester.pumpWidget(app(home: TripDetailScreen(trip: noPoints)));
    expect(find.byType(FlutterMap), findsNothing);
    handle.dispose();
  });

  testWidgets('S09 tambah tujuan: tiba berurutan, peta lewat semua titik, '
      'End menutup tujuan terakhir', (tester) async {
    tester.view
      ..physicalSize = const Size(960, 1704)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final geocode = reverseGeocode;
    reverseGeocode = (_) async => 'Halte Uji';
    addTearDown(() => reverseGeocode = geocode);
    final (origin, destination) = tripPoints[first.number]!;
    // Langsung di S08 (alur Start diuji di atas), teks 200% di 320dp.
    activeTrip.value = (trip: first, startedAt: DateTime(2030, 1, 1, 9, 5));
    setTripStatus(first, onTrip);
    await tester.pumpWidget(
      app(home: ActiveTripScreen(active: activeTrip.value!), textScale: 2),
    );
    await tester.pumpAndSettle();
    expect(find.text('Daftar tujuan'), findsNothing); // satu tujuan
    expect(find.text('Tiba di tujuan ini'), findsNothing);

    // Mulai dari tujuan terakhir; geser → titik baru, nama dari peta.
    await tap(tester, find.text('Tujuan'));
    expect(find.text('Tambah tujuan'), findsOneWidget);
    expect(
      MapCamera.of(tester.element(find.text('© OpenStreetMap'))).center,
      destination,
    );
    await tester.drag(find.byType(FlutterMap), const Offset(-100, 0));
    await tester.pumpAndSettle();
    await tap(tester, find.text('Pilih titik ini'));
    // Alamat lengkap manual, opsional (2026-10-14).
    expect(tester.takeException(), isNull, reason: 'dialog alamat');
    await tester.enterText(find.byType(TextField), ' Jl. Halte No. 2 ');
    await tap(tester, find.text('Tambahkan'));
    expect(find.byType(ActiveTripScreen), findsOneWidget);
    expect(stopsOf(first).last.address, 'Jl. Halte No. 2');
    final added = stopsOf(first).last.point!;
    expect(added.longitude, greaterThan(destination.longitude));
    expect(stopsOf(first).map((s) => s.name), [
      tripDestination(first),
      'Halte Uji',
    ]);
    // Teks 200% di 320dp: kartu tujuan muat.
    expect(tester.takeException(), isNull);
    // S08 berupa ListView lazy: gulir ke kartu tujuan.
    await tester.scrollUntilVisible(
      find.text('Tiba di tujuan ini'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Tujuan saat ini · 1 dari 2'), findsOneWidget);
    expect(find.text('Daftar tujuan'), findsOneWidget);
    expect(
      tester
          .widget<PolylineLayer>(find.byType(PolylineLayer))
          .polylines
          .single
          .points,
      [origin, destination, added],
    );
    // Tambah lagi: peta mulai dari tujuan terakhir yang baru; Back = batal.
    await tap(tester, find.text('Tujuan'));
    expect(
      MapCamera.of(tester.element(find.text('© OpenStreetMap'))).center,
      added,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(stopsOf(first), hasLength(2));
    await tester.scrollUntilVisible(
      find.text('Tiba di tujuan ini'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    await tap(tester, find.text('Tiba di tujuan ini'));
    expect(find.text('Tujuan saat ini · 2 dari 2'), findsOneWidget);
    expect(find.text('Halte Uji'), findsWidgets);
    // Alamat manual tujuan saat ini: di kartu + daftar.
    expect(find.text('Jl. Halte No. 2'), findsNWidgets(2));
    expect(find.text('Tiba di tujuan ini'), findsNothing); // terakhir: End
    expect(stopsOf(first).first.arrivedAt, isNotNull);
    expect(stopsOf(first).last.arrivedAt, isNull);
    final arrived = find.textContaining(RegExp(r'^Tiba \d\d\.\d\d$'));
    expect(arrived, findsOneWidget);

    await tap(tester, find.text('Akhiri trip'));
    await tap(tester, find.byType(CheckboxListTile));
    await tap(tester, find.widgetWithText(FilledButton, 'Akhiri'));
    expect(stopsOf(first).every((s) => s.arrivedAt != null), isTrue);

    // S13 ikut menampilkan daftar tujuan (Navigator baru, tanpa S10).
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app(home: TripSummaryScreen(trip: first)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Daftar tujuan'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.scrollUntilVisible(
      find.text('2. Halte Uji'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Daftar tujuan'), findsOneWidget);
    expect(find.textContaining(RegExp(r'^Tiba \d\d\.\d\d$')), findsNWidgets(2));
    expect(find.text('Jl. Halte No. 2'), findsOneWidget);
  });

  testWidgets('S08: ilustrasi 2D; driver tidak bisa menghapus tujuan', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final geocode = reverseGeocode;
    reverseGeocode = (_) async => 'Halte Uji';
    addTearDown(() => reverseGeocode = geocode);
    activeTrip.value = (trip: first, startedAt: DateTime(2030, 1, 1, 9, 5));
    setTripStatus(first, onTrip);
    await tester.pumpWidget(
      app(home: ActiveTripScreen(active: activeTrip.value!)),
    );
    await tester.pumpAndSettle();
    // Ilustrasi dekoratif, diam saat reduced motion (pumpAndSettle selesai).
    expect(find.byType(MooverRoadIllustration), findsOneWidget);

    // Tambah tanpa alamat; Batal di dialog alamat = tidak ditambahkan.
    await tap(tester, find.text('Tujuan'));
    await tap(tester, find.text('Pilih titik ini'));
    await tap(tester, find.text('Batal'));
    expect(stopsOf(first), hasLength(1));
    await tap(tester, find.text('Tujuan'));
    await tap(tester, find.text('Pilih titik ini'));
    await tap(tester, find.text('Tambahkan'));
    expect(stopsOf(first).map((s) => (s.name, s.address)), [
      (tripDestination(first), first.address),
      ('Halte Uji', null),
    ]);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    // Hapus/ubah tujuan = keputusan pemesan + approval (keputusan pemilik
    // project 2026-10-14): tanpa tombol hapus.
    expect(find.text('Daftar tujuan'), findsOneWidget);
    expect(find.byTooltip(RegExp('^Hapus tujuan')), findsNothing);
    expect(find.byType(IconButton), findsOneWidget); // Kembali saja
    handle.dispose();
  });

  test('S09 daftar tujuan tersimpan di SQLite dan pulih', () async {
    final dir = Directory.systemTemp.createTempSync('moover_trip');
    final path = tripDbPath;
    tripDbPath = '${dir.path}/trip.db';
    addTearDown(() async {
      await tripStore.reset();
      tripDbPath = path;
      dir.deleteSync(recursive: true);
    });
    final stops = <TripStop>[
      (
        name: 'Tujuan Uji',
        address: null,
        point: null,
        arrivedAt: DateTime(2030, 1, 1, 9),
      ),
      (
        name: 'Halte Uji',
        address: 'Jl. Halte No. 2',
        point: const LatLng(-6.2, 106.8),
        arrivedAt: null,
      ),
    ];
    await tripStore.saveStops(first.number, stops);
    // "Tutup app": memori kosong, lalu muat ulang dari file.
    await tripStore.reset();
    expect(stopsOf(first), hasLength(1));
    await tripStore.load();
    expect(stopsOf(first), stops);
  });

  test('kontras banner dan tombol batal', () {
    expect(contrast(MooverColors.surface, MooverColors.navy), greaterThan(4.5));
    expect(contrast(MooverColors.sky, MooverColors.navy), greaterThan(4.5));
    expect(
      contrast(StatusTone.err.foreground, MooverColors.surface),
      greaterThan(4.5),
    );
    expect(
      contrast(StatusTone.indigo.foreground, StatusTone.indigo.background),
      greaterThan(4.5),
    );
    expect(
      contrast(MooverColors.textMuted, MooverColors.blueTint),
      greaterThan(4.5),
    );
  });
}
