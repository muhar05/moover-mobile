import 'package:flutter/material.dart';

import '../themes/theme.dart';

/// Baris yang sejajar kiri-kanan bila muat, turun ke baris baru bila tidak
/// (teks 200% di layar 320dp).
Widget spread(Widget start, Widget end) => Wrap(
  alignment: WrapAlignment.spaceBetween,
  crossAxisAlignment: WrapCrossAlignment.center,
  spacing: MooverSpace.sm,
  runSpacing: 6,
  children: [start, end],
);
