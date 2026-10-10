import 'package:flutter/material.dart';

import '../themes/theme.dart';

typedef MooverNavItem = ({String label, IconData icon, IconData selectedIcon});

/// Navigasi bawah Moover (V2.1, 2026-10-10): bar putih menempel di bawah,
/// tepi atas hairline, tanpa bayangan. Tab aktif: pill blueTint 56×30 di
/// ikon (primary 6,67:1), label primary w800 (7,59:1); tak aktif textMuted
/// w600 (6,13:1).
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
        : const Duration(milliseconds: 200);
    return Material(
      color: MooverColors.surface,
      shape: const Border(top: BorderSide(color: MooverColors.hairline)),
      child: SafeArea(
        top: false,
        child: Padding(
          // V2.1: 6 atas, 8 samping, 12 bawah (+ safe area).
          padding: const EdgeInsets.fromLTRB(
            MooverSpace.sm,
            6,
            MooverSpace.sm,
            MooverSpace.md,
          ),
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
    final color = selected ? MooverColors.primary : MooverColors.textMuted;
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: selected,
        inMutuallyExclusiveGroup: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(MooverRadius.md),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  width: 56,
                  height: 30,
                  decoration: BoxDecoration(
                    color: MooverColors.blueTint.withValues(
                      alpha: selected ? 1 : 0,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    selected ? item.selectedIcon : item.icon,
                    size: 22,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3), // V2.1: jarak ikon–label
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    // labelSmall 11sp (V2.1).
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: color,
                    ),
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
