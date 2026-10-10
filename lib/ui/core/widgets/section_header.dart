import 'package:flutter/material.dart';

import '../themes/theme.dart';

/// Judul bagian: teks tebal, [trailing] opsional (mis. jumlah item) muted.
/// V2.1 (2026-10-10): judul 18/w800, trailing 13/w600.
class MooverSectionHeader extends StatelessWidget {
  const MooverSectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      header: true,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: textTheme.labelLarge?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: MooverColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}
