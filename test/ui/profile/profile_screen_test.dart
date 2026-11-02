import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moover/ui/core/themes/theme.dart';
import 'package:moover/ui/core/widgets/widgets.dart';
import 'package:moover/ui/profile/profile_screen.dart';

import '../core/design_system_test.dart' show contrast;

// Nilai non-mock: terbukti datang dari parameter.
Widget app({double textScale = 1}) => MaterialApp(
  theme: mooverTheme(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: const ProfileScreen(
    name: 'nama uji coba',
    employeeId: 'UJI-42',
    email: 'uji.nama.panjang.sekali@contoh.example',
  ),
);

void main() {
  testWidgets('S18 hanya baca: nama, Employee ID, email; tanpa edit', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(app());
    expect(find.text('Informasi profil'), findsOneWidget); // judul
    for (final (label, value) in [
      ('Nama', 'nama uji coba'),
      ('Employee ID', 'UJI-42'),
      ('Email', 'uji.nama.panjang.sekali@contoh.example'),
    ]) {
      expect(
        tester.getSemantics(find.text(label)),
        isSemantics(label: '$label\n$value'),
        reason: label,
      );
    }
    // Avatar dari nama yang diberikan (inisial, maks. 2, huruf besar).
    expect(find.text('NU'), findsOneWidget);
    // Tanpa aksi edit: field dan tombol tidak ada.
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.text('Mengubah data profil belum tersedia.'), findsOneWidget);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    expect(
      contrast(MooverColors.textMuted, MooverColors.background),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrast(MooverColors.primary, MooverColors.blueTint),
      greaterThanOrEqualTo(4.5),
    );
    handle.dispose();
  });

  testWidgets('MooverAvatar: spasi ganda tidak error, dekoratif', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: MooverAvatar(
          name: ' satu  dua tiga ',
          size: 40,
          ring: 2,
          border: MooverColors.surface,
        ),
      ),
    );
    expect(find.text('SD'), findsOneWidget);
    expect(find.bySemanticsLabel('SD'), findsNothing);
    handle.dispose();
  });

  testWidgets('320dp + teks 200%: tanpa overflow', (tester) async {
    tester.view
      ..physicalSize = const Size(960, 1704)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(textScale: 2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
