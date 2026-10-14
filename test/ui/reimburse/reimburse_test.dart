import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moover/ui/core/themes/theme.dart';
import 'package:moover/ui/core/widgets/widgets.dart';
import 'package:moover/ui/reimburse/reimburse_detail_screen.dart';
import 'package:moover/ui/reimburse/reimburse_form_screen.dart';
import 'package:moover/ui/reimburse/reimburse_store.dart';

import '../core/design_system_test.dart' show contrast;
import '../trip/trip_flow_test.dart' show app, tap;

/// Main Menu → tab Reimburse (DB seed di memori, flutter_test_config.dart).
Future<void> openTab(WidgetTester tester, {double textScale = 1}) async {
  await tester.pumpWidget(app(textScale: textScale));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Reimburse').last);
  await tester.pumpAndSettle();
}

Finder item(String number) =>
    find.widgetWithText(MooverReimburseItem, number, skipOffstage: false);

void main() {
  setUp(() {
    // Viewport tinggi: seluruh form/daftar terbangun tanpa gulir.
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.single;
    view
      ..physicalSize = const Size(1200, 4000)
      ..devicePixelRatio = 2;
  });
  tearDown(
    () => TestWidgetsFlutterBinding.instance.platformDispatcher.views.single
        .reset(),
  );

  test('format Rupiah D4', () {
    expect(formatRupiah(5), 'Rp 5');
    expect(formatRupiah(45000), 'Rp 45.000');
    expect(formatRupiah(1234567), 'Rp 1.234.567');
  });

  testWidgets('S14: seed SQLite, nomor, urutan terbaru, filter', (
    tester,
  ) async {
    await openTab(tester);
    final numbers = [
      for (final w in tester.widgetList<MooverReimburseItem>(
        find.byType(MooverReimburseItem, skipOffstage: false),
      ))
        w.number,
    ];
    // Beranda (reimburse terakhir) + 4 di tab.
    expect(numbers, [
      'RMB-202610-0004',
      'RMB-202610-0004',
      'RMB-202610-0003',
      'RMB-202610-0002',
      'RMB-202610-0001',
    ]);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Dibayar'));
    await tester.pumpAndSettle();
    expect(find.text('1 item'), findsOneWidget);
    expect(find.text('Rp 20.000'), findsOneWidget);
  });

  testWidgets('S15: validasi per field, simpan → nomor baru di S14', (
    tester,
  ) async {
    await openTab(tester);
    await tap(tester, find.text('Ajukan reimburse'));
    expect(find.byType(ReimburseFormScreen), findsOneWidget);

    // Semua wajib kecuali trip; foto nota juga.
    await tap(tester, find.text('Kirim pengajuan'));
    for (final e in [
      'Pilih kategori.',
      'Isi nominal lebih dari 0.',
      'Isi keterangan.',
      'Ambil foto nota.',
    ]) {
      expect(find.text(e), findsOneWidget, reason: e);
    }
    final err = tester
        .widget<Text>(find.text('Ambil foto nota.'))
        .style!
        .color!;
    expect(contrast(err, MooverColors.surface), greaterThanOrEqualTo(4.5));
    expect(find.byType(ReimburseFormScreen), findsOneWidget);

    await tap(tester, find.text('Kategori'));
    await tap(tester, find.text('BBM').last);
    // Hanya angka (formatter).
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nominal'),
      '1a5000',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Keterangan'),
      'Isi bensin uji',
    );
    await tap(tester, find.text('Simulasi tanpa kamera'));
    expect(find.text('Foto nota contoh'), findsOneWidget);
    await tap(tester, find.text('Kirim pengajuan'));

    // Kembali ke S14; D10: tanpa "berhasil".
    expect(find.byType(ReimburseFormScreen), findsNothing);
    final now = DateTime.now();
    final number =
        'RMB-${now.year}${now.month.toString().padLeft(2, '0')}-'
        '${now.year == 2026 && now.month == 10 ? '0005' : '0001'}';
    expect(
      find.text('$number disimpan di perangkat (belum dikirim ke server).'),
      findsOneWidget,
    );
    expect(find.textContaining('berhasil'), findsNothing);
    expect(item(number), findsWidgets);
    expect(find.text('Rp 15.000'), findsWidgets);

    // Tersimpan di SQLite: muat ulang dari DB.
    await reimburseStore.load();
    final saved = reimburseStore.items!.firstWhere((r) => r.number == number);
    expect(saved.draft.amount, 15000);
    expect(saved.draft.category, ReimburseCategory.fuel);
    expect(saved.status, ReimburseStatus.submitted);
    expect(saved.timeline.single.actor, driverActor);
  });

  testWidgets('S16 Dibayar: rincian, bukti transfer, timeline', (tester) async {
    await openTab(tester);
    await tap(tester, item('RMB-202610-0002').last);
    expect(find.byType(ReimburseDetailScreen), findsOneWidget);
    expect(find.text('Parkir di Kantor Cabang (contoh)'), findsOneWidget);
    expect(find.text('Bukti transfer'), findsOneWidget);
    expect(find.text('Nominal transfer'), findsOneWidget);
    // Timeline terbaru dulu: Dibayar, Disetujui, Diajukan; waktu + pelaku.
    final labels = find.descendant(
      of: find.byType(ListView),
      matching: find.textContaining(RegExp(r'^(Diajukan|Disetujui|Dibayar)$')),
    );
    expect(
      [for (final t in tester.widgetList<Text>(labels)) t.data],
      ['Dibayar', 'Dibayar', 'Disetujui', 'Diajukan'], // badge + timeline
    );
    expect(
      find.text('6 Okt 2026, 11.00 WIB · Finance (contoh)'),
      findsOneWidget,
    );
    expect(find.text('Perbaiki & ajukan ulang'), findsNothing);
  });

  testWidgets('S16 Ditolak → ajukan ulang: catatan tampil, riwayat tetap', (
    tester,
  ) async {
    const note =
        'Foto nota buram, nominal tidak terbaca. Unggah ulang foto nota.';
    await openTab(tester);
    await tap(tester, item('RMB-202610-0001').last);
    // Catatan di atas rincian + di timeline.
    expect(find.text(note), findsNWidgets(2));
    await tap(tester, find.text('Perbaiki & ajukan ulang'));

    // S15 ajukan ulang: catatan di atas form, isian lama terisi.
    expect(find.text('Ajukan ulang'), findsOneWidget);
    expect(find.text(note), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(note)).dy,
      lessThan(tester.getTopLeft(find.text('Tanggal')).dy),
    );
    expect(find.text('75000'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, '75000'),
      '70000',
    );
    await tap(tester, find.text('Kirim ulang'));

    // Kembali ke S16: Diajukan, tanpa tombol ajukan ulang; riwayat tolak tetap.
    expect(find.byType(ReimburseDetailScreen), findsOneWidget);
    expect(find.text('Rp 70.000'), findsOneWidget);
    expect(find.text('Perbaiki & ajukan ulang'), findsNothing);
    expect(find.text(note), findsOneWidget, reason: 'di timeline');
    expect(find.text('Diajukan ulang setelah diperbaiki.'), findsOneWidget);
    expect(
      find.text(
        'Pengajuan ulang disimpan di perangkat (belum dikirim ke '
        'server).',
      ),
      findsOneWidget,
    );
    final r = reimburseStore.items!.firstWhere(
      (r) => r.number == 'RMB-202610-0001',
    );
    expect(
      [for (final e in r.timeline) e.status],
      [
        ReimburseStatus.submitted,
        ReimburseStatus.rejected,
        ReimburseStatus.submitted,
      ],
    );
  });

  testWidgets('S14 kosong: "Belum ada pengajuan" + Ajukan → S15', (
    tester,
  ) async {
    await reimburseStore.load();
    reimburseStore.items = [];
    await tester.pumpWidget(app());
    await tester.tap(find.text('Reimburse').last);
    await tester.pumpAndSettle();
    expect(find.text('Belum ada pengajuan'), findsOneWidget);
    expect(find.text('Reimburse terakhir', skipOffstage: false), findsNothing);
    await tap(tester, find.widgetWithText(OutlinedButton, 'Ajukan'));
    expect(find.byType(ReimburseFormScreen), findsOneWidget);
  });

  testWidgets('320dp, teks 200%: S14, S15, S16 tanpa overflow; target sentuh', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    tester.view
      ..physicalSize = const Size(960, 1704)
      ..devicePixelRatio = 3;
    await openTab(tester, textScale: 2);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await tap(tester, item('RMB-202610-0001').last);
    expect(tester.takeException(), isNull);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await tap(tester, find.text('Perbaiki & ajukan ulang'));
    expect(tester.takeException(), isNull);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    // Kirim di akhir isi yang digulir (S15 form panjang), bukan bar bawah.
    // Gulir bertahap sampai Kirim: overflow tiap baris form ikut tertangkap.
    for (
      var i = 0;
      i < 40 && find.text('Kirim ulang').evaluate().isEmpty;
      i++
    ) {
      // Mulai di padding kiri: field multiline juga Scrollable.
      await tester.dragFrom(const Offset(10, 400), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'gulir $i');
    }
    expect(
      find.descendant(
        of: find.byType(ListView),
        matching: find.text('Kirim ulang'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    handle.dispose();
  });

  test('skema SQLite menolak nilai di luar kontrak', () async {
    await reimburseStore.load(); // buat DB + seed
    final bad = (
      date: DateTime(2026, 10, 9),
      category: ReimburseCategory.toll,
      amount: 0,
      description: 'x',
      tripNumber: null,
      receiptPhoto: null,
    );
    // CHECK (amount > 0).
    await expectLater(reimburseStore.submit(bad), throwsA(anything));
  });
}
