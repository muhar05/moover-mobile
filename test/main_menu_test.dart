import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moover_driver/design/theme.dart';
import 'package:moover_driver/design/widgets.dart';
import 'package:moover_driver/screens/landing.dart';
import 'package:moover_driver/screens/login.dart';
import 'package:moover_driver/screens/main_menu.dart';

const tabs = ['Beranda', 'Trip', 'Reimburse', 'Akun'];

Widget app({Widget home = const MainMenuPage(), double textScale = 1}) =>
    MaterialApp(
      theme: mooverTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: home,
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
      // Data mock ditandai (D10).
      expect(find.byType(MockDataBanner), findsOneWidget, reason: label);
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
    await tester.pumpWidget(app(home: const LandingPage()));
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, demoEmployeeId);
    await tester.enterText(find.byType(TextFormField).last, demoPassword);
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    expect(find.byType(MainMenuPage), findsOneWidget);

    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    expect(nav.canPop(), isFalse, reason: 'Login/Landing masih di stack');
    // Back sistem: tidak ada route di bawahnya, app ditutup oleh OS.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsNothing);
    expect(find.byType(LandingPage), findsNothing);
    expect(find.byType(MainMenuPage), findsOneWidget);
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
    expect(find.byType(MainMenuPage), findsOneWidget);

    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keluar').last); // tombol di dialog
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(MainMenuPage), findsNothing);
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
      isFalse,
    );
  });

  testWidgets('item trip: data, tanpa kartu, riwayat per tanggal', (
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
    // Langsung di latar halaman, tidak dibungkus kartu.
    expect(
      find.ancestor(
        of: find.byType(MooverTripItem),
        matching: find.byType(Card),
      ),
      findsNothing,
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
            '09.30 WIB\nTerjadwal\n'
            'Dari Kantor Pusat ke Kantor Cabang (contoh)\n2 penumpang',
      ),
    );
    handle.dispose();
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
