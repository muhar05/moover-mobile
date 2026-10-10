import 'package:flutter/material.dart';

import '../themes/theme.dart';

typedef MooverNavItem = ({String label, IconData icon, IconData selectedIcon});

/// Navigasi bawah Moover: bar putih mengambang, tab aktif ditandai pill g100
/// di ikon (teks 13,2:1), label tebal, dan garis g500 (4,38:1, nonteks).
/// Label dibatasi 130% seperti NavigationBar M3 agar empat tab muat di layar
/// 320dp; teks konten tetap mengikuti skala OS. Reduced motion: tanpa animasi.
class MooverBottomNavigation extends StatelessWidget {
  const MooverBottomNavigation({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<MooverNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);
    final radius = BorderRadius.circular(MooverRadius.lg);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        MooverSpace.md,
        0,
        MooverSpace.md,
        MooverSpace.md,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: MooverColors.text.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: MooverColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: const BorderSide(color: MooverColors.hairline),
          ),
          clipBehavior: Clip.antiAlias,
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: Row(
              children: [
                for (final (i, item) in items.indexed)
                  Expanded(
                    child: _NavButton(
                      item: item,
                      selected: i == selectedIndex,
                      duration: duration,
                      onTap: () => onSelected(i),
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

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.duration,
    required this.onTap,
  });

  final MooverNavItem item;
  final bool selected;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? MooverColors.text : MooverColors.textMuted;
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: selected,
        inMutuallyExclusiveGroup: true,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    width: selected ? 56 : 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: MooverColors.g100.withValues(
                        alpha: selected ? 1 : 0,
                      ),
                      borderRadius: BorderRadius.circular(MooverRadius.md),
                    ),
                    child: Icon(
                      selected ? item.selectedIcon : item.icon,
                      size: 22,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: MooverSpace.xs),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.label,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(height: MooverSpace.xs),
                  AnimatedContainer(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    width: selected ? 16 : 0,
                    height: 3,
                    decoration: BoxDecoration(
                      color: MooverColors.g500,
                      borderRadius: BorderRadius.circular(2),
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
