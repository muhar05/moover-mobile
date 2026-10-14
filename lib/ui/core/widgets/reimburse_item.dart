import 'package:flutter/material.dart';

import '../themes/theme.dart';
import 'spread.dart';
import 'status_badge.dart';

/// Kartu pengajuan reimburse (dipakai di Beranda dan tab Reimburse): ikon
/// kategori, kategori + nominal, tanggal + badge status. Kartu sendiri seperti
/// [MooverTripItem]; dibaca TalkBack sebagai satu item. [number] nomor
/// reimburse (S14); [onTap] buka detail (S16), null = hanya tampil.
class MooverReimburseItem extends StatelessWidget {
  const MooverReimburseItem({
    super.key,
    required this.category,
    required this.icon,
    required this.amount,
    required this.date,
    required this.status,
    required this.tone,
    this.number,
    this.onTap,
  });

  final String category;
  final IconData icon;
  final String amount;
  final String date;
  final String status;
  final StatusTone tone;
  final String? number;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Card(
        clipBehavior: Clip.antiAlias, // riak InkWell ikut sudut kartu
        child: InkWell(
          onTap: onTap,
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
                      if (number case final number?)
                        Text(
                          number,
                          style: textTheme.bodySmall?.copyWith(
                            color: MooverColors.textMuted,
                            fontFeatures: tabularFigures,
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
      ),
    );
  }
}
