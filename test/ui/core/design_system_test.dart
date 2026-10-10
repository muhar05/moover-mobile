import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moover_driver/ui/core/themes/theme.dart';
import 'package:moover_driver/ui/core/widgets/widgets.dart';

// Uji ini hanya mencakup pasangan warna dan komponen yang didefinisikan di
// sini. Ini bukan uji aksesibilitas layar atau uji di perangkat.

double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

Widget harness(Widget child, {double textScale = 1}) => MaterialApp(
  theme: mooverTheme(),
  builder: (context, app) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: app!,
  ),
  home: Scaffold(body: child),
);

Widget sampleComponents() => ListView(
  padding: const EdgeInsets.all(16),
  children: [
    PrimaryButton(label: 'Kirim pengajuan reimburse', onPressed: () {}),
    const PrimaryButton(
      label: 'Kirim pengajuan reimburse',
      onPressed: null,
      busy: true,
    ),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tone in StatusTone.values)
          StatusBadge(label: 'Dalam Perjalanan ${tone.name}', tone: tone),
      ],
    ),
    ErrorView(
      message: 'Gagal memuat data. Periksa koneksi internet.',
      onRetry: () {},
    ),
    EmptyView(
      message: 'Belum ada pengajuan.',
      action: TextButton(onPressed: () {}, child: const Text('Ajukan')),
    ),
    const SkeletonBox(height: 16),
  ],
);

void main() {
  test('kontras teks ≥4,5:1 (hitungan WCAG), termasuk turunan M3', () {
    final theme = mooverTheme();
    final s = theme.colorScheme;
    final bg = theme.scaffoldBackgroundColor;
    final pairs = <String, (Color, Color)>{
      'onPrimary/primary (FilledButton)': (s.onPrimary, s.primary),
      'primary/latar (Outlined/TextButton, label fokus)': (s.primary, bg),
      'primary/surface': (s.primary, s.surface),
      'onSurface/surface': (s.onSurface, s.surface),
      'onSurface/latar': (s.onSurface, bg),
      'textMuted/surface': (s.onSurfaceVariant, s.surface),
      'textMuted/latar': (s.onSurfaceVariant, bg),
      'onSecondary/secondary': (s.onSecondary, s.secondary),
      'onPrimaryContainer/primaryContainer': (
        s.onPrimaryContainer,
        s.primaryContainer,
      ),
      'onSecondaryContainer/secondaryContainer (terpilih)': (
        s.onSecondaryContainer,
        s.secondaryContainer,
      ),
      'error/latar': (s.error, bg),
      'error/surface': (s.error, s.surface),
      // NavigationBar: label & ikon tak terpilih di atas surfaceContainer.
      'textMuted/surfaceContainer (nav bar)': (
        s.onSurfaceVariant,
        s.surfaceContainer,
      ),
      'onSurface/surfaceContainer (nav bar)': (s.onSurface, s.surfaceContainer),
      // Dialog: judul dan tombol di atas surfaceContainerHigh.
      'onSurface/surfaceContainerHigh (dialog)': (
        s.onSurface,
        s.surfaceContainerHigh,
      ),
      'primary/surfaceContainerHigh (dialog)': (
        s.primary,
        s.surfaceContainerHigh,
      ),
      // Kartu agenda Beranda: teks di atas ujung terang gradient (blue700).
      'surface/blue700 (kartu agenda)': (
        MooverColors.surface,
        MooverColors.blue700,
      ),
      'sky/blue700 (kartu agenda, teks sekunder)': (
        MooverColors.sky,
        MooverColors.blue700,
      ),
      // V2.1 header navy: teks utama, sekunder, dan tombol aksen cyan.
      'surface/navy': (MooverColors.surface, MooverColors.navy),
      'sky/navy': (MooverColors.sky, MooverColors.navy),
      // Pill garis amber "belum clock-in" di kedua ujung gradient Agenda.
      'amber/navy (pill clock-in)': (MooverColors.amber, MooverColors.navy),
      'amber/blue700 (pill clock-in)': (
        MooverColors.amber,
        MooverColors.blue700,
      ),
      'navy/cyan (tombol aksen)': (MooverColors.navy, MooverColors.cyan),
      // Bottom navigation: label tak terpilih di atas putih; terpilih di
      // atas pill blueTint (ikon).
      'textMuted/surface (nav tak terpilih)': (
        MooverColors.textMuted,
        MooverColors.surface,
      ),
      'primary/blueTint (ikon nav terpilih)': (
        MooverColors.primary,
        MooverColors.blueTint,
      ),
      'primary/surface (label nav terpilih)': (
        MooverColors.primary,
        MooverColors.surface,
      ),
      // V2.1 tombol nonaktif (tema FilledButton).
      'textMuted/hairline (tombol nonaktif)': (
        MooverColors.textMuted,
        MooverColors.hairline,
      ),
      // Segmen Trip terpilih.
      'surface/primary (segmen terpilih)': (MooverColors.surface, s.primary),
      // Splash: logo (±#0040A0) di atas bidang putih.
      'logo/surface': (const Color(0xFF0040A0), MooverColors.surface),
      for (final t in StatusTone.values)
        'tone ${t.name}': (t.foreground, t.background),
    };
    for (final MapEntry(:key, value: (fg, bg)) in pairs.entries) {
      expect(contrast(fg, bg), greaterThanOrEqualTo(4.5), reason: key);
    }
  });

  test('elemen nonteks ≥3:1: garis input, outline, kartu, bidang logo', () {
    final theme = mooverTheme();
    final s = theme.colorScheme;
    final bg = theme.scaffoldBackgroundColor;
    final pairs = <String, (Color, Color)>{
      'outline/surface (garis input)': (s.outline, s.surface),
      'outline/latar (OutlinedButton)': (s.outline, bg),
      'primary/surface (garis input fokus)': (s.primary, s.surface),
      'error/surface (garis input error)': (s.error, s.surface),
      'garis blue500/surface (indikator nav)': (
        MooverColors.blue500,
        MooverColors.surface,
      ),
      'garis blue500/latar (rute)': (
        MooverColors.blue500,
        MooverColors.background,
      ),
      'outline/surface (tepi segmen)': (s.outline, s.surface),
      'bidang logo/blue500 (Splash)': (
        MooverColors.surface,
        MooverColors.blue500,
      ),
      'cyan/navy (titik live, aksen)': (MooverColors.cyan, MooverColors.navy),
      'cyan/blue700 (isi bar progres Agenda)': (
        MooverColors.cyan,
        MooverColors.blue700,
      ),
    };
    for (final MapEntry(:key, value: (fg, bg)) in pairs.entries) {
      expect(contrast(fg, bg), greaterThanOrEqualTo(3), reason: key);
    }
  });

  test('pasangan palet yang tidak boleh dipakai untuk teks (<4,5:1)', () {
    // Dokumentasi: alasan blue500/cyan tidak dipakai sebagai warna teks di
    // permukaan terang, dan alasan tepi kontrol V2.1 diganti outline.
    const white = MooverColors.surface;
    expect(contrast(MooverColors.blue500, white), lessThan(4.5));
    expect(contrast(MooverColors.cyan, white), lessThan(3));
    expect(contrast(white, MooverColors.blue500), lessThan(4.5));
    expect(contrast(MooverColors.text, MooverColors.navy), lessThan(3));
    // Tepi input/tombol sekunder V2.1 asli: <3:1 (gagal D9).
    expect(contrast(const Color(0xFFD5DCE7), white), lessThan(3));
    expect(contrast(const Color(0xFFC9D6EE), white), lessThan(3));
    // Hijau ok V2.1 asli: <4,5:1 di tint-nya.
    expect(
      contrast(const Color(0xFF1A7F4B), StatusTone.ok.background),
      lessThan(4.5),
    );
  });

  test('palet = V2.1 (keputusan pemilik project 2026-10-10)', () {
    expect(
      [
        MooverColors.navy,
        MooverColors.blue700,
        MooverColors.blue500,
        MooverColors.cyan,
        MooverColors.cyanTint,
        MooverColors.blueTint,
        MooverColors.text,
        MooverColors.textMuted,
        MooverColors.hairline,
        MooverColors.background,
      ],
      const [
        Color(0xFF06275C),
        Color(0xFF0550AE),
        Color(0xFF0A84D8),
        Color(0xFF08DCF3),
        Color(0xFFDDF8FD),
        Color(0xFFE8F1FD),
        Color(0xFF0B1730),
        Color(0xFF56627A),
        Color(0xFFE2E8F2),
        Color(0xFFF3F6FB),
      ],
    );
    expect(MooverColors.primary, MooverColors.blue700);
    expect(mooverTheme().colorScheme.primary, const Color(0xFF0550AE));
  });

  test('status tetap berbeda satu sama lain (tone tidak disamakan)', () {
    final fg = {for (final t in StatusTone.values) t.foreground};
    final bg = {for (final t in StatusTone.values) t.background};
    expect(fg, hasLength(StatusTone.values.length));
    expect(bg, hasLength(StatusTone.values.length));
  });

  testWidgets('komponen memakai token tema', (tester) async {
    await tester.pumpWidget(
      harness(
        Column(
          children: [
            PrimaryButton(label: 'Masuk', onPressed: () {}),
            NavigationBar(
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home), label: 'A'),
                NavigationDestination(icon: Icon(Icons.person), label: 'B'),
              ],
            ),
          ],
        ),
      ),
    );
    Color materialColor(Finder of) => tester
        .widget<Material>(
          find.descendant(of: of, matching: find.byType(Material)).first,
        )
        .color!;
    expect(materialColor(find.byType(FilledButton)), MooverColors.primary);
    expect(
      tester
          .widget<NavigationIndicator>(find.byType(NavigationIndicator).first)
          .color,
      MooverColors.blueTint,
    );
  });

  test('token typography: judul w700, font Plus Jakarta Sans', () {
    final t = mooverTheme().textTheme;
    for (final (name, s) in [
      ('headlineMedium', t.headlineMedium),
      ('titleLarge', t.titleLarge),
      ('titleMedium', t.titleMedium),
      ('titleSmall', t.titleSmall),
    ]) {
      expect(s!.fontWeight, FontWeight.w700, reason: name);
    }
    // Peran lain tetap bawaan M3 (tidak ikut tebal).
    expect(t.bodyMedium!.fontWeight, isNot(FontWeight.w700));
    expect(t.labelMedium!.fontWeight, isNot(FontWeight.w700));
    for (final s in [
      t.headlineMedium,
      t.titleSmall,
      t.bodySmall,
      t.labelSmall,
    ]) {
      expect(s!.fontFamily, mooverFontFamily);
    }
  });

  test('token spacing dan radius', () {
    const space = [
      MooverSpace.xs,
      MooverSpace.sm,
      MooverSpace.md,
      MooverSpace.lg,
      MooverSpace.xl,
      MooverSpace.xxl,
    ];
    expect(space, [4, 8, 12, 16, 24, 32]);
    expect(MooverSpace.screen, 20);
    expect(
      [
        MooverRadius.sm,
        MooverRadius.input,
        MooverRadius.md,
        MooverRadius.card,
        MooverRadius.lg,
      ],
      [12, 14, 16, 20, 24],
    );
    // Radius kartu tetap 20 (keputusan C), bukan 24.
    final shape = mooverTheme().cardTheme.shape! as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(20));
  });

  testWidgets('StatusBadge: ≥12sp, w800 (V2.1, keputusan 2026-10-10)', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(const StatusBadge(label: 'Selesai', tone: StatusTone.ok)),
    );
    final style = tester.widget<Text>(find.text('Selesai')).style!;
    expect(style.fontSize, 13);
    expect(style.fontWeight, FontWeight.w800);
    expect(style.color, StatusTone.ok.foreground);
  });

  testWidgets('StatusBadge live: titik cyan dekoratif, tone lain tanpa titik', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    Finder dot() => find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).shape == BoxShape.circle &&
          (w.decoration as BoxDecoration).color == MooverColors.cyan,
    );
    for (final tone in StatusTone.values) {
      await tester.pumpWidget(
        harness(StatusBadge(label: 'Sedang trip', tone: tone)),
      );
      expect(
        dot(),
        tone == StatusTone.live ? findsOneWidget : findsNothing,
        reason: tone.name,
      );
      // Titik tidak dibaca; label tetap satu-satunya makna.
      expect(find.bySemanticsLabel('Sedang trip'), findsOneWidget);
    }
    await tester.pumpWidget(
      harness(const StatusBadge(label: 'Sedang trip', tone: StatusTone.live)),
    );
    expect(tester.getSize(dot()), const Size(7, 7));
    handle.dispose();
  });

  testWidgets('PrimaryButton busy: spinner tampil dan tidak bisa ditekan', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      harness(
        PrimaryButton(label: 'Kirim', busy: true, onPressed: () => taps++),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.text('Kirim'));
    expect(taps, 0);

    await tester.pumpWidget(
      harness(PrimaryButton(label: 'Kirim', onPressed: () => taps++)),
    );
    await tester.tap(find.text('Kirim'));
    expect(taps, 1);
  });

  testWidgets('PrimaryButton busy: label ≥4,5:1, semantik, ukuran tetap', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    Color fill() => tester
        .widget<Material>(
          find
              .descendant(
                of: find.byType(FilledButton),
                matching: find.byType(Material),
              )
              .first,
        )
        .color!;
    TextStyle label(String t) =>
        DefaultTextStyle.of(tester.element(find.text(t))).style;

    await tester.pumpWidget(
      harness(
        Center(
          child: PrimaryButton(label: 'Kirim', busy: true, onPressed: () {}),
        ),
      ),
    );
    final busySize = tester.getSize(find.byType(FilledButton));
    expect(fill(), MooverColors.blueTint);
    expect(label('Kirim').color, MooverColors.text);
    expect(contrast(label('Kirim').color!, fill()), greaterThanOrEqualTo(4.5));
    expect(label('Kirim').fontWeight, FontWeight.w800);
    // Pembaca layar: status memproses + label, tombol nonaktif.
    expect(
      tester.getSemantics(find.byType(FilledButton)),
      isSemantics(
        label: 'Memproses\nKirim',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
        hasTapAction: false,
      ),
    );

    // Nonaktif karena alasan lain: tampilan disabled V2.1, bukan blueTint.
    await tester.pumpWidget(
      harness(
        const Center(child: PrimaryButton(label: 'Kirim', onPressed: null)),
      ),
    );
    // Elemen tombol dipakai ulang: warna dianimasikan, tunggu selesai.
    await tester.pumpAndSettle();
    expect(fill(), MooverColors.hairline);
    expect(label('Kirim').color, isNot(MooverColors.text));

    // V2.1 (keputusan 2026-10-10): tinggi 56, radius 16, label 16/w800;
    // tinggi tidak berubah saat busy.
    await tester.pumpWidget(
      harness(
        Center(
          child: PrimaryButton(label: 'Kirim', onPressed: () {}),
        ),
      ),
    );
    expect(tester.getSize(find.byType(FilledButton)).height, busySize.height);
    expect(busySize.height, 56);
    expect(label('Kirim').fontWeight, FontWeight.w800);
    expect(label('Kirim').fontSize, 16);
    expect(
      (tester
                  .widget<Material>(
                    find
                        .descendant(
                          of: find.byType(FilledButton),
                          matching: find.byType(Material),
                        )
                        .first,
                  )
                  .shape!
              as RoundedRectangleBorder)
          .borderRadius,
      BorderRadius.circular(MooverRadius.md),
    );
    handle.dispose();
  });

  testWidgets('komponen tidak overflow pada skala teks 200% di layar 360dp', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1080, 1920)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness(sampleComponents(), textScale: 2));
    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('target sentuh ≥48dp dan tombol berlabel', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(harness(sampleComponents()));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  group('komponen berparameter', () {
    // Data non-mock: memastikan nilai datang dari parameter, bukan konstanta.
    Widget agenda({double progress = 0.5}) => MooverAgendaCard(
      date: 'Tanggal Q',
      shiftProgress: progress,
      tripCount: 7,
      nextTime: '11.15 WIB',
      origin: 'Gudang Timur Lantai Dua Pintu Barat',
      destination: 'Terminal Kedatangan Internasional',
      clockInStatus: 'Status X',
      operatingHours: 'Jam Y',
    );
    Widget reimburse() => const MooverReimburseItem(
      category: 'Kategori Z',
      icon: Icons.toll_outlined,
      amount: 'Rp 1.234.567',
      date: '2 Jan 2027',
      status: 'Status W',
      tone: StatusTone.info,
    );
    Widget trip({bool next = false}) => MooverTripItem(
      time: '06.45 WIB',
      origin: 'Asal P',
      destination: 'Tujuan R',
      status: 'Status V',
      tone: StatusTone.live,
      passengers: '9 orang',
      next: next,
    );

    testWidgets('data dari parameter tampil', (tester) async {
      await tester.pumpWidget(
        harness(Column(children: [agenda(), reimburse()])),
      );
      for (final t in [
        'Tanggal Q',
        '7 trip',
        '11.15 WIB',
        'Status X',
        'Jam Y',
        'Kategori Z',
        'Rp 1.234.567',
        '2 Jan 2027',
        'Status W',
      ]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      final route = tester.widget<MooverRouteTimeline>(
        find.byType(MooverRouteTimeline),
      );
      expect(
        (route.origin, route.destination, route.onDark),
        (
          'Gudang Timur Lantai Dua Pintu Barat',
          'Terminal Kedatangan Internasional',
          true,
        ),
      );
      expect(
        tester.widget<StatusBadge>(find.byType(StatusBadge)).tone,
        StatusTone.info,
      );
    });

    testWidgets('Agenda: bar progres mengikuti shiftProgress (0–1)', (
      tester,
    ) async {
      double fill() => tester
          .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .widthFactor!;
      for (final (p, want) in [(0.25, 0.25), (-1.0, 0.0), (3.0, 1.0)]) {
        await tester.pumpWidget(harness(agenda(progress: p)));
        expect(fill(), want, reason: '$p');
      }
      // Tanpa tombol/aksi clock-in.
      expect(
        find.descendant(
          of: find.byType(MooverAgendaCard),
          matching: find.byWidgetPredicate(
            (w) => w is InkWell || w is ButtonStyleButton,
          ),
        ),
        findsNothing,
      );
    });

    testWidgets('kartu trip: kartu, data, badge Berikutnya, semantik', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(harness(trip(next: true)));
      expect(
        find.ancestor(of: find.text('Asal P'), matching: find.byType(Card)),
        findsOneWidget,
      );
      final badges = tester
          .widgetList<StatusBadge>(find.byType(StatusBadge))
          .map((b) => (b.label, b.tone));
      expect(badges, [
        ('Berikutnya', StatusTone.info),
        ('Status V', StatusTone.live),
      ]);
      // Kolom waktu di kiri rute.
      expect(
        tester.getRect(find.text('06.45 WIB')).right,
        lessThan(tester.getRect(find.byType(MooverRouteTimeline)).left),
      );
      expect(
        tester.getSemantics(find.byType(MooverTripItem)),
        isSemantics(
          label:
              '06.45 WIB\nBerikutnya\nStatus V\n'
              'Dari Asal P ke Tujuan R\n9 orang',
        ),
      );
      await tester.pumpWidget(harness(trip()));
      expect(find.text('Berikutnya'), findsNothing);
      handle.dispose();
    });

    testWidgets('320dp, teks 200%: tanpa overflow', (tester) async {
      tester.view
        ..physicalSize = const Size(960, 1704)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        harness(
          SingleChildScrollView(
            padding: const EdgeInsets.all(MooverSpace.screen),
            child: Column(children: [agenda(), reimburse(), trip(next: true)]),
          ),
          textScale: 2,
        ),
      );
      expect(tester.takeException(), isNull);
      for (final t in ['Rp 1.234.567', '11.15 WIB', '06.45 WIB', 'Status V']) {
        expect(
          tester.getRect(find.text(t)).right,
          lessThanOrEqualTo(320),
          reason: t,
        );
      }
    });
  });

  group('MooverBottomNavigation', () {
    const items = <MooverNavItem>[
      (label: 'Satu', icon: Icons.home_outlined, selectedIcon: Icons.home),
      (label: 'Dua', icon: Icons.person_outline, selectedIcon: Icons.person),
    ];
    Widget nav({int selected = 0}) => MaterialApp(
      theme: mooverTheme(),
      home: Scaffold(
        bottomNavigationBar: MooverBottomNavigation(
          items: items,
          selectedIndex: selected,
          onSelected: (_) {},
        ),
      ),
    );

    testWidgets('V2.1: menempel, putih, tepi atas hairline, tanpa bayangan', (
      tester,
    ) async {
      await tester.pumpWidget(nav());
      final bar = find.byType(MooverBottomNavigation);
      final rect = tester.getRect(bar);
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      expect(rect.left, 0);
      expect(rect.right, screen.width);
      expect(rect.bottom, screen.height);
      final material = tester.widget<Material>(
        find.descendant(of: bar, matching: find.byType(Material)).first,
      );
      expect(material.color, MooverColors.surface);
      expect(material.elevation, 0);
      expect(
        material.shape,
        const Border(top: BorderSide(color: MooverColors.hairline)),
      );
      expect(
        find.descendant(
          of: bar,
          matching: find.byWidgetPredicate(
            (w) =>
                w is DecoratedBox &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).boxShadow != null,
          ),
        ),
        findsNothing,
      );
    });

    testWidgets('tab aktif: pill blueTint 56×30, primary w800; lain w600', (
      tester,
    ) async {
      await tester.pumpWidget(nav(selected: 1));
      TextStyle style(String t) => tester.widget<Text>(find.text(t)).style!;
      expect(
        (style('Dua').color, style('Dua').fontWeight),
        (MooverColors.primary, FontWeight.w800),
      );
      expect(
        (style('Satu').color, style('Satu').fontWeight),
        (MooverColors.textMuted, FontWeight.w600),
      );
      final pills = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .toList();
      expect(pills.map((p) => (p.decoration! as BoxDecoration).color), [
        MooverColors.blueTint.withValues(alpha: 0),
        MooverColors.blueTint,
      ]);
      expect(
        tester.getSize(find.byType(AnimatedContainer).last),
        const Size(56, 30),
      );
      // Tinggi tab ≥56 (V2.1), di atas minimum 48 (D9).
      expect(
        tester.getSize(find.byType(InkWell).first).height,
        greaterThanOrEqualTo(56),
      );
    });
  });

  group('MooverRouteTimeline', () {
    const longOrigin =
        'Gedung Kantor Pusat Siaga Abdi Utama Lantai Dasar Pintu Timur';
    const longDest =
        'Bandara Internasional Soekarno-Hatta Terminal 3 Kedatangan';

    Widget timeline({bool onDark = false}) => ColoredBox(
      color: onDark ? MooverColors.primary : MooverColors.background,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: MooverRouteTimeline(origin: longOrigin, destination: longDest),
      ),
    );

    Color textColor(WidgetTester tester, String text) =>
        tester.widget<Text>(find.text(text)).style!.color!;

    testWidgets('warna terbaca di latar terang dan gelap', (tester) async {
      for (final (onDark, bg) in [
        (false, MooverColors.background),
        (false, MooverColors.surface),
        (true, MooverColors.primary),
      ]) {
        await tester.pumpWidget(
          harness(
            MooverRouteTimeline(origin: 'A', destination: 'B', onDark: onDark),
          ),
        );
        for (final t in ['A', 'B']) {
          expect(
            contrast(textColor(tester, t), bg),
            greaterThanOrEqualTo(4.5),
            reason: '$t onDark=$onDark',
          );
        }
        // Titik asal (isi) dan tujuan (cincin): elemen nonteks ≥3:1.
        final dots = tester
            .widgetList<Container>(find.byType(Container))
            .map((c) => c.decoration)
            .whereType<BoxDecoration>()
            .where((d) => d.shape == BoxShape.circle);
        expect(dots, hasLength(2));
        for (final d in dots) {
          final c = d.color ?? (d.border! as Border).top.color;
          expect(
            contrast(c, bg),
            greaterThanOrEqualTo(3),
            reason: 'titik onDark=$onDark',
          );
        }
      }
    });

    testWidgets('nama panjang: 320dp, teks 200%, tanpa overflow, berurutan', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(960, 1704)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      for (final onDark in [false, true]) {
        await tester.pumpWidget(
          harness(
            SingleChildScrollView(child: timeline(onDark: onDark)),
            textScale: 2,
          ),
        );
        expect(tester.takeException(), isNull);
        final o = tester.getRect(find.text(longOrigin));
        final d = tester.getRect(find.text(longDest));
        // Membungkus beberapa baris, tidak terpotong; tujuan di bawah asal.
        expect(o.height, greaterThan(60));
        expect(d.top, greaterThanOrEqualTo(o.bottom));
        expect(o.right, lessThanOrEqualTo(320));
        expect(d.right, lessThanOrEqualTo(320));
      }
    });

    testWidgets('semantics: satu label asal lalu tujuan, tanpa dobel', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        harness(const MooverRouteTimeline(origin: 'Asal X', destination: 'Y')),
      );
      expect(
        tester.getSemantics(find.byType(MooverRouteTimeline)),
        isSemantics(label: 'Dari Asal X ke Y'),
      );
      expect(find.bySemanticsLabel('Asal X'), findsNothing);
      expect(find.bySemanticsLabel('Y'), findsNothing);
      handle.dispose();
    });
  });
}
