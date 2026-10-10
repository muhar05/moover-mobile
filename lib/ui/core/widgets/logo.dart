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
