import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moover/ui/core/themes/theme.dart';
import 'package:moover/ui/main_menu/mock_data.dart';
import 'package:moover/ui/support/support_screen.dart';

import '../core/design_system_test.dart' show contrast;

// Nilai non-mock: terbukti datang dari parameter.
final sample = <SupportContact>[
  (
    icon: LucideIcons.mail,
    label: 'Surel Uji',
    value: 'uji@contoh.example',
    uri: Uri(scheme: 'mailto', path: 'uji@contoh.example'),
  ),
  (
    icon: LucideIcons.phone,
    label: 'Telepon Uji',
    value: '(000) 111',
    uri: Uri(scheme: 'tel', path: '000111'),
  ),
];

Widget app(List<SupportContact> contacts, {double textScale = 1}) =>
    MaterialApp(
      theme: mooverTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: SupportScreen(contacts: contacts),
    );

void main() {
  late List<Uri> opened;
  late bool result;
  setUp(() {
    opened = [];
    result = true;
    openExternal = (uri) async {
      opened.add(uri);
      return result;
    };
  });

  testWidgets('S21: tiap kontak satu tombol; ketuk membuka uri-nya', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(app(sample));
    expect(find.text('Hubungi support'), findsOneWidget);
    for (final c in sample) {
      expect(
        tester.getSemantics(find.text(c.label)),
        isSemantics(
          label: '${c.label}\n${c.value}',
          isButton: true,
          hasTapAction: true,
        ),
        reason: c.label,
      );
    }
    await tester.tap(find.text('Telepon Uji'));
    await tester.pump();
    expect(opened, [sample[1].uri]);
    expect(find.byType(SnackBar), findsNothing);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    expect(
      contrast(StatusTone.live.foreground, StatusTone.live.background),
      greaterThanOrEqualTo(3),
    );
    expect(
      contrast(MooverColors.textMuted, MooverColors.surface),
      greaterThanOrEqualTo(4.5),
    );
    handle.dispose();
  });

  testWidgets('S21: gagal membuka aplikasi → pesan', (tester) async {
    result = false;
    await tester.pumpWidget(app(sample));
    await tester.tap(find.text('Surel Uji'));
    await tester.pump();
    expect(opened, [sample[0].uri]);
    expect(find.text('Tidak bisa membuka Surel Uji.'), findsOneWidget);
  });

  test('kontak demo: WhatsApp/email/telepon, skema benar, fiktif', () {
    expect(
      [for (final c in supportContacts) c.uri.scheme],
      ['https', 'mailto', 'tel'],
    );
    expect(supportContacts.first.uri.host, 'wa.me');
    expect(supportContacts[1].value, endsWith('.example'));
  });

  testWidgets('320dp + teks 200%: tanpa overflow', (tester) async {
    tester.view
      ..physicalSize = const Size(960, 1704)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(supportContacts, textScale: 2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
