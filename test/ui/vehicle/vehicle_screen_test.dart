import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moover/ui/core/themes/theme.dart';
import 'package:moover/ui/core/widgets/widgets.dart';
import 'package:moover/ui/main_menu/mock_data.dart';
import 'package:moover/ui/vehicle/vehicle_screen.dart';

import '../core/design_system_test.dart' show contrast;

// Nilai non-mock: terbukti datang dari parameter.
const sample = (
  model: 'Mobil Uji',
  plate: 'B 9 UJI',
  capacity: '4 kursi',
  image: 'assets/images/vehicles/vehicle-placeholder.jpg',
);

Widget app(Vehicle? v, {double textScale = 1}) => MaterialApp(
  theme: mooverTheme(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: VehicleScreen(vehicle: v),
);

void main() {
  testWidgets('S19: model, nomor polisi, kapasitas; dibaca per baris', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(app(sample));
    expect(find.text('Kendaraan'), findsOneWidget); // judul
    for (final (label, value) in [
      ('Model', sample.model),
      ('Nomor polisi', sample.plate),
      ('Kapasitas', sample.capacity),
    ]) {
      expect(
        tester.getSemantics(find.text(label)),
        isSemantics(label: '$label\n$value'),
        reason: label,
      );
    }
    // Foto dekoratif: tidak dibaca.
    expect(
      tester.widget<Image>(find.byType(Image)).excludeFromSemantics,
      isTrue,
    );
    expect(find.byType(EmptyView), findsNothing);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    expect(
      contrast(MooverColors.textMuted, MooverColors.surface),
      greaterThanOrEqualTo(4.5),
    );
    handle.dispose();
  });

  testWidgets('S19 tanpa kendaraan: Belum ada kendaraan', (tester) async {
    await tester.pumpWidget(app(null));
    expect(find.byType(EmptyView), findsOneWidget);
    expect(find.text('Belum ada kendaraan.'), findsOneWidget);
    expect(find.text('Nomor polisi'), findsNothing);
  });

  testWidgets('320dp + teks 200%: tanpa overflow', (tester) async {
    tester.view
      ..physicalSize = const Size(960, 1704)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    for (final v in [sample, null]) {
      await tester.pumpWidget(app(v, textScale: 2));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$v');
    }
  });
}
