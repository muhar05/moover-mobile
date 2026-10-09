import 'package:flutter/material.dart';

import 'theme.dart';

/// Logo Moover. File dipilih pemilik project (2026-10-09):
/// `assets/brand/moover-logo.png`.
class MooverLogo extends StatelessWidget {
  const MooverLogo({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/brand/moover-logo.png',
    height: height,
    semanticLabel: 'Moover',
  );
}

/// Tombol aksi utama. Disetujui (D10): saat [busy], spinner tampil dan tombol
/// tidak bisa ditekan sampai ada respons.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final text = Text(label);
    if (busy) {
      return FilledButton.icon(
        onPressed: null,
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
    if (icon != null) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: text,
      );
    }
    return FilledButton(onPressed: onPressed, child: text);
  }
}

/// Badge status. Disetujui (D7): selalu teks + warna.
/// Ukuran (tinggi ≥24dp, teks ≥12sp): Usulan aktif (UD3).
/// [label] diisi pemanggil; pemetaan kode status → label (§4.7) belum ada.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.tone});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      // ponytail: padding belum ditentukan di DESIGN.md; ganti saat ada token spacing.
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: ShapeDecoration(
        color: tone.background,
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: tone.foreground,
        ),
      ),
    );
  }
}

/// Disetujui (D10): pesan jelas + "Coba lagi".
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _StateMessage(
    icon: Icons.error_outline,
    message: message,
    action: OutlinedButton(onPressed: onRetry, child: const Text('Coba lagi')),
  );
}

/// Disetujui (D10): satu kalimat; aksi hanya jika relevan.
/// Ikon + teks: Usulan aktif (UD3).
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) =>
      _StateMessage(icon: icon, message: message, action: action);
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.icon, required this.message, this.action});

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

/// Disetujui (D10): skeleton saat loading. Statis karena animasi loading
/// Belum ditentukan. Disembunyikan dari pembaca layar; layar pemanggil
/// bertanggung jawab memberi label "Memuat".
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, required this.height});

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
    ),
  );
}

/// Disetujui (D10): penanda layar yang memakai data mock.
/// Warna memakai kandidat tone warn (belum final, D6).
class MockDataBanner extends StatelessWidget {
  const MockDataBanner({super.key});

  @override
  Widget build(BuildContext context) {
    const tone = StatusTone.warn;
    return Container(
      width: double.infinity,
      color: tone.background,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: tone.foreground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Data contoh',
              style: TextStyle(
                color: tone.foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
