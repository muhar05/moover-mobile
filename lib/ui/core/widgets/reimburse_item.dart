import 'package:flutter/material.dart';

import '../themes/theme.dart';
import 'spread.dart';
import 'status_badge.dart';

/// Kartu pengajuan reimburse (dipakai di Beranda dan tab Reimburse): ikon
/// kategori, kategori + nominal, tanggal + badge status. Kartu sendiri seperti
/// [MooverTripItem]; dibaca TalkBack sebagai satu item.
class MooverReimburseItem extends StatelessWidget {
  const MooverReimburseItem({
    super.key,
    required this.category,
    required this.icon,
    required this.amount,
    required this.date,
    required this.status,
    required this.tone,
  });

  final String category;
  final IconData icon;
  final String amount;
  final String date;
  final String status;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(MooverSpace.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // V2.1: tile ikon 40, radius 12, blueTint (ikon primary 6,67:1).
              ExcludeSemantics(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: MooverColors.blueTint,
                    borderRadius: BorderRadius.circular(MooverRadius.sm),
                  ),
                  child: Icon(icon, size: 20, color: MooverColors.primary),
                ),
              ),
              const SizedBox(width: MooverSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: MooverSpace.xs,
                  children: [
                    spread(
                      Text(category, style: textTheme.titleSmall),
                      Text(
                        amount,
                        style: textTheme.titleMedium?.copyWith(
                          fontFeatures: tabularFigures, // D2
                        ),
                      ),
                    ),
                    spread(
                      Text(
                        date,
                        style: textTheme.bodySmall?.copyWith(
                          color: MooverColors.textMuted,
                        ),
                      ),
                      StatusBadge(label: status, tone: tone),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
