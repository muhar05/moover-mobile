import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moover/ui/attendance/attendance_screen.dart';
import 'package:moover/ui/core/themes/theme.dart';
import 'package:moover/ui/core/widgets/widgets.dart';
import 'package:moover/ui/landing/landing_screen.dart';
import 'package:moover/ui/login/login_screen.dart';
import 'package:moover/ui/main_menu/main_menu_screen.dart';
import 'package:moover/ui/time_log/time_log_screen.dart';
import 'package:moover/ui/main_menu/mock_data.dart'
    show clockIn, clockOut, demoDriverEmail, vehicle;

import '../core/design_system_test.dart' show contrast;

const tabs = ['Beranda', 'Trip', 'Reimburse', 'Akun'];

/// [reduceMotion] default true: animasi kartu trip tambahan berulang tanpa
/// henti, sehingga pumpAndSettle tidak pernah selesai saat tab Trip tampil.
Widget app({
  Widget home = const MainMenuScreen(),
  double textScale = 1,
  bool reduceMotion = true,
}) => MaterialApp(
  theme: mooverTheme(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(textScale),
      disableAnimations: reduceMotion,
    ),
    child: child!,
  ),
  home: home,
);

/// Bidang header navy (Beranda, Akun), termasuk tab yang tidak tampil.
/// Kartu navy di isi tab (trip tambahan, Ajukan reimburse) bukan header:
/// header selalu di bawah AnnotatedRegion status bar.
Finder navyBox() => find.byElementPredicate(
  (e) =>
      e.widget is DecoratedBox &&
      (e.widget as DecoratedBox).decoration is BoxDecoration &&
      ((e.widget as DecoratedBox).decoration as BoxDecoration).color ==
          MooverColors.navy &&
      e
              .findAncestorWidgetOfExactType<
                AnnotatedRegion<SystemUiOverlayStyle>
              >() !=
          null,
  skipOffstage: false,
);

/// Buka tab Trip dan gulir sampai Riwayat (bagian terakhir) terbangun.
Future<void> openHistory(WidgetTester tester) async {
  await tester.tap(tab('Trip'));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text('7 Okt 2026'),
    300,
    scrollable: find.byType(Scrollable).hitTestable().first,
  );
  await tester.pumpAndSettle();
}

/// Tombol Keluar di bawah grup menu Akun: gulir dulu, lalu ketuk.
Future<void> tapLogout(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Keluar').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Keluar').first);
  await tester.pumpAndSettle();
}

Finder tab(String label) => find.descendant(
  of: find.byType(MooverBottomNavigation),
  matching: find.text(label),
);

int selectedTab(WidgetTester tester) => tester
    .widget<MooverBottomNavigation>(find.byType(MooverBottomNavigation))
    .selectedIndex;

void main() {
  // Status clock-in simulasi global (ValueNotifier): reset tiap tes.
  setUp(() => clockIn.value = clockOut.value = null);

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
      'Akun': demoDriverEmail,
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
    // Segmen Hari ini/Riwayat dihapus (keputusan 2026-10-10): yang
    // dipertahankan adalah posisi gulir tab.
    await openHistory(tester);
    expect(find.text('Selesai'), findsOneWidget);
    double offset() => tester
        .state<ScrollableState>(find.byType(Scrollable).hitTestable().first)
        .position
        .pixels;
    final before = offset();
    expect(before, greaterThan(0));

    await tester.tap(tab('Beranda'));
    await tester.pumpAndSettle();
    await tester.tap(tab('Trip'));
    await tester.pumpAndSettle();
    expect(offset(), before, reason: 'posisi gulir di-reset');
    expect(find.text('Selesai'), findsOneWidget);
  });

  testWidgets('Landing → Login → Main Menu; Back tidak kembali ke Login', (
    tester,
  ) async {
    await tester.pumpWidget(app(home: const LandingScreen()));
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, demoEmployeeId);
    await tester.enterText(find.byType(TextFormField).last, demoPassword);
    await tester.tap(find.text('Login'));
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

    await tapLogout(tester);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(find.byType(MainMenuScreen), findsOneWidget);

    await tapLogout(tester);
    await tester.tap(find.text('Keluar').last); // tombol di sheet
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
          (t) => (
            t.time,
            t.origin,
            t.destination,
            t.address,
            t.passengers,
            t.status,
            t.tone,
          ),
        )
        .toList();
    // V2.1 Home (keputusan 2026-10-10): tujuan + alamat, tanpa asal.
    expect(home, [
      (
        '09.30 WIB',
        null,
        'Kantor Cabang (contoh)',
        'Jl. Contoh Raya No. 10, Jakarta Selatan (contoh)',
        '2 penumpang',
        'Terjadwal',
        StatusTone.neutral,
      ),
      (
        '13.00 WIB',
        null,
        'Kantor Pusat (contoh)',
        'Jl. Contoh Utama No. 1, Jakarta Pusat (contoh)',
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

    await openHistory(tester);
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
    await openHistory(tester);
    expect(find.textContaining('→', skipOffstage: false), findsNothing);
    await tester.tap(tab('Beranda'));
    await tester.pumpAndSettle();

    // V2.1 (keputusan 2026-10-10): Beranda tanpa timeline (agenda tanpa
    // rute; jadwal = tujuan + alamat). Timeline hanya di Riwayat.
    expect(find.byType(MooverRouteTimeline), findsNothing);
    // Pembaca layar: tujuan lalu alamat, digabung dengan data item lain.
    expect(
      tester.getSemantics(find.byType(MooverTripItem).first),
      isSemantics(
        label:
            '09.30 WIB\nBerikutnya\nTerjadwal\n'
            'Ke Kantor Cabang (contoh)\n'
            'Jl. Contoh Raya No. 10, Jakarta Selatan (contoh)\n2 penumpang',
      ),
    );
    await openHistory(tester);
    expect(find.byType(MooverRouteTimeline), findsNWidgets(3));
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
            '14.00 WIB\nSelesai\n'
            'Dari Kantor Pusat ke Bandara (contoh)',
      ),
    );
    handle.dispose();
  });

  testWidgets(
    'kartu agenda: data, di header navy, kontras, satu aksi Clock-in',
    (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app());
      final agenda = find.byType(MooverAgendaCard);
      expect(agenda, findsOneWidget);
      Finder inAgenda(Finder f) => find.descendant(of: agenda, matching: f);

      // Jam berjalan HH.MM.SS (V2.1) dan tanggal hari ini.
      final clock = inAgenda(
        find.byWidgetPredicate(
          (w) => w is Text && RegExp(r'^\d\d\.\d\d\.\d\d$').hasMatch(w.data!),
        ),
      );
      expect(clock, findsOneWidget);
      String clockText() => tester.widget<Text>(clock).data!;
      final today = formatDate(DateTime.now());
      for (final t in [
        'Agenda hari ini',
        today,
        '2 trip',
        'Belum clock-in hari ini.',
        'Jam operasional 07.30–16.30',
      ]) {
        expect(inAgenda(find.text(t)), findsOneWidget, reason: t);
      }
      // V2.1: tanpa rute dan tanpa "Berikutnya" di agenda.
      expect(inAgenda(find.byType(MooverRouteTimeline)), findsNothing);
      expect(inAgenda(find.text('Berikutnya')), findsNothing);
      // Urutan V2.1: label + status clock-in → jam → jam operasional.
      double y(String t) => tester.getTopLeft(inAgenda(find.text(t))).dy;
      final clockY = tester.getTopLeft(clock).dy;
      expect(y('Agenda hari ini'), lessThan(clockY));
      expect(y('Belum clock-in hari ini.'), lessThan(clockY));
      expect(clockY, lessThan(y('Jam operasional 07.30–16.30')));

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
          today,
          'Belum clock-in hari ini.',
          '2 trip',
          clockText(),
          'Jam operasional 07.30–16.30',
        ]) {
          expect(
            contrast(textColor(t), stop),
            greaterThanOrEqualTo(4.5),
            reason: '$t / $stop',
          );
        }
        // Isi bar progres (nonteks) ≥3.
        expect(contrast(MooverColors.cyan, stop), greaterThanOrEqualTo(3));
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

      // Satu-satunya aksi: tombol Clock-in V2.1 (simulasi, keputusan
      // pemilik project 2026-10-11), cyan + label navy, ≥52dp. Tanpa klaim
      // berhasil.
      final clockIn = inAgenda(
        find.byWidgetPredicate((w) => w is ButtonStyleButton),
      );
      expect(clockIn, findsOneWidget);
      expect(
        find.descendant(of: clockIn, matching: find.text('Clock-in')),
        findsOneWidget,
      );
      final style = tester.widget<ButtonStyleButton>(clockIn).style!;
      expect(
        (
          style.backgroundColor!.resolve({}),
          style.foregroundColor!.resolve({}),
        ),
        (MooverColors.cyan, MooverColors.navy),
      );
      expect(tester.getSize(clockIn).height, greaterThanOrEqualTo(52));
      expect(find.textContaining('berhasil'), findsNothing);

      // Jam diperbarui tiap detik: Timer (waktu palsu tes) membaca
      // DateTime.now() (waktu nyata), jadi keduanya dimajukan.
      final before = clockText();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 1100)),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(clockText(), isNot(before));
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
    final greet = '${greeting(DateTime.now().hour)},';
    expect(color(greet), MooverColors.sky);
    expect(color(demoDriverName), MooverColors.surface);
    for (final t in [greet, demoDriverName]) {
      expect(contrast(color(t), MooverColors.navy), greaterThanOrEqualTo(4.5));
    }
    expect(
      tester.getSemantics(find.text(greet)),
      isSemantics(label: '$greet\n$demoDriverName', isHeader: true),
    );

    // Watermark tanda Moover 10% (V2.1) di Beranda dan Akun, dipotong
    // bidang navy (Clip) dan tidak dibaca pembaca layar. Tanda ketiga =
    // footer versi Akun (diuji di tes Akun).
    final marks = find.descendant(
      of: navyBox(),
      matching: find.byType(MooverMark, skipOffstage: false),
      skipOffstage: false,
    );
    expect(marks, findsNWidgets(2));
    expect(find.byType(MooverMark, skipOffstage: false), findsNWidgets(3));
    for (final m in tester.widgetList<MooverMark>(marks)) {
      expect(m.opacity, 0.10);
    }
    for (final box in [home, navyBox().last]) {
      final clip = find.ancestor(
        of: find.descendant(
          of: box,
          matching: find.byType(MooverMark, skipOffstage: false),
          skipOffstage: false,
        ),
        matching: find.byType(Container, skipOffstage: false),
      );
      expect(tester.widget<Container>(clip.first).clipBehavior, Clip.antiAlias);
    }
    final markRect = tester.getRect(marks.first);
    expect(markRect.right, greaterThan(800), reason: 'terpotong di kanan');
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
      of: find.text(demoDriverEmail),
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

  testWidgets('Akun V2.1: profil, grup menu, belum tersedia, footer versi', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    tester.view
      ..physicalSize = const Size(800, 4000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());
    await tester.tap(tab('Akun'));
    await tester.pumpAndSettle();

    // Kartu profil: nama, email fiktif (satu baris), chip kendaraan dari mock.
    final chip = 'Driver · ${vehicle.model}';
    final email = tester.widget<Text>(find.text(demoDriverEmail));
    expect((email.maxLines, email.overflow), (1, TextOverflow.ellipsis));
    expect(demoDriverEmail, endsWith('.example'), reason: 'fiktif');
    final chipText = tester.widget<Text>(find.text(chip));
    expect(chipText.style!.color, StatusTone.live.foreground);
    expect(
      contrast(StatusTone.live.foreground, StatusTone.live.background),
      greaterThanOrEqualTo(4.5),
    );
    expect(find.textContaining('Employee ID'), findsNothing);
    expect(
      tester.getSemantics(find.text(demoDriverName).last),
      isSemantics(
        label: '$demoDriverName\n$demoDriverEmail\n$chip',
        isButton: true,
        hasTapAction: true,
      ),
    );

    // Logo reverse di kanan judul, berlabel.
    final logo = find.bySemanticsLabel('Moover');
    expect(logo, findsOneWidget);
    expect(
      tester.getCenter(logo).dx,
      greaterThan(tester.getCenter(find.text('Akun').first).dx),
    );

    // Grup dan urutan menu (gabungan S17 + V2.1, keputusan 2026-10-10).
    const groups = {
      'Akun': ['Informasi profil', 'Ubah kata sandi', 'Kendaraan', 'Time Log'],
      'Bantuan': ['Bantuan & FAQ', 'Hubungi support'],
    };
    double y(Finder f) => tester.getTopLeft(f).dy;
    final order = <Finder>[];
    for (final MapEntry(key: group, value: menus) in groups.entries) {
      final header = find.text(group.toUpperCase());
      expect(
        tester.getSemantics(header),
        isSemantics(label: group, isHeader: true),
      );
      order.add(header);
      for (final m in menus) {
        // Hanya baris menu (judul "Akun" header pakai teks berbeda).
        order.add(find.text(m).last);
      }
    }
    for (var i = 1; i < order.length; i++) {
      expect(y(order[i]), greaterThan(y(order[i - 1])), reason: '$i');
    }
    expect(y(find.text('Keluar')), greaterThan(y(order.last)));
    expect(y(find.text('Moover v0.1.0')), greaterThan(y(find.text('Keluar'))));

    // Ikon tone: Akun info, Bantuan live.
    Color iconColor(String m) => tester
        .widget<Icon>(
          find
              .descendant(
                of: find.ancestor(
                  of: find.text(m).last,
                  matching: find.byType(InkWell),
                ),
                matching: find.byType(Icon),
              )
              .first,
        )
        .color!;
    expect(iconColor('Time Log'), StatusTone.info.foreground);
    expect(iconColor('Hubungi support'), StatusTone.live.foreground);

    // Tiap baris satu tombol berlabel; ketuk = belum tersedia, kecuali
    // Time Log (S05 sudah ada, dites terpisah).
    for (final m in [...groups.values.expand((m) => m)]) {
      final row = find.text(m).last;
      expect(
        tester.getSemantics(row),
        isSemantics(isButton: true, hasTapAction: true),
        reason: m,
      );
      expect(tester.getSemantics(row).label, startsWith(m));
      if (m == 'Time Log') continue;
      await tester.tap(row);
      await tester.pump();
      expect(find.text('$m belum tersedia.'), findsOneWidget, reason: m);
    }
    await tester.tap(find.text(demoDriverEmail));
    await tester.pump();
    expect(find.text('Informasi profil belum tersedia.'), findsOneWidget);
    expect(find.byType(MainMenuScreen), findsOneWidget);

    // Footer: tanda Moover + versi dari pubspec, muted di latar.
    final footer = tester.widget<Text>(find.text('Moover v0.1.0'));
    expect(
      contrast(footer.style!.color!, MooverColors.background),
      greaterThanOrEqualTo(4.5),
    );
    expect(tester.getSize(find.byType(MooverMark).last).height, 14);
    handle.dispose();
  });

  testWidgets('sheet logout V2.1: judul, pesan clock-out, tombol merah', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(app());
    await tester.tap(tab('Akun'));
    await tester.pumpAndSettle();
    await tapLogout(tester);

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(
      tester.getSemantics(find.text('Keluar dari Moover?')),
      isSemantics(label: 'Keluar dari Moover?', isHeader: true),
    );
    final body = tester.widget<Text>(
      find.textContaining('Pastikan Anda sudah clock-out'),
    );
    expect(
      contrast(body.style!.color!, MooverColors.surface),
      greaterThanOrEqualTo(4.5),
    );
    final confirm = find.ancestor(
      of: find.text('Keluar').last,
      matching: find.byType(FilledButton),
    );
    final style = tester.widget<FilledButton>(confirm).style!;
    final bg = style.backgroundColor!.resolve({})!;
    final fg = style.foregroundColor!.resolve({})!;
    expect((bg, fg), (StatusTone.err.foreground, MooverColors.surface));
    expect(contrast(fg, bg), greaterThanOrEqualTo(4.5));
    final cancel = find.widgetWithText(OutlinedButton, 'Batal');
    for (final b in [confirm, cancel]) {
      expect(tester.getSize(b).height, 54);
    }
    expect(
      tester.getTopLeft(cancel).dy,
      tester.getTopLeft(confirm).dy,
      reason: 'berdampingan',
    );
    expect(
      tester.getTopLeft(cancel).dx,
      lessThan(tester.getTopLeft(confirm).dx),
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();

    // 320 dp, teks 200%: sheet tetap utuh.
    tester.view
      ..physicalSize = const Size(960, 1704)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(textScale: 2));
    await tester.tap(tab('Akun'));
    await tester.pumpAndSettle();
    await tapLogout(tester);
    expect(tester.takeException(), isNull);
    // Isi lebih tinggi dari layar: sheet memakai lebih dari batas bawaan
    // 9/16 layar, sisanya digulir.
    expect(
      tester.getSize(find.byType(BottomSheet)).height,
      greaterThan(568 * 9 / 16),
    );
    await tester.ensureVisible(find.text('Batal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('tab Trip V2.1: status clock-in, urutan, kendaraan, tips', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    // Layar tinggi: seluruh isi tab terbangun (ListView lazy) untuk cek urutan.
    tester.view
      ..physicalSize = const Size(800, 4000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());
    await tester.tap(tab('Trip'));
    await tester.pumpAndSettle();

    // Segmen Hari ini/Riwayat dihapus; jadwal hari ini hanya di Beranda.
    expect(find.byType(SegmentedButton<bool>), findsNothing);
    expect(find.text('Hari ini'), findsNothing);

    // Available = sudah clock-in (keputusan 2026-10-10). Mock: belum
    // clock-in, sejalan dengan Beranda. Status teks, bukan toggle.
    expect(clockIn.value, isNull);
    expect(find.text('Belum clock-in hari ini.'), findsNothing);
    expect(find.byType(Switch), findsNothing);
    final badge = tester.widget<StatusBadge>(find.byType(StatusBadge).first);
    expect((badge.label, badge.tone), ('Tidak bertugas', StatusTone.neutral));
    expect(find.text('Status Available aktif setelah clock-in.'), findsOne);
    final card = tester.widget<MooverExtraTripCard>(
      find.byType(MooverExtraTripCard),
    );
    expect(card.available, isFalse);
    expect(find.text('Tambah trip baru'), findsNothing);
    expect(find.text('Clock-in untuk menambah trip'), findsOneWidget);
    // Tile jenis trip informasi saja, tanpa aksi.
    for (final t in [
      'Antar-jemput mendadak',
      'Permintaan trip baru',
      'Perubahan jadwal atau shift',
    ]) {
      expect(
        find.ancestor(of: find.text(t), matching: find.byType(InkWell)),
        findsNothing,
        reason: t,
      );
    }

    // Urutan V2.1, Riwayat terakhir.
    final order = [
      'Trip',
      'Butuh trip tambahan?',
      'Trip tambahan untuk',
      'Kendaraan Anda',
      'Tips berkendara',
      'Riwayat',
    ];
    final ys = [
      for (final t in order)
        tester
            .getTopLeft(
              find.descendant(
                of: find.byType(IndexedStack),
                matching: find.text(t),
              ),
            )
            .dy,
    ];
    expect(ys, [...ys]..sort());
    expect(
      tester.getSemantics(find.text('Trip tambahan untuk')),
      isSemantics(label: 'Trip tambahan untuk', isHeader: true),
    );

    // Kendaraan: data mock, foto PLACEHOLDER dekoratif, satu item TalkBack.
    final vehicleCard = find.ancestor(
      of: find.text(vehicle.model),
      matching: find.byType(MergeSemantics),
    );
    final img = tester.widget<Image>(
      find.descendant(of: vehicleCard, matching: find.byType(Image)),
    );
    expect((img.image as AssetImage).assetName, vehicle.image);
    expect(img.excludeFromSemantics, isTrue);
    expect(
      tester.getSemantics(find.text(vehicle.model)),
      isSemantics(
        label:
            '${vehicle.model}\nNomor polisi ${vehicle.plate}\n'
            'Kapasitas\n${vehicle.capacity}\nDriver\n$demoDriverName',
      ),
    );

    // Tips: teks tone ok di bidang ok.
    for (final t in [
      'Tips berkendara',
      'Patuhi rambu lalu lintas.',
      'Hindari mengemudi agresif.',
      'Pastikan penumpang sesuai dengan trip.',
    ]) {
      final c = tester.widget<Text>(find.text(t)).style!.color!;
      expect(
        contrast(c, StatusTone.ok.background),
        greaterThanOrEqualTo(4.5),
        reason: t,
      );
    }
    expect(
      tester.getSemantics(find.text('Tips berkendara')),
      isSemantics(label: 'Tips berkendara', isHeader: true),
    );
    handle.dispose();
  });

  testWidgets('tab Reimburse: gaya tab Trip, Ajukan, filter status, kartu', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    tester.view
      ..physicalSize = const Size(800, 4000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());
    await tester.tap(tab('Reimburse'));
    await tester.pumpAndSettle();

    // Judul di Ground + subjudul muted, seperti tab Trip (bukan navy).
    expect(
      tester.getSemantics(
        find.descendant(
          of: find.byType(ListView).hitTestable(),
          matching: find.text('Reimburse'),
        ),
      ),
      isSemantics(label: 'Reimburse', isHeader: true),
    );
    final sub = find.text('Pengajuan biaya tol, parkir, BBM, dan lainnya.');
    final subColor = tester.widget<Text>(sub).style!.color!;
    expect(subColor, MooverColors.textMuted);
    expect(
      contrast(subColor, MooverColors.background),
      greaterThanOrEqualTo(4.5),
    );

    // Kartu navy: aksi Ajukan memberi tahu belum tersedia (S15 belum ada).
    final ajukan = find.text('Ajukan reimburse');
    expect(
      tester.getTopLeft(ajukan).dy,
      lessThan(tester.getTopLeft(find.text('Pengajuan')).dy),
    );
    for (final (t, bg) in [
      ('Ada biaya perjalanan?', MooverColors.navy),
      ('Ajukan dengan foto nota.', MooverColors.navy),
      ('Ajukan reimburse', MooverColors.cyan),
    ]) {
      // Warna efektif (label tombol mewarisi foregroundColor).
      final c = tester
          .widget<RichText>(
            find.descendant(of: find.text(t), matching: find.byType(RichText)),
          )
          .text
          .style!
          .color!;
      expect(contrast(c, bg), greaterThanOrEqualTo(4.5), reason: t);
    }
    await tester.tap(ajukan);
    await tester.pump();
    expect(find.text('Form reimburse belum tersedia.'), findsOneWidget);

    // Tiap pengajuan kartu sendiri (seperti trip), dibaca satu item.
    final cards = find.ancestor(
      of: find.byType(MooverReimburseItem),
      matching: find.byType(Card),
    );
    expect(find.byType(MooverReimburseItem), findsNWidgets(4));
    expect(
      find.descendant(
        of: find.byType(MooverReimburseItem),
        matching: find.byType(Card),
      ),
      findsNWidgets(4),
    );
    expect(cards, findsNothing, reason: 'tidak dibungkus satu kartu');
    expect(
      tester.getSemantics(find.text('Rp 45.000')),
      isSemantics(label: 'Tol\nRp 45.000\n8 Okt 2026\nDiajukan'),
    );

    // Filter status: label §4.7, terpilih primary + putih, jumlah ikut.
    final chips = find.byType(ChoiceChip);
    expect(
      [
        for (final c in tester.widgetList<ChoiceChip>(chips))
          (c.label as Text).data,
      ],
      ['Semua', 'Diajukan', 'Disetujui', 'Ditolak', 'Dibayar'],
    );
    expect(find.text('4 item'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Ditolak'));
    await tester.pumpAndSettle();
    expect(find.text('1 item'), findsOneWidget);
    expect(find.byType(MooverReimburseItem), findsOneWidget);
    expect(find.text('Rp 75.000'), findsOneWidget);
    final selected = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Ditolak'),
    );
    expect(selected.selected, isTrue);
    expect(
      contrast(selected.labelStyle!.color!, selected.selectedColor!),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      tester.getSemantics(find.widgetWithText(ChoiceChip, 'Ditolak')),
      isSemantics(label: 'Ditolak', isSelected: true, isButton: true),
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Semua'));
    await tester.pumpAndSettle();
    expect(find.byType(MooverReimburseItem), findsNWidgets(4));
    handle.dispose();
  });

  testWidgets(
    'tile trip tambahan: baris di layar lebar, tumpuk di 320dp 200%',
    (tester) async {
      const labels = [
        'Antar-jemput mendadak',
        'Permintaan trip baru',
        'Perubahan jadwal atau shift',
      ];
      Future<List<Offset>> tiles({required double textScale}) async {
        await tester.pumpWidget(app(textScale: textScale));
        await tester.tap(tab('Trip'));
        await tester.pumpAndSettle();
        return [
          for (final t in labels)
            tester.getTopLeft(find.text(t, skipOffstage: false)),
        ];
      }

      tester.view
        ..physicalSize = const Size(800, 4000)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final wide = await tiles(textScale: 1);
      expect(wide.map((o) => o.dy).toSet(), hasLength(1));

      // Emulator 2026-10-10: tiga kolom di 200% memotong kata ("jempu/t").
      tester.view
        ..physicalSize = const Size(960, 6000)
        ..devicePixelRatio = 3;
      final narrow = await tiles(textScale: 2);
      expect(narrow.map((o) => o.dx).toSet(), hasLength(1));
      expect(
        narrow.map((o) => o.dy).toList(),
        [...narrow.map((o) => o.dy)]..sort(),
      );
    },
  );

  testWidgets('ikon Lucide (gaya garis V2.1), tanpa Material Icons', (
    tester,
  ) async {
    Future<void> expectLucide(String screen) async {
      final icons = tester
          .widgetList<Icon>(find.byType(Icon, skipOffstage: false))
          .map((i) => i.icon!)
          .toList();
      expect(icons, isNotEmpty, reason: screen);
      for (final icon in icons) {
        expect(
          icon.fontPackage,
          'lucide_icons_flutter',
          reason: '$screen: ${icon.fontFamily} ${icon.codePoint}',
        );
      }
    }

    await tester.pumpWidget(app());
    // Gulir semua tab supaya isi ListView yang lazy ikut terbangun.
    for (final label in tabs) {
      await tester.tap(tab(label));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(Scrollable).hitTestable().first,
        const Offset(0, -3000),
      );
      await tester.pumpAndSettle();
      await expectLucide(label);
    }
    // Tab terpilih: varian lebih tebal, bukan ikon yang sama.
    final nav = tester.widget<MooverBottomNavigation>(
      find.byType(MooverBottomNavigation),
    );
    for (final item in nav.items) {
      expect(item.selectedIcon.fontFamily, isNot(item.icon.fontFamily));
    }

    await tester.pumpWidget(app(home: const LoginScreen()));
    await tester.pumpAndSettle();
    await expectLucide('Login');

    await tester.pumpWidget(
      app(
        home: Scaffold(
          body: Column(
            children: [
              const EmptyView(message: 'x'),
              ErrorView(message: 'y', onRetry: () {}),
            ],
          ),
        ),
      ),
    );
    await expectLucide('state views');
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

  test('sapaan menurut jam (V2.1: <11 pagi, <15 siang, <19 sore)', () {
    expect(
      {
        for (final h in [0, 10, 11, 14, 15, 18, 19, 23]) h: greeting(h),
      },
      {
        0: 'Selamat pagi',
        10: 'Selamat pagi',
        11: 'Selamat siang',
        14: 'Selamat siang',
        15: 'Selamat sore',
        18: 'Selamat sore',
        19: 'Selamat malam',
        23: 'Selamat malam',
      },
    );
  });

  test('format jam dan tanggal (D4)', () {
    expect(formatClock(DateTime(2026, 10, 9, 9, 5, 7)), '09.05.07');
    expect(formatClock(DateTime(2026, 10, 9, 23, 59, 59)), '23.59.59');
    expect(formatDate(DateTime(2026, 10, 9)), 'Jumat, 9 Okt 2026');
    expect(formatDate(DateTime(2026, 10, 11)), 'Minggu, 11 Okt 2026');
    expect(formatDate(DateTime(2027, 1, 4)), 'Senin, 4 Jan 2027');
  });

  testWidgets('simulasi clock-in: Beranda → S04 → status, Trip Available', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('Clock-in'));
    await tester.pumpAndSettle();
    expect(find.byType(AttendanceScreen), findsOneWidget);

    await tester.tap(find.text('Simulasi tanpa kamera'));
    await tester.pump();
    await tester.ensureVisible(find.text('Kirim clock-in'));
    await tester.pump();
    await tester.tap(find.text('Kirim clock-in'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.byType(AttendanceScreen), findsNothing);
    final at = clockIn.value!.at;
    final hhmm = formatClock(at).substring(0, 5);
    final agenda = find.byType(MooverAgendaCard);
    expect(
      find.descendant(of: agenda, matching: find.text('Clock-in $hhmm WIB')),
      findsOneWidget,
    );
    // Sudah clock-in: Clock-in diganti Clock-out (2026-10-13), pill cyan.
    expect(
      find.descendant(of: agenda, matching: find.text('Clock-in')),
      findsNothing,
    );
    expect(
      find.descendant(of: agenda, matching: find.text('Clock-out')),
      findsOneWidget,
    );
    expect(
      tester.widget<Text>(find.text('Clock-in $hhmm WIB')).style!.color,
      MooverColors.cyan,
    );
    // D10: pesan menyebut simulasi, bukan berhasil.
    expect(find.textContaining('simulasi'), findsOneWidget);
    expect(find.textContaining('berhasil'), findsNothing);

    await tester.tap(tab('Trip'));
    await tester.pumpAndSettle();
    final badge = tester.widget<StatusBadge>(find.byType(StatusBadge).first);
    expect((badge.label, badge.tone), ('Available', StatusTone.ok));
    expect(find.text('Tambah trip baru'), findsOneWidget);
  });

  testWidgets('clock-in dibatalkan (Kembali): status tetap belum', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('Clock-in'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    expect(clockIn.value, isNull);
    expect(find.text('Belum clock-in hari ini.'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('simulasi clock-out: kartu ringkasan, Time Log, Trip berhenti', (
    tester,
  ) async {
    clockIn.value = (at: DateTime(2030, 1, 2, 7, 5), photo: null);
    await tester.pumpWidget(app());
    final agenda = find.byType(MooverAgendaCard);
    await tester.tap(
      find.descendant(of: agenda, matching: find.text('Clock-out')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AttendanceScreen), findsOneWidget);
    expect(find.text('Clock-out'), findsOneWidget); // judul S04

    await tester.tap(find.text('Simulasi tanpa kamera'));
    await tester.pump();
    await tester.ensureVisible(find.text('Kirim clock-out'));
    await tester.pump();
    await tester.tap(find.text('Kirim clock-out'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    final out = clockOut.value!.at;
    expect(clockIn.value!.at, DateTime(2030, 1, 2, 7, 5)); // tetap
    // Kartu agenda diganti ringkasan V2.1.
    expect(agenda, findsNothing);
    expect(find.text('Anda sudah clock-out'), findsOneWidget);
    expect(find.text('07.05'), findsOneWidget);
    expect(find.text(formatHm(out)), findsOneWidget);
    final (status, _) = attendanceStatus((
      clockIn: clockIn.value!,
      clockOut: clockOut.value!,
    ));
    expect(find.widgetWithText(StatusBadge, status), findsOneWidget);
    // D10: simulasi, bukan berhasil.
    expect(
      find.text(
        'Clock-out ${formatHm(out)} WIB tercatat di simulasi '
        '(belum dikirim ke server).',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('berhasil'), findsNothing);

    await tester.tap(find.text('Lihat time log'));
    await tester.pumpAndSettle();
    expect(find.byType(TimeLogScreen), findsOneWidget);
    expect(find.byType(Card), findsWidgets);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    // Sudah clock-out: tidak Available lagi (sama dengan mock web).
    await tester.tap(tab('Trip'));
    await tester.pumpAndSettle();
    final badge = tester.widget<StatusBadge>(find.byType(StatusBadge).first);
    expect((badge.label, badge.tone), ('Tidak bertugas', StatusTone.neutral));
  });

  testWidgets('Akun → Time Log membuka S05', (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(tab('Akun'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Time Log'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Time Log'));
    await tester.pumpAndSettle();
    expect(find.byType(TimeLogScreen), findsOneWidget);
    expect(find.text('Time Log belum tersedia.'), findsNothing);
  });
}
