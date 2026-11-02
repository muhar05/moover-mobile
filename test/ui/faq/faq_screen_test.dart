import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moover/ui/core/themes/theme.dart';
import 'package:moover/ui/core/widgets/widgets.dart';
import 'package:moover/ui/faq/faq_screen.dart';
import 'package:moover/ui/main_menu/mock_data.dart';

import '../core/design_system_test.dart' show contrast;

// Nilai non-mock: terbukti datang dari parameter.
const sample = <Faq>[
  (question: 'Pertanyaan Alfa?', answer: 'Jawaban pertama.'),
  (question: 'Pertanyaan Beta?', answer: 'Isi berisi kata Gamma.'),
];

Widget app(List<Faq> faqs, {double textScale = 1}) => MaterialApp(
  theme: mooverTheme(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: FaqScreen(faqs: faqs),
);

void main() {
  testWidgets('S20: accordion buka/tutup, jawaban tersembunyi awalnya', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(app(sample));
    expect(find.text('Bantuan & FAQ'), findsOneWidget);
    expect(find.text('Pertanyaan Alfa?'), findsOneWidget);
    expect(find.text('Jawaban pertama.'), findsNothing);

    await tester.tap(find.text('Pertanyaan Alfa?'));
    await tester.pumpAndSettle();
    expect(find.text('Jawaban pertama.'), findsOneWidget);
    expect(find.text('Isi berisi kata Gamma.'), findsNothing);

    await tester.tap(find.text('Pertanyaan Alfa?'));
    await tester.pumpAndSettle();
    expect(find.text('Jawaban pertama.'), findsNothing);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    expect(
      contrast(MooverColors.textMuted, MooverColors.surface),
      greaterThanOrEqualTo(4.5),
    );
    handle.dispose();
  });

  testWidgets('S20: cari di pertanyaan + jawaban; kosong; hapus', (
    tester,
  ) async {
    await tester.pumpWidget(app(sample));
    // Cocok di jawaban, tanpa membedakan huruf besar/kecil.
    await tester.enterText(find.byType(TextField), 'gamma');
    await tester.pump();
    expect(find.text('Pertanyaan Beta?'), findsOneWidget);
    expect(find.text('Pertanyaan Alfa?'), findsNothing);

    await tester.enterText(find.byType(TextField), 'tidak ada');
    await tester.pump();
    expect(find.byType(EmptyView), findsOneWidget);
    expect(find.text('Tidak ada pertanyaan yang cocok.'), findsOneWidget);

    await tester.tap(find.byTooltip('Hapus pencarian'));
    await tester.pump();
    expect(find.byType(EmptyView), findsNothing);
    expect(find.text('Pertanyaan Alfa?'), findsOneWidget);
    expect(find.text('Pertanyaan Beta?'), findsOneWidget);
  });

  testWidgets('320dp + teks 200%: tanpa overflow (tertutup dan terbuka)', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(960, 1704)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(faqs, textScale: 2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text(faqs.first.question));
    await tester.pumpAndSettle();
    expect(find.text(faqs.first.answer), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
