import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moover/ui/core/themes/theme.dart';
import 'package:moover/ui/core/widgets/widgets.dart';
import 'package:moover/ui/main_menu/main_menu_screen.dart';
import 'package:moover/ui/main_menu/mock_data.dart';
import 'package:moover/ui/trip/trip_detail_screen.dart';

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
