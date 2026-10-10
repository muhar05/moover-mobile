import 'package:flutter/material.dart';

import '../themes/theme.dart';

/// Tombol aksi utama. Disetujui (D10): saat [busy], spinner tampil dan tombol
/// tidak bisa ditekan sampai ada respons.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final text = Text(label);
    if (busy) {
      return FilledButton.icon(
        onPressed: null,
        // Usulan aktif (audit tombol 2026-10-10): busy = sedang diproses,
        // label tetap terbaca. Teks di atas g100 13,2:1; spinner (primary)
        // 6,02:1. Nonaktif lain tetap bawaan M3.
        style: FilledButton.styleFrom(
          disabledBackgroundColor: MooverColors.g100,
          disabledForegroundColor: MooverColors.text,
        ),
        icon: const SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            semanticsLabel: 'Memproses',
          ),
        ),
        label: text,
      );
    }
    return FilledButton(onPressed: onPressed, child: text);
  }
}
