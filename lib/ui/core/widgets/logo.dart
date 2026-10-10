import 'package:flutter/material.dart';

/// Logo Moover. File dipilih pemilik project (2026-10-09):
/// `assets/brand/moover-logo.png`.
class MooverLogo extends StatelessWidget {
  const MooverLogo({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/brand/moover-logo.png',
    height: height,
    semanticLabel: 'Moover',
  );
}

/// Tanda loop Moover sebagai watermark dekoratif header navy (V2.1,
/// 2026-10-10): `assets/brand/moover-mark.png`. Tidak dibaca pembaca layar.
class MooverMark extends StatelessWidget {
  const MooverMark({super.key, required this.opacity});

  final double opacity;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/brand/moover-mark.png',
    opacity: AlwaysStoppedAnimation(opacity),
    excludeFromSemantics: true,
  );
}
