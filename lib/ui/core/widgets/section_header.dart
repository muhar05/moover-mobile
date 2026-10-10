import 'package:flutter/material.dart';

import '../themes/theme.dart';

/// Judul bagian: teks tebal, [trailing] opsional (mis. jumlah item) muted.
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
          Expanded(child: Text(title, style: textTheme.titleMedium)),
          if (trailing != null)
            Text(
              trailing!,
              style: textTheme.labelLarge?.copyWith(
                color: MooverColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}
