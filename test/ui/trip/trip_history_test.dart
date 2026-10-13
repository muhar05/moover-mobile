import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moover/ui/core/themes/theme.dart';
import 'package:moover/ui/core/widgets/widgets.dart';
import 'package:moover/ui/main_menu/mock_data.dart';
import 'package:moover/ui/trip/trip_detail_screen.dart';

import '../core/design_system_test.dart' show contrast;
import 'trip_flow_test.dart' show app, tap;

Trip byStatus(String status) =>
    tripHistory.firstWhere((t) => t.status == status);

/// Layar tinggi agar ListView membangun semua kartu.
void tall(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(1200, 4000)
    ..devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

List<String> destinationsShown(WidgetTester tester) => [
  for (final item in tester.widgetList<MooverTripItem>(
    find.byType(MooverTripItem),
  ))
    item.destination,
];

void main() {
  setUp(() {
    tripStatus.value = {};
    activeTrip.value = null;
    for (final t in tripsToday) {
      tripResults.remove(t.number);
    }
  });

  test('filterTrips: kata kunci, status, rentang tanggal (inklusif)', () {
    List<String> numbers(List<Trip> ts) => [for (final t in ts) t.number];
    expect(numbers(filterTrips(tripHistory)), [
      for (final t in tripHistory) t.number,
    ]);
    // Asal, tujuan, dan nomor; tanpa beda huruf besar/kecil.
    expect(numbers(filterTrips(tripHistory, query: ' BANDARA ')), [
      'TRP-20261008-0003',
    ]);
    expect(numbers(filterTrips(tripHistory, query: '20261007')), [
      'TRP-20261007-0002',
    ]);
    expect(filterTrips(tripHistory, query: 'tidak ada'), isEmpty);
    expect(numbers(filterTrips(tripHistory, status: 'Dibatalkan')), [
      'TRP-20261007-0002',
    ]);
    final oct8 = DateTimeRange(
      start: DateTime(2026, 10, 8),
      end: DateTime(2026, 10, 8),
    );
    expect(numbers(filterTrips(tripHistory, range: oct8)), [
      'TRP-20261008-0003',
      'TRP-20261008-0001',
    ]);
    expect(
      numbers(filterTrips(tripHistory, status: 'Selesai', query: 'cabang')),
      isEmpty,
    );
    // Batas akhir ikut dihitung: trip setelahnya tidak masuk.
    final oct7 = DateTimeRange(
      start: DateTime(2026, 10, 7),
      end: DateTime(2026, 10, 7),
    );
    expect(numbers(filterTrips(tripHistory, range: oct7)), [
      'TRP-20261007-0002',
    ]);
    expect(tripDay(tripHistory.last), DateTime(2026, 10, 7));
  });

  testWidgets('S12: cari, chip status + jumlah, empty → Reset filter', (
    tester,
  ) async {
    tall(tester);
    await tester.pumpWidget(app(home: const TripHistoryScreen()));
    expect(find.byType(MooverTripItem), findsNWidgets(3));
    expect(find.text('Semua 3'), findsOneWidget);
    expect(find.text('Selesai 1'), findsOneWidget);
    expect(find.text('Menunggu Feedback 1'), findsOneWidget);
    expect(find.text('Dibatalkan 1'), findsOneWidget);
    expect(find.text('Semua tanggal'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'kantor cabang');
    await tester.pumpAndSettle();
    expect(destinationsShown(tester), [
      'Kantor Cabang (contoh)',
      'Kantor Pusat (contoh)',
    ]);
    // Jumlah di chip mengikuti kata kunci (V2.1).
    expect(find.text('Semua 2'), findsOneWidget);
    expect(find.text('Selesai 0'), findsOneWidget);

    await tap(tester, find.text('Selesai 0'));
    expect(find.byType(MooverTripItem), findsNothing);
    expect(
      find.text('Tidak ada trip yang cocok dengan filter.'),
      findsOneWidget,
    );
    await tap(tester, find.text('Reset filter'));
    expect(find.byType(MooverTripItem), findsNWidgets(3));
    expect(find.text('Semua 3'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );

    // Tombol hapus pencarian hanya saat ada isian.
    expect(find.byTooltip('Hapus pencarian'), findsNothing);
    await tester.enterText(find.byType(TextField), 'bandara');
    await tester.pumpAndSettle();
    expect(find.byType(MooverTripItem), findsOneWidget);
    await tap(tester, find.byTooltip('Hapus pencarian'));
    expect(find.byType(MooverTripItem), findsNWidgets(3));
  });

  testWidgets('S12: filter rentang tanggal lewat date range picker', (
    tester,
  ) async {
    tall(tester);
    await tester.pumpWidget(app(home: const TripHistoryScreen()));
    await tap(tester, find.text('Semua tanggal'));
    expect(find.text('Pilih rentang tanggal'), findsOneWidget);
    await tap(tester, find.text('8').last);
    await tap(tester, find.text('8').last);
    await tap(tester, find.text('Terapkan'));
    expect(find.text('8 Okt 2026 – 8 Okt 2026'), findsOneWidget);
    expect(find.byType(MooverTripItem), findsNWidgets(2));
    expect(find.text('7 Okt 2026'), findsNothing);

    await tap(tester, find.byTooltip('Hapus filter tanggal'));
    expect(find.text('Semua tanggal'), findsOneWidget);
    expect(find.byType(MooverTripItem), findsNWidgets(3));
  });

  testWidgets('S13 per status: rating + komentar, menunggu, alasan batal', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      app(home: TripSummaryScreen(trip: byStatus('Selesai'))),
    );
    expect(find.text('TRP-20261008-0003'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);
    // Bintang dekoratif; nilai dibaca dari teks.
    expect(
      tester.getSemantics(find.text('Feedback penumpang')),
      isSemantics(
        label:
            'Feedback penumpang\n4 dari 5\n'
            '“Perjalanan nyaman dan tepat waktu. (contoh)”',
      ),
    );
    final stars = tester.widgetList<Icon>(
      find.descendant(
        of: find.byType(ExcludeSemantics),
        matching: find.byType(Icon),
      ),
    );
    expect(
      [for (final s in stars) s.color],
      [...List.filled(4, MooverColors.amber), MooverColors.blue500],
    );
    expect(
      tester.getSemantics(find.text('Tiba')),
      isSemantics(label: 'Tiba\n14.50 WIB'),
    );
    expect(find.byType(MooverRouteTimeline), findsOneWidget);
    // Tampilkan QR Perlu konfirmasi (Q-B5): belum ada aksi.
    expect(find.byType(ButtonStyleButton), findsNothing);

    await tester.pumpWidget(
      app(home: TripSummaryScreen(trip: byStatus('Menunggu Feedback'))),
    );
    expect(find.text('Feedback penumpang'), findsNothing);
    expect(
      find.text('Penumpang belum mengisi feedback trip ini.'),
      findsOneWidget,
    );
    expect(find.text('Tiba'), findsOneWidget);
    expect(find.textContaining('Tampilkan QR'), findsNothing);

    await tester.pumpWidget(
      app(home: TripSummaryScreen(trip: byStatus('Dibatalkan'))),
    );
    expect(find.text('Alasan pembatalan'), findsOneWidget);
    expect(find.text('Jadwal berubah'), findsOneWidget);
    expect(find.text('Tiba'), findsNothing);
    expect(find.text('Mulai'), findsNothing);
    handle.dispose();
  });

  testWidgets('tab Trip: Riwayat → S13, Cari & filter → S12', (tester) async {
    tall(tester);
    await tester.pumpWidget(app());
    await tester.tap(find.text('Trip').last);
    await tester.pumpAndSettle();
    await tap(tester, find.byType(MooverTripItem).first);
    expect(find.byType(TripSummaryScreen), findsOneWidget);
    expect(find.text('TRP-20261008-0003'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tap(tester, find.text('Cari & filter'));
    expect(find.byType(TripHistoryScreen), findsOneWidget);
  });

  testWidgets(
    'simulasi: trip hari ini yang diakhiri/dibatalkan masuk riwayat',
    (tester) async {
      tall(tester);
      final (ended, canceledTrip) = (tripsToday[0], tripsToday[1]);
      // Alur End/Cancel dari S08/S07 (lihat trip_flow_test).
      setTripStatus(ended, waitingFeedback, (
        start: '09.05 WIB',
        arrival: '09.40 WIB',
        rating: null,
        comment: null,
        reason: null,
      ));
      setTripStatus(canceledTrip, canceled, (
        start: null,
        arrival: null,
        rating: null,
        comment: null,
        reason: 'Kendaraan bermasalah',
      ));
      await tester.pumpWidget(app(home: const TripHistoryScreen()));
      expect(find.text('9 Okt 2026'), findsOneWidget);
      expect(find.text('Semua 5'), findsOneWidget);
      // Riwayat = rute asal → tujuan, tanpa alamat.
      final first = tester.widget<MooverTripItem>(
        find.byType(MooverTripItem).first,
      );
      expect(
        (first.origin, first.address, first.status),
        ('Kantor Cabang', null, 'Dibatalkan'),
      );

      await tap(tester, find.byType(MooverTripItem).first);
      expect(find.text('Kendaraan bermasalah'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tap(tester, find.byType(MooverTripItem).at(1));
      expect(find.text('09.05 WIB'), findsOneWidget);
      expect(find.text('09.40 WIB'), findsOneWidget);
      expect(find.text('2 penumpang'), findsOneWidget);

      // Trip Terjadwal tidak masuk riwayat; yang selesai dibuka ke S13
      // juga dari Beranda.
      await tester.pageBack();
      await tester.pumpAndSettle();
      tripStatus.value = {ended.number: waitingFeedback};
      await tester.pumpWidget(app());
      await tap(tester, find.byType(MooverTripItem).first);
      expect(find.byType(TripSummaryScreen), findsOneWidget);
      expect(
        pastTrips().map((t) => t.number),
        isNot(contains(canceledTrip.number)),
      );
    },
  );

  testWidgets('320dp + teks 200%: S12, S12 kosong, S13 tanpa overflow', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(960, 1704)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    for (final screen in <Widget>[
      const TripHistoryScreen(),
      for (final t in tripHistory) TripSummaryScreen(trip: t),
    ]) {
      await tester.pumpWidget(app(home: screen, textScale: 2));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$screen');
    }
    await tester.pumpWidget(app(home: const TripHistoryScreen(), textScale: 2));
    await tester.enterText(find.byType(TextField), 'tidak ada');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Reset filter'),
      200,
      scrollable: find.byType(Scrollable).first, // ListView, bukan TextField
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('target sentuh dan label: S12, S13', (tester) async {
    tall(tester);
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(app(home: const TripHistoryScreen()));
    await tester.enterText(find.byType(TextField), 'kantor');
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await tester.pumpWidget(
      app(home: TripSummaryScreen(trip: byStatus('Selesai'))),
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  test('kontras S13: kartu feedback navy, catatan tone', () {
    expect(contrast(MooverColors.surface, MooverColors.navy), greaterThan(4.5));
    expect(contrast(MooverColors.sky, MooverColors.navy), greaterThan(4.5));
    // Bintang: elemen non-teks ≥3:1 (D9).
    expect(contrast(MooverColors.amber, MooverColors.navy), greaterThan(3));
    expect(contrast(MooverColors.blue500, MooverColors.navy), greaterThan(3));
    for (final tone in [StatusTone.warn, StatusTone.err]) {
      expect(contrast(tone.foreground, tone.background), greaterThan(4.5));
    }
  });
}
