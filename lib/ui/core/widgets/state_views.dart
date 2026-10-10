import 'package:flutter/material.dart';

import '../themes/theme.dart';

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
      padding: const EdgeInsets.all(MooverSpace.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: MooverSpace.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          if (action != null) ...[
            const SizedBox(height: MooverSpace.lg),
            action!,
          ],
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
