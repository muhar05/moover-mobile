import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moover_driver/design/theme.dart';
import 'package:moover_driver/design/widgets.dart';

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
      // Kartu agenda Beranda: teks di atas steel.
      'surface/primary (kartu agenda)': (MooverColors.surface, s.primary),
      'mist/primary (kartu agenda, teks sekunder)': (
        MooverColors.mist,
        s.primary,
      ),
      // Bottom navigation: label tak terpilih di atas putih; terpilih di
      // atas pill mist (ikon).
      'textMuted/surface (nav tak terpilih)': (
        MooverColors.textMuted,
        MooverColors.surface,
      ),
      'text/mist (ikon nav terpilih)': (MooverColors.text, MooverColors.mist),
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
      'garis teal/surface (indikator nav)': (
        MooverColors.teal,
        MooverColors.surface,
      ),
      'outline/surface (tepi segmen)': (s.outline, s.surface),
      'bidang logo/teal (Splash)': (MooverColors.surface, MooverColors.teal),
    };
    for (final MapEntry(:key, value: (fg, bg)) in pairs.entries) {
      expect(contrast(fg, bg), greaterThanOrEqualTo(3), reason: key);
    }
  });

  test('pasangan palet yang tidak boleh dipakai untuk teks (<4,5:1)', () {
    // Dokumentasi: alasan teal/surf tidak dipakai sebagai warna teks.
    const white = MooverColors.surface;
    expect(contrast(MooverColors.teal, white), lessThan(4.5));
    expect(contrast(MooverColors.surf, white), lessThan(3));
    expect(contrast(white, MooverColors.teal), lessThan(4.5));
    expect(contrast(MooverColors.steel, MooverColors.abyss), lessThan(3));
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
      MooverColors.surf,
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
      [MooverRadius.sm, MooverRadius.md, MooverRadius.card, MooverRadius.lg],
      [12, 16, 20, 24],
    );
    // Radius kartu tetap 20 (keputusan C), bukan 24.
    final shape = mooverTheme().cardTheme.shape! as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(20));
  });

  testWidgets('StatusBadge: ≥12sp, w600 (pengecualian disengaja)', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(const StatusBadge(label: 'Selesai', tone: StatusTone.ok)),
    );
    final style = tester.widget<Text>(find.text('Selesai')).style!;
    expect(style.fontSize, greaterThanOrEqualTo(12));
    expect(style.fontWeight, FontWeight.w600);
    expect(style.color, StatusTone.ok.foreground);
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
    expect(fill(), MooverColors.mist);
    expect(label('Kirim').color, MooverColors.abyss);
    expect(contrast(label('Kirim').color!, fill()), greaterThanOrEqualTo(4.5));
    expect(label('Kirim').fontWeight, FontWeight.w500);
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

    // Nonaktif karena alasan lain: tetap tampilan bawaan, bukan mist.
    await tester.pumpWidget(
      harness(
        const Center(child: PrimaryButton(label: 'Kirim', onPressed: null)),
      ),
    );
    // Elemen tombol dipakai ulang: warna dianimasikan, tunggu selesai.
    await tester.pumpAndSettle();
    expect(fill(), isNot(MooverColors.mist));
    expect(label('Kirim').color, isNot(MooverColors.abyss));

    // Tinggi tidak berubah (52dp ditunda); weight normal tetap 500.
    await tester.pumpWidget(
      harness(
        Center(
          child: PrimaryButton(label: 'Kirim', onPressed: () {}),
        ),
      ),
    );
    expect(tester.getSize(find.byType(FilledButton)).height, busySize.height);
    expect(label('Kirim').fontWeight, FontWeight.w500);
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
    Widget agenda() => const MooverAgendaCard(
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

    testWidgets('data dari parameter tampil', (tester) async {
      await tester.pumpWidget(
        harness(Column(children: [agenda(), reimburse()])),
      );
      for (final t in [
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

    testWidgets('320dp, teks 200%: tanpa overflow', (tester) async {
      tester.view
        ..physicalSize = const Size(960, 1704)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        harness(
          SingleChildScrollView(
            padding: const EdgeInsets.all(MooverSpace.screen),
            child: Column(children: [agenda(), reimburse()]),
          ),
          textScale: 2,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.text('Rp 1.234.567')).right,
        lessThanOrEqualTo(320),
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
