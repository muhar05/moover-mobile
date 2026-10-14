import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:moover/ui/core/widgets/widgets.dart';
import 'package:moover/ui/main_menu/mock_data.dart';
import 'package:moover/ui/trip/new_trip_screen.dart';
import 'package:moover/ui/trip/trip_detail_screen.dart';
import 'package:moover/ui/trip/trip_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'trip_flow_test.dart' show app, tap;

/// Nomor trip pertama yang dibuat hari ini.
String firstNumberToday() {
  final n = DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  return 'TRP-${n.year}${two(n.month)}${two(n.day)}-0001';
}

/// Beranda (sudah clock-in) → tab Trip → Tambah trip baru → S11.
Future<void> openForm(WidgetTester tester, {double textScale = 1}) async {
  await tester.pumpWidget(app(textScale: textScale));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Trip').last);
  await tester.pumpAndSettle();
  await tap(tester, find.text('Tambah trip baru'));
  expect(find.byType(NewTripScreen), findsOneWidget);
}

/// Scrollable form S11 (Main Menu di bawahnya punya Scrollable sendiri).
Finder formScroll() => find
    .descendant(
      of: find.byType(NewTripScreen),
      matching: find.byType(Scrollable),
    )
    .first;

/// Gulir form sampai [f] terlihat (ListView lazy), ke atas atau ke bawah.
Future<void> reveal(WidgetTester tester, Finder f) async {
  for (final delta in [-200.0, 200.0]) {
    if (f.evaluate().isNotEmpty) break;
    try {
      await tester.scrollUntilVisible(
        f,
        delta,
        scrollable: formScroll(),
        maxScrolls: 10,
      );
    } on StateError {
      // tidak di arah ini
    }
  }
}

Future<void> fill(WidgetTester tester, Map<String, String> values) async {
  for (final MapEntry(:key, :value) in values.entries) {
    final field = find.widgetWithText(TextFormField, key);
    await reveal(tester, field);
    await tester.enterText(field, value);
  }
}

/// Gulir form S11 sampai [text] terlihat, lalu ketuk.
Future<void> tapInForm(WidgetTester tester, String text) async {
  await reveal(tester, find.text(text));
  await tap(tester, find.text(text));
}

/// Field lokasi S11 (read-only) berlabel [label].
Finder locationField(String label) => find.widgetWithText(TextFormField, label);

/// Ketuk field lokasi [label], geser peta [by], pilih.
Future<void> pickPoint(WidgetTester tester, String label, Offset by) async {
  await reveal(tester, locationField(label));
  await tap(tester, locationField(label));
  expect(find.byType(LocationPickerScreen), findsOneWidget);
  expect(find.text('© OpenStreetMap'), findsOneWidget);
  await tester.drag(find.byType(FlutterMap), by);
  await tester.pumpAndSettle();
  await tap(tester, find.text('Pilih titik ini'));
  expect(find.byType(LocationPickerScreen), findsNothing);
}

const sample = {'Nama penumpang': 'Penumpang Uji', 'Divisi': 'Divisi Uji'};

/// Geocoding palsu (tanpa jaringan): Kantor Pusat → 'Gedung A', titik lain
/// → 'Gedung → B'; [geocoded] mencatat titik yang ditanyakan.
final geocoded = <LatLng>[];
Future<String?> fakeGeocode(LatLng p) async {
  geocoded.add(p);
  return p == kantorPusat ? 'Gedung A' : 'Gedung → B';
}

void main() {
  setUp(() {
    geocoded.clear();
    reverseGeocode = fakeGeocode;
    searchPlaces = (_) async => const [];
    tripStatus.value = {};
    activeTrip.value = null;
    clockOut.value = null;
    clockIn.value = (at: DateTime(2030, 1, 2, 7, 5), photo: null);
  });
  tearDown(() => clockIn.value = null);

  testWidgets('S11: validasi per field, simpan → Jadwal hari ini, S07', (
    tester,
  ) async {
    await openForm(tester);
    await tapInForm(tester, 'Simpan trip');
    for (final e in [
      'Isi nama penumpang.',
      'Isi divisi penumpang.',
      'Pilih lokasi jemput di peta.',
      'Pilih tujuan di peta.',
    ]) {
      expect(find.text(e), findsOneWidget, reason: e);
    }
    expect(find.byType(NewTripScreen), findsOneWidget);

    // Spasi saja tetap kosong.
    await fill(tester, {...sample, 'Divisi': '   '});
    await tapInForm(tester, 'Simpan trip');
    expect(find.text('Isi divisi penumpang.'), findsOneWidget);
    expect(find.text('Isi nama penumpang.'), findsNothing);

    // Penumpang lengkap tanpa lokasi: tetap ditolak.
    await fill(tester, sample);
    await tapInForm(tester, 'Simpan trip');
    expect(find.text('Pilih lokasi jemput di peta.'), findsOneWidget);
    expect(find.byType(NewTripScreen), findsOneWidget);

    // Nama lokasi tidak bisa diketik: hanya dari peta (koreksi 2026-10-14).
    for (final label in ['Lokasi jemput', 'Tujuan']) {
      await reveal(tester, locationField(label));
      final f = tester.widget<TextField>(
        find.descendant(
          of: locationField(label),
          matching: find.byType(TextField),
        ),
      );
      expect(f.readOnly, isTrue, reason: label);
    }

    await pickPoint(tester, 'Lokasi jemput', Offset.zero);
    // Nama terisi otomatis dari titik; galat lokasi jemput hilang.
    expect(find.text('Gedung A'), findsOneWidget);
    expect(find.text('Pilih lokasi jemput di peta.'), findsNothing);
    expect(find.text('Pilih tujuan di peta.'), findsOneWidget);
    // Tujuan: peta digeser ke kiri-atas → titik ke timur-selatan.
    // Rute jalan palsu: lewat satu belokan.
    const bend = LatLng(-6.19, 106.84);
    fetchRoute = (a, b) async => [a, bend, b];
    expect(find.byType(PolylineLayer), findsNothing); // baru satu titik
    await pickPoint(tester, 'Tujuan', const Offset(-150, -150));
    expect(find.text('Gedung → B'), findsOneWidget);
    expect(find.text('Pilih tujuan di peta.'), findsNothing);
    // Kedua titik dipilih: preview rute mengikuti jalan, bukan garis lurus.
    await reveal(tester, find.byType(PolylineLayer));
    final preview = tester
        .widget<PolylineLayer>(find.byType(PolylineLayer))
        .polylines
        .single
        .points;
    expect(preview, hasLength(3));
    expect(preview[1], bend);
    await tapInForm(tester, 'Simpan trip');
    expect(find.byType(NewTripScreen), findsNothing);
    final number = firstNumberToday();
    // D10: tanpa "berhasil".
    expect(
      find.textContaining('$number disimpan di perangkat'),
      findsOneWidget,
    );
    expect(find.textContaining('berhasil'), findsNothing);
    expect(extraTrips.value.single.number, number);
    // Pemilih mulai di Kantor Pusat (contoh); titik tujuan ikut geseran.
    final (origin, destination) = tripPoints[number]!;
    expect(origin, kantorPusat);
    // Nama yang disimpan berasal dari titik yang sama.
    expect(geocoded, [origin, destination]);
    expect(destination.longitude, greaterThan(kantorPusat.longitude));
    expect(destination.latitude, lessThan(kantorPusat.latitude));

    // Beranda: jadwal hari ini 3 trip, trip baru terakhir, Terjadwal.
    await tester.tap(find.text('Beranda').last);
    await tester.pumpAndSettle();
    expect(find.text('3 trip'), findsWidgets); // agenda + judul bagian
    final items = tester.widgetList<MooverTripItem>(
      find.byType(MooverTripItem),
    );
    final added = items.last;
    // Panah di isian diganti agar rute tetap "Asal → Tujuan".
    expect(
      (added.destination, added.status, added.passengers),
      ('Gedung - B', 'Terjadwal', 'Penumpang Uji (Divisi Uji)'),
    );

    // S07 → Start → S08: alur trip biasa, dengan peta rute jalan.
    await tap(tester, find.byType(MooverTripItem).last);
    expect(find.byType(TripDetailScreen), findsOneWidget);
    expect(
      tester
          .widget<PolylineLayer>(find.byType(PolylineLayer))
          .polylines
          .single
          .points,
      [origin, bend, destination],
    );
    expect(find.text(number), findsOneWidget);
    expect(find.text('Gedung A'), findsOneWidget);
    expect(find.text('Penumpang Uji (Divisi Uji)'), findsOneWidget);
    await tap(tester, find.text('Mulai trip'));
    await tap(tester, find.widgetWithText(FilledButton, 'Mulai'));
    expect(find.byType(ActiveTripScreen), findsOneWidget);
    expect(activeTrip.value?.trip.number, number);
    // Riwayat hanya berisi trip yang sudah diakhiri/dibatalkan.
    expect(pastTrips().map((t) => t.number), isNot(contains(number)));
    setTripStatus(extraTrips.value.single, waitingFeedback);
    expect(pastTrips().first.number, number);
  });

  testWidgets('cari tempat → pilih hasil → konfirmasi: nama + titik hasil', (
    tester,
  ) async {
    const plaza = (point: LatLng(-6.2, 106.82), name: 'Plaza Uji, Jl. Uji');
    final queries = <String>[];
    searchPlaces = (q) async {
      queries.add(q);
      return q == 'kosong' ? const [] : [plaza];
    };
    await openForm(tester);
    await reveal(tester, locationField('Lokasi jemput'));
    await tap(tester, locationField('Lokasi jemput'));

    final search = find.descendant(
      of: find.byType(LocationPickerScreen),
      matching: find.byType(TextField),
    );
    await tester.enterText(search, 'kosong');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.textContaining('Tempat tidak ditemukan'), findsOneWidget);

    await tester.enterText(search, '  plaza  ');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(queries.last, 'plaza');
    await tap(tester, find.widgetWithText(ListTile, plaza.name));
    // Hasil dipilih: daftar tertutup, nama tampil, peta pindah ke titiknya.
    expect(find.byType(ListTile), findsNothing);
    expect(find.text(plaza.name), findsOneWidget);
    // Peta pindah ke titik hasil (pin di tengah).
    expect(
      MapCamera.of(tester.element(find.text('© OpenStreetMap'))).center,
      plaza.point,
    );
    await tap(tester, find.text('Pilih titik ini'));
    // Nama hasil pencarian dipakai apa adanya, tanpa geocoding ulang.
    expect(geocoded, isEmpty);
    expect(find.text(plaza.name), findsOneWidget);

    // Pilih lagi, lalu geser peta: titik baru → nama dari peta.
    await tap(tester, locationField('Lokasi jemput'));
    await tester.enterText(search, 'plaza');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tap(tester, find.widgetWithText(ListTile, plaza.name));
    await tester.drag(find.byType(FlutterMap), const Offset(-100, 0));
    await tester.pumpAndSettle();
    await tap(tester, find.text('Pilih titik ini'));
    expect(geocoded.single.longitude, greaterThan(plaza.point.longitude));
    expect(find.text('Gedung → B'), findsOneWidget);
  });

  testWidgets('pencarian gagal (offline): pesan, tutup → peta lagi', (
    tester,
  ) async {
    searchPlaces = (_) async => throw const SocketException('offline');
    await openForm(tester);
    await reveal(tester, locationField('Tujuan'));
    await tap(tester, locationField('Tujuan'));
    await tester.enterText(
      find.descendant(
        of: find.byType(LocationPickerScreen),
        matching: find.byType(TextField),
      ),
      'plaza',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(
      find.text('Pencarian gagal. Periksa koneksi internet.'),
      findsOneWidget,
    );
    expect(find.text('Pilih titik ini'), findsNothing);
    await tap(tester, find.byTooltip('Tutup pencarian'));
    expect(find.text('Pilih titik ini'), findsOneWidget);
  });

  test('respons Nominatim /search: lat/lon teks → titik; rusak dilewati', () {
    expect(
      placesFromNominatim([
        {
          'lat': '-6.2',
          'lon': '106.8',
          'display_name': 'Plaza, Jl. A, Kel. B, Kota C, Indonesia',
        },
        {'lat': 'x', 'lon': '106.8', 'display_name': 'rusak'},
        {'lat': '-6.2'},
      ]),
      [(point: const LatLng(-6.2, 106.8), name: 'Plaza, Jl. A, Kel. B')],
    );
    expect(placesFromNominatim({'error': 'x'}), isEmpty);
  });

  testWidgets('tersimpan di SQLite: trip dan status pulih setelah app dibuka '
      'ulang', (tester) async {
    final dir = Directory.systemTemp.createTempSync('moover_trip');
    final path = tripDbPath;
    tripDbPath = '${dir.path}/trip.db';
    addTearDown(() {
      tripDbPath = path;
      dir.deleteSync(recursive: true);
    });

    late Trip trip;
    await tester.runAsync(() async {
      trip = await tripStore.add((
        passengerName: 'Penumpang Uji',
        passengerDivision: 'Divisi Uji',
        origin: 'Gedung A',
        destination: 'Gedung B',
        originPoint: const LatLng(-6.2, 106.8),
        destinationPoint: const LatLng(-6.3, 106.9),
      ));
      final startedAt = DateTime(2030, 1, 2, 9, 5);
      activeTrip.value = (trip: trip, startedAt: startedAt);
      setTripStatus(trip, onTrip);
      setTripStatus(tripsToday[1], canceled, (
        start: null,
        arrival: null,
        rating: null,
        comment: null,
        reason: 'Jadwal berubah',
      ));
      await tripStore.load();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // "Tutup app": memori kosong, DB file tetap.
      await tripStore.reset();
      expect(tripPoints[trip.number], isNull);
      tripStatus.value = {};
      activeTrip.value = null;
      tripResults.remove(tripsToday[1].number);
      await tripStore.load();
    });

    expect(extraTrips.value.map((t) => t.number), [trip.number]);
    expect(tripPoints[trip.number], (
      const LatLng(-6.2, 106.8),
      const LatLng(-6.3, 106.9),
    ));
    expect(statusOf(trip), onTrip);
    expect(activeTrip.value?.trip.number, trip.number);
    expect(activeTrip.value?.startedAt, DateTime(2030, 1, 2, 9, 5));
    expect(statusOf(tripsToday[1]), canceled);
    expect(tripResults[tripsToday[1].number]?.reason, 'Jadwal berubah');
    await tester.runAsync(tripStore.reset);
  });

  testWidgets('nama tempat tidak ditemukan / offline: koordinat jadi nama', (
    tester,
  ) async {
    await openForm(tester);
    reverseGeocode = (_) async => null;
    await pickPoint(tester, 'Lokasi jemput', Offset.zero);
    expect(find.text('Titik -6.18650, 106.83400'), findsOneWidget);
    reverseGeocode = (_) async => throw const SocketException('offline');
    await pickPoint(tester, 'Tujuan', Offset.zero);
    expect(find.textContaining('Titik '), findsNWidgets(2));
    expect(find.text('Pilih tujuan di peta.'), findsNothing);
  });

  test('respons OSRM: geometri [lng, lat] → titik; galat → null', () {
    expect(
      routeFromOsrm({
        'code': 'Ok',
        'routes': [
          {
            'geometry': {
              'coordinates': [
                [106.8, -6.2],
                [106.9, -6.3],
              ],
            },
          },
          {'geometry': <String, Object?>{}},
        ],
      }),
      [const LatLng(-6.2, 106.8), const LatLng(-6.3, 106.9)],
    );
    expect(routeFromOsrm({'code': 'NoRoute', 'routes': <Object?>[]}), isNull);
    expect(routeFromOsrm(null), isNull);
  });

  test('skema SQLite menolak isian kosong', () async {
    await tripStore.load(); // buat DB
    await expectLater(
      tripStore.add((
        passengerName: ' ',
        passengerDivision: 'x',
        origin: 'x',
        destination: 'x',
        originPoint: kantorPusat,
        destinationPoint: kantorCabang,
      )),
      throwsA(isA<DatabaseException>()),
    );
  });

  test(
    'DB v1 di HP demo (tanpa titik peta) dimigrasi: trip lama tetap',
    () async {
      final dir = Directory.systemTemp.createTempSync('moover_trip');
      final path = tripDbPath;
      tripDbPath = '${dir.path}/trip.db';
      addTearDown(() {
        tripDbPath = path;
        dir.deleteSync(recursive: true);
      });
      final v1 = await openDatabase(
        tripDbPath,
        version: 1,
        singleInstance: false,
        onCreate: (db, _) async {
          for (final sql in tripSchema) {
            await db.execute(sql);
          }
        },
      );
      await v1.insert('trip', {
        'number': 'TRP-20261014-0001',
        'trip_date': '2026-10-14',
        'pickup_time': '09:05',
        'origin': 'Gedung A',
        'destination': 'Gedung B',
        'passenger_name': 'Penumpang Uji',
        'passenger_division': 'Divisi Uji',
        'created_at': '2026-10-14T09:05:00',
      });
      await v1.close();

      await tripStore.load();
      expect(extraTrips.value.single.number, 'TRP-20261014-0001');
      expect(tripPoints['TRP-20261014-0001'], isNull); // tanpa peta
      final trip = await tripStore.add((
        passengerName: 'Penumpang Uji',
        passengerDivision: 'Divisi Uji',
        origin: 'Gedung A',
        destination: 'Gedung B',
        originPoint: kantorPusat,
        destinationPoint: kantorCabang,
      ));
      expect(tripPoints[trip.number], (kantorPusat, kantorCabang));
      await tripStore.reset();
    },
  );

  testWidgets('320dp, teks 200%: S11 tanpa overflow; target sentuh, label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    tester.view
      ..physicalSize = const Size(960, 1704)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await openForm(tester, textScale: 2);
    expect(tester.takeException(), isNull);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await tapInForm(tester, 'Simpan trip');
    expect(tester.takeException(), isNull, reason: 'dengan pesan galat');
    await reveal(tester, find.text('Penumpang'));
    expect(find.bySemanticsLabel(RegExp('^Nama penumpang')), findsOneWidget);
    expect(find.bySemanticsLabel('Penumpang'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Penumpang')),
      isSemantics(label: 'Penumpang', isHeader: true),
    );
    // Pemilih lokasi di 320dp, teks 200%.
    await reveal(tester, locationField('Tujuan'));
    await tap(tester, locationField('Tujuan'));
    expect(find.byType(LocationPickerScreen), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'pemilih lokasi');
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
