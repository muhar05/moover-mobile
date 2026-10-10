import 'package:flutter/material.dart';

import '../themes/theme.dart';

/// Rute asal–tujuan: titik isi (asal) dan cincin (tujuan) dihubungkan garis
/// vertikal; nama lokasi di samping titik, boleh membungkus beberapa baris.
/// Dibaca pembaca layar sebagai satu kalimat "Dari … ke …"; titik dan garis
/// dekoratif tidak dibaca.
///
/// Kontras (hitungan WCAG) di latar halaman / kartu putih: teks ≥17:1,
/// titik g900 ≥8:1, garis g500 ≥4,1:1. [onDark] (kartu g700–g900): teks
/// putih ≥6,61:1, titik dan garis g100 ≥4,61:1 (g300 hanya 2,75:1 di g700).
class MooverRouteTimeline extends StatelessWidget {
  const MooverRouteTimeline({
    super.key,
    required this.origin,
    required this.destination,
    this.onDark = false,
    this.style,
  });

  final String origin;
  final String destination;
  final bool onDark;

  /// Gaya nama lokasi; bawaan bodyLarge w500. Warna ditentukan [onDark].
  final TextStyle? style;

  static const _dot = 10.0, _rail = 16.0, _gap = MooverSpace.md;

  @override
  Widget build(BuildContext context) {
    final base =
        style ??
        Theme.of(context).textTheme.bodyLarge!
            .copyWith(fontWeight: FontWeight.w500);
    final textStyle = base.copyWith(
      color: onDark ? MooverColors.surface : MooverColors.text,
    );
    final dotColor = onDark ? MooverColors.g100 : MooverColors.g900;
    final lineColor = onDark ? MooverColors.g100 : MooverColors.g500;
    // Titik di tengah baris pertama teks, berapa pun skala teks OS.
    final lineHeight = MediaQuery.textScalerOf(context)
        .scale((base.fontSize ?? 16) * (base.height ?? 1.4));
    final above = (lineHeight - _dot) / 2;
    Widget line([double? height]) => Container(
      width: 2,
      height: height,
      decoration: BoxDecoration(
        color: lineColor,
        borderRadius: BorderRadius.circular(1),
      ),
    );

    return Semantics(
      label: 'Dari $origin ke $destination',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: _rail,
                  child: Column(
                    children: [
                      SizedBox(height: above),
                      Container(
                        width: _dot,
                        height: _dot,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(child: line()),
                    ],
                  ),
                ),
                const SizedBox(width: _gap),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: MooverSpace.sm),
                    child: Text(origin, style: textStyle),
                  ),
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _rail,
                child: Column(
                  children: [
                    line(above),
                    Container(
                      width: _dot,
                      height: _dot,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: dotColor, width: 2),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: _gap),
              Expanded(child: Text(destination, style: textStyle)),
            ],
          ),
        ],
      ),
    );
  }
}
