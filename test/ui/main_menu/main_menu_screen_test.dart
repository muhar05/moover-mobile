import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moover_driver/ui/core/themes/theme.dart';
import 'package:moover_driver/ui/core/widgets/widgets.dart';
import 'package:moover_driver/ui/landing/landing_screen.dart';
import 'package:moover_driver/ui/login/login_screen.dart';
import 'package:moover_driver/ui/main_menu/main_menu_screen.dart';

import '../core/design_system_test.dart' show contrast;

const tabs = ['Beranda', 'Trip', 'Reimburse', 'Akun'];

Widget app({Widget home = const MainMenuScreen(), double textScale = 1}) =>
    MaterialApp(
      theme: mooverTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: home,
    );

/// Bidang header navy (Beranda, Akun), termasuk tab yang tidak tampil.
Finder navyBox() => find.byWidgetPredicate(
  (w) =>
      w is DecoratedBox &&
      w.decoration is BoxDecoration &&
      (w.decoration as BoxDecoration).color == MooverColors.navy,
  skipOffstage: false,
);

Finder tab(String label) => find.descendant(
  of: find.byType(MooverBottomNavigation),
  matching: find.text(label),
);

int selectedTab(WidgetTester tester) => tester
    .widget<MooverBottomNavigation>(find.byType(MooverBottomNavigation))
    .selectedIndex;

void main() {
  testWidgets('tepat empat tab dengan label yang ditentukan; awal Beranda', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    final bar = tester.widget<MooverBottomNavigation>(
      find.byType(MooverBottomNavigation),
    );
    expect(bar.items, hasLength(4));
    expect([for (final d in bar.items) d.label], tabs);
    expect(bar.selectedIndex, 0);
    // Empat target sentuh di bar, tidak lebih.
    expect(
      find.descendant(
        of: find.byType(MooverBottomNavigation),
        matching: find.byType(InkWell),
      ),
      findsNWidgets(4),
    );
  });

  testWidgets('keempat tab bisa dibuka dan menampilkan isinya', (tester) async {
    await tester.pumpWidget(app());
    final content = {
      'Beranda': 'Jadwal hari ini',
      'Trip': 'Riwayat',
      'Reimburse': 'Rp 300.000',
      'Akun': 'Employee ID: $demoEmployeeId',
    };
    for (final (i, label) in tabs.indexed) {
      await tester.tap(tab(label));
      await tester.pumpAndSettle();
      expect(selectedTab(tester), i);
      expect(find.text(content[label]!), findsOneWidget, reason: label);
      // Banner MOCK/DEMO dihapus (keputusan 2026-10-10): tidak ada bidang
      // kuning tone warn atau ikon ⓘ, termasuk di tab yang tidak tampil.
      expect(
        find.byWidgetPredicate(
          (w) =>
              (w is Container && w.color == StatusTone.warn.background) ||
              (w is DecoratedBox &&
                  w.decoration is BoxDecoration &&
                  (w.decoration as BoxDecoration).color ==
                      StatusTone.warn.background),
          skipOffstage: false,
        ),
        findsNothing,
        reason: label,
      );
      expect(
        find.byIcon(Icons.info_outline, skipOffstage: false),
        findsNothing,
        reason: label,
      );
      expect(
        find.textContaining('Data contoh', skipOffstage: false),
        findsNothing,
      );
    }
  });

  testWidgets('state tab dipertahankan saat berpindah tab', (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(tab('Trip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle();
    expect(find.text('Selesai'), findsOneWidget);

    await tester.tap(tab('Beranda'));
    await tester.pumpAndSettle();
    await tester.tap(tab('Trip'));
    await tester.pumpAndSettle();
    expect(find.text('Selesai'), findsOneWidget, reason: 'segmen di-reset');
  });

  testWidgets('Landing → Login → Main Menu; Back tidak kembali ke Login', (
    tester,
  ) async {
    await tester.pumpWidget(app(home: const LandingScreen()));
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, demoEmployeeId);
    await tester.enterText(find.byType(TextFormField).last, demoPassword);
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    expect(find.byType(MainMenuScreen), findsOneWidget);

    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    expect(nav.canPop(), isFalse, reason: 'Login/Landing masih di stack');
    // Back sistem: tidak ada route di bawahnya, app ditutup oleh OS.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(LandingScreen), findsNothing);
    expect(find.byType(MainMenuScreen), findsOneWidget);
  });

  testWidgets('logout dengan konfirmasi kembali ke Login tanpa Back', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.tap(tab('Akun'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(find.byType(MainMenuScreen), findsOneWidget);

    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keluar').last); // tombol di dialog
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(MainMenuScreen), findsNothing);
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
      isFalse,
    );
  });

  testWidgets('item trip: data, kartu sendiri, riwayat per tanggal', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    final home = tester
        .widgetList<MooverTripItem>(find.byType(MooverTripItem))
        .map(
          (t) =>
              (t.time, t.origin, t.destination, t.passengers, t.status, t.tone),
        )
        .toList();
    expect(home, [
      (
        '09.30 WIB',
        'Kantor Pusat',
        'Kantor Cabang (contoh)',
        '2 penumpang',
        'Terjadwal',
        StatusTone.neutral,
      ),
      (
        '13.00 WIB',
        'Kantor Cabang',
        'Kantor Pusat (contoh)',
        '1 penumpang',
        'Terjadwal',
        StatusTone.neutral,
      ),
    ]);
    // V2.1: tiap item adalah kartu sendiri, tidak dibungkus kartu bagian.
    expect(
      find.ancestor(
        of: find.byType(MooverTripItem),
        matching: find.byType(Card),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(MooverTripItem),
        matching: find.byType(Card),
      ),
      findsNWidgets(2),
    );
    // Hanya trip pertama hari ini ditandai "Berikutnya".
    expect(
      tester
          .widgetList<MooverTripItem>(find.byType(MooverTripItem))
          .map((t) => t.next),
      [true, false],
    );

    await tester.tap(tab('Trip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle();
    // Item milik header tanggal terdekat di atasnya (urutan vertikal).
    final headers = {
      for (final d in ['8 Okt 2026', '7 Okt 2026'])
        d: tester.getTopLeft(find.text(d)).dy,
    };
    final grouped = <String, List<String>>{};
    for (final e in find.byType(MooverTripItem).evaluate()) {
      final t = e.widget as MooverTripItem;
      final y = tester.getTopLeft(find.byWidget(t)).dy;
      final date =
          (headers.entries.where((h) => h.value < y).toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .first
              .key;
      (grouped[date] ??= []).add(
        '${t.time} ${t.status} ${t.origin}/${t.destination}',
      );
    }
    expect(grouped, {
      '8 Okt 2026': [
        '14.00 WIB Selesai Kantor Pusat/Bandara (contoh)',
        '08.00 WIB Menunggu Feedback Kantor Pusat/Kantor Cabang (contoh)',
      ],
      '7 Okt 2026': [
        '10.00 WIB Dibatalkan Kantor Cabang/Kantor Pusat (contoh)',
      ],
    });
    expect(find.text('2 trip'), findsWidgets);
    expect(find.text('1 trip'), findsOneWidget);
    // Riwayat tidak punya data penumpang: baris tidak ditampilkan.
    expect(find.textContaining('penumpang').hitTestable(), findsNothing);
  });

  testWidgets('rute tampil sebagai timeline, bukan teks dengan "→"', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(app());
    // Termasuk tab yang tidak tampil (IndexedStack) dan segmen Riwayat.
    expect(find.textContaining('→', skipOffstage: false), findsNothing);
    await tester.tap(tab('Trip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle();
    expect(find.textContaining('→', skipOffstage: false), findsNothing);
    await tester.tap(tab('Beranda'));
    await tester.pumpAndSettle();

    // Kartu Agenda: rute trip berikutnya, mode latar gelap.
    final agenda = tester
        .widgetList<MooverRouteTimeline>(find.byType(MooverRouteTimeline))
        .first;
    expect(
      (agenda.origin, agenda.destination, agenda.onDark),
      ('Kantor Pusat', 'Kantor Cabang (contoh)', true),
    );
    // Item trip: mode latar terang.
    expect(
      tester
          .widgetList<MooverRouteTimeline>(
            find.descendant(
              of: find.byType(MooverTripItem),
              matching: find.byType(MooverRouteTimeline),
            ),
          )
          .map((r) => r.onDark),
      everyElement(isFalse),
    );
    // Pembaca layar: asal lalu tujuan, digabung dengan data item lain.
    expect(
      tester.getSemantics(find.byType(MooverTripItem).first),
      isSemantics(
        label:
            '09.30 WIB\nBerikutnya\nTerjadwal\n'
            'Dari Kantor Pusat ke Kantor Cabang (contoh)\n2 penumpang',
      ),
    );
    handle.dispose();
  });

  testWidgets(
    'kartu agenda: data, di header navy, kontras, tanpa aksi clock-in',
    (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app());
      final agenda = find.byType(MooverAgendaCard);
      expect(agenda, findsOneWidget);
      Finder inAgenda(Finder f) => find.descendant(of: agenda, matching: f);

      // Data mock tetap: jumlah, waktu, rute, status, jam operasional.
      for (final t in [
        'Agenda hari ini',
        '9 Okt 2026',
        '2 trip',
        'Berikutnya',
        '09.30 WIB',
        'Belum clock-in hari ini.',
        'Jam operasional 07.30–16.30',
      ]) {
        expect(inAgenda(find.text(t)), findsOneWidget, reason: t);
      }
      final route = tester.widget<MooverRouteTimeline>(
        inAgenda(find.byType(MooverRouteTimeline)),
      );
      expect(
        (route.origin, route.destination, route.onDark),
        ('Kantor Pusat', 'Kantor Cabang (contoh)', true),
      );
      // Urutan V2.1: label + status clock-in → waktu → rute → jam
      // operasional.
      double y(String t) => tester.getTopLeft(inAgenda(find.text(t))).dy;
      final routeY = tester.getTopLeft(
        inAgenda(find.byType(MooverRouteTimeline)),
      );
      expect(y('Agenda hari ini'), lessThan(y('09.30 WIB')));
      expect(y('Belum clock-in hari ini.'), lessThan(y('09.30 WIB')));
      expect(y('09.30 WIB'), lessThan(routeY.dy));
      expect(routeY.dy, lessThan(y('Jam operasional 07.30–16.30')));

      // V2.1: kartu putih 8% di dalam header navy, radius kartu (20).
      final card =
          tester
                  .widget<DecoratedBox>(
                    inAgenda(find.byType(DecoratedBox)).first,
                  )
                  .decoration
              as BoxDecoration;
      expect(card.color, MooverAgendaCard.fill);
      expect(card.borderRadius, BorderRadius.circular(MooverRadius.card));
      // Kartu sepenuhnya di dalam bidang navy (lapisan Stack di bawahnya).
      final agendaRect = tester.getRect(agenda);
      expect(tester.getRect(navyBox().first).intersect(agendaRect), agendaRect);

      // Kontras di navy dan di bidang kartu (fill di atas navy): teks ≥4,5,
      // indikator rute ≥3.
      Color textColor(String t) =>
          tester.widget<Text>(inAgenda(find.text(t))).style!.color!;
      final cardBg = Color.alphaBlend(MooverAgendaCard.fill, MooverColors.navy);
      for (final stop in [MooverColors.navy, cardBg]) {
        for (final t in [
          'Agenda hari ini',
          '9 Okt 2026',
          'Belum clock-in hari ini.',
          '2 trip',
          'Berikutnya',
          '09.30 WIB',
          'Jam operasional 07.30–16.30',
          'Kantor Pusat',
          'Kantor Cabang (contoh)',
        ]) {
          expect(
            contrast(textColor(t), stop),
            greaterThanOrEqualTo(4.5),
            reason: '$t / $stop',
          );
        }
        for (final c in [MooverColors.sky]) {
          expect(contrast(c, stop), greaterThanOrEqualTo(3), reason: 'rute');
        }
      }
      // Status clock-in V2.1: pill garis amber, warna garis = warna teks
      // (sudah diuji ≥4,5 di kedua latar di atas).
      final pill = tester.widget<DecoratedBox>(
        find
            .ancestor(
              of: find.text('Belum clock-in hari ini.'),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final pillShape =
          (pill.decoration as ShapeDecoration).shape as StadiumBorder;
      expect(pillShape.side.color, MooverColors.amber);
      expect(textColor('Belum clock-in hari ini.'), MooverColors.amber);

      // Status saja: tidak ada tombol/aksi clock-in atau klaim berhasil.
      expect(
        inAgenda(
          find.byWidgetPredicate(
            (w) =>
                w is InkWell || w is ButtonStyleButton || w is GestureDetector,
          ),
        ),
        findsNothing,
      );
      expect(find.textContaining('berhasil'), findsNothing);

      // Pembaca layar: waktu dan rute trip berikutnya dibaca berurutan.
      expect(
        tester.getSemantics(inAgenda(find.text('Berikutnya'))),
        isSemantics(
          label:
              'Berikutnya\n09.30 WIB\n'
              'Dari Kantor Pusat ke Kantor Cabang (contoh)',
        ),
      );
      handle.dispose();
    },
  );

  testWidgets('header navy Beranda: sudut bawah 32, sapaan, status bar', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(app());
    // Navy hanya di Beranda dan Akun; Trip dan Reimburse judul di Ground.
    expect(navyBox(), findsNWidgets(2));
    final home = navyBox().first;
    expect(
      (tester.widget<DecoratedBox>(home).decoration as BoxDecoration)
          .borderRadius,
      const BorderRadius.vertical(bottom: Radius.circular(32)),
    );
    // Header full-bleed sampai tepi atas layar.
    expect(tester.getTopLeft(home), Offset.zero);
    expect(tester.getSize(home).width, 800);
    final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find
          .ancestor(
            of: home,
            matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
          )
          .first,
    );
    expect(region.value, SystemUiOverlayStyle.light);

    Color color(String t) => tester.widget<Text>(find.text(t)).style!.color!;
    expect(color('Halo,'), MooverColors.sky);
    expect(color(demoDriverName), MooverColors.surface);
    for (final t in ['Halo,', demoDriverName]) {
      expect(contrast(color(t), MooverColors.navy), greaterThanOrEqualTo(4.5));
    }
    expect(
      tester.getSemantics(find.text('Halo,')),
      isSemantics(label: 'Halo,\n$demoDriverName', isHeader: true),
    );
    handle.dispose();
  });

  testWidgets('Akun: header navy, kartu profil menumpang, Keluar tone err', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.tap(tab('Akun'));
    await tester.pumpAndSettle();

    final header = navyBox().last;
    final title = find.text('Akun').first;
    expect(
      find.descendant(of: find.byType(MooverBottomNavigation), matching: title),
      findsNothing,
    );
    final titleColor = tester.widget<Text>(title).style!.color!;
    expect(contrast(titleColor, MooverColors.navy), greaterThanOrEqualTo(4.5));

    // Kartu profil: radius 24, atas di navy, bawah melewati tepi navy.
    final profile = find.ancestor(
      of: find.text('Employee ID: $demoEmployeeId'),
      matching: find.byType(Card),
    );
    expect(
      (tester.widget<Card>(profile).shape as RoundedRectangleBorder)
          .borderRadius,
      const BorderRadius.all(Radius.circular(MooverRadius.lg)),
    );
    final navyBottom = tester.getBottomLeft(header).dy;
    expect(tester.getTopLeft(profile).dy, lessThan(navyBottom));
    expect(tester.getBottomLeft(profile).dy, greaterThan(navyBottom));

    // Tombol Keluar: tint err, label err, tinggi ≥52.
    final logout = find.ancestor(
      of: find.text('Keluar'),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );
    final style = tester.widget<ButtonStyleButton>(logout).style!;
    final bg = style.backgroundColor!.resolve({})!;
    final fg = style.foregroundColor!.resolve({})!;
    expect((bg, fg), (StatusTone.err.background, StatusTone.err.foreground));
    expect(contrast(fg, bg), greaterThanOrEqualTo(4.5));
    expect(tester.getSize(logout).height, greaterThanOrEqualTo(52));
  });

  testWidgets('semantik tab: tombol, label, status terpilih', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(app());
    for (final (i, label) in tabs.indexed) {
      expect(
        tester.getSemantics(tab(label)),
        isSemantics(
          label: label,
          isButton: true,
          hasTapAction: true,
          hasSelectedState: true,
          isSelected: i == 0,
          isInMutuallyExclusiveGroup: true,
        ),
        reason: label,
      );
    }
    await tester.tap(tab('Akun'));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(tab('Akun')),
      isSemantics(label: 'Akun', isSelected: true),
    );
    expect(
      tester.getSemantics(tab('Beranda')),
      isSemantics(label: 'Beranda', isSelected: false),
    );
    handle.dispose();
  });

  testWidgets('tidak overflow di layar 320x568dp, teks 200%, semua tab', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(960, 1704)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app(textScale: 2));
    for (final label in tabs) {
      await tester.tap(tab(label));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(ListView).hitTestable(),
        const Offset(0, -3000),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: label);
    }
  });

  testWidgets('target sentuh ≥48dp dan kontrol berlabel', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(app());
    for (final label in tabs) {
      await tester.tap(tab(label));
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    }
    handle.dispose();
  });
}
