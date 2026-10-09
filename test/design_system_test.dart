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
    const MockDataBanner(),
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
  test('kontras pasangan yang didefinisikan ≥4,5:1 (hitungan WCAG)', () {
    final theme = mooverTheme();
    final s = theme.colorScheme;
    final pairs = <String, (Color, Color)>{
      'onPrimary/primary': (s.onPrimary, s.primary),
      'onSurface/surface': (s.onSurface, s.surface),
      'onSurface/scaffold': (s.onSurface, theme.scaffoldBackgroundColor),
      'textMuted/surface': (s.onSurfaceVariant, s.surface),
      for (final t in StatusTone.values)
        'tone ${t.name}': (t.foreground, t.background),
    };
    for (final MapEntry(:key, value: (fg, bg)) in pairs.entries) {
      expect(contrast(fg, bg), greaterThanOrEqualTo(4.5), reason: key);
    }
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
}
