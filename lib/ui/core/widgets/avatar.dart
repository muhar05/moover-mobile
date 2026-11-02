import 'package:flutter/material.dart';

import '../themes/theme.dart';

/// Avatar inisial [name] dengan ring gradient blue700 → cyan (V2.1) dan tepi
/// [border]. Dekoratif (nama ditulis di sebelahnya); inisial blue700 di
/// blueTint 6,67:1. Foto driver: Belum ditentukan (Q-B6, tidak ada data).
class MooverAvatar extends StatelessWidget {
  const MooverAvatar({
    super.key,
    required this.name,
    required this.size,
    required this.ring,
    required this.border,
  });

  final String name;
  final double size;
  final double ring;
  final Color border;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join()
        .toUpperCase();
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(ring),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [MooverColors.blue700, MooverColors.cyan],
          ),
        ),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: MooverColors.blueTint,
            border: Border.all(color: border, width: 2),
          ),
          child: FittedBox(
            child: Text(
              initials,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: MooverColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
