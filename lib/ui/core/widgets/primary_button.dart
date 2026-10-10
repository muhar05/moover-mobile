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
        // label tetap terbaca. Teks di atas blueTint 15,6:1; spinner
        // (primary) 6,67:1. Nonaktif lain mengikuti tema (V2.1 disabled).
        style: FilledButton.styleFrom(
          disabledBackgroundColor: MooverColors.blueTint,
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
