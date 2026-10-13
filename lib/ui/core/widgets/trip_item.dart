import 'package:flutter/material.dart';

import '../themes/theme.dart';
import 'route_timeline.dart';
import 'status_badge.dart';

/// Kartu trip V2.1 (2026-10-10): kartu putih bertepi hairline (tema Card),
/// kolom waktu 54dp (ikut skala teks) dengan garis pemisah, lalu badge
/// (+ "Berikutnya" bila [next]), tujuan, penumpang (opsional, muted 6,13:1 di
/// putih). Dibaca TalkBack sebagai satu item.
/// Tujuan mengikuti V2.1 (keputusan pemilik project 2026-10-10): dengan
/// [origin] = rute [MooverRouteTimeline] (Riwayat); tanpa [origin] = nama
/// tempat tebal + [address] muted maks. 2 baris (Jadwal hari ini, Home V2.1).
/// ponytail: pemisah V2 putus-putus diganti garis solid hairline; tambahkan
/// CustomPainter bila diminta. Chip "NEXT" V2 dipindah ke kolom kanan
/// sebagai badge info: "Berikutnya" tidak muat di kolom 54dp.
/// [onTap]: kartu bisa diketuk (buka S07); null = hanya tampil.
class MooverTripItem extends StatelessWidget {
  const MooverTripItem({
    super.key,
    required this.time,
    this.origin,
    required this.destination,
    this.address,
    required this.status,
    required this.tone,
    this.passengers,
    this.next = false,
    this.onTap,
  });

  final String time;
  final String? origin;
  final String destination;
  final String? address;
  final String status;
  final StatusTone tone;
  final String? passengers;
  final bool next;
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
            // V2.1: 14 14 14 16.
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 14,
                children: [
                  // 54 isi (V2.1) + 8 jarak ke garis; ikut skala teks agar
                  // "09.30" tidak terpotong di tengah angka.
                  Container(
                    width: MediaQuery.textScalerOf(context).scale(62),
                    padding: const EdgeInsets.only(right: MooverSpace.sm),
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: MooverColors.hairline),
                      ),
                    ),
                    child: Text(
                      time,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFeatures: tabularFigures, // D2
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 10, // komposisi optik badge–rute–penumpang
                      children: [
                        Wrap(
                          spacing: MooverSpace.sm,
                          runSpacing: 6,
                          children: [
                            if (next)
                              const StatusBadge(
                                label: 'Berikutnya',
                                tone: StatusTone.info,
                              ),
                            StatusBadge(label: status, tone: tone),
                          ],
                        ),
                        if (origin case final origin?)
                          MooverRouteTimeline(
                            origin: origin,
                            destination: destination,
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: MooverSpace.xs,
                            children: [
                              // V2.1: 15/w800.
                              Text(
                                destination,
                                semanticsLabel: 'Ke $destination',
                                style: textTheme.titleSmall?.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (address != null)
                                Text(
                                  address!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodySmall?.copyWith(
                                    fontSize: 12.5, // V2.1
                                    height: 1.45,
                                    color: MooverColors.textMuted,
                                  ),
                                ),
                            ],
                          ),
                        if (passengers != null)
                          Text(
                            passengers!,
                            style: textTheme.bodySmall?.copyWith(
                              color: MooverColors.textMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
