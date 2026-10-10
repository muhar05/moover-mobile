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

typedef MooverNavItem = ({String label, IconData icon, IconData selectedIcon});

/// Navigasi bawah Moover: bar putih mengambang, tab aktif ditandai pill
/// Glacier Mist di ikon, label tebal, dan garis teal (3,02:1, nonteks).
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
              color: MooverColors.abyss.withValues(alpha: 0.08),
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
                      color: MooverColors.mist.withValues(
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
                      color: MooverColors.teal,
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

/// Judul bagian: teks tebal, [trailing] opsional (mis. jumlah item) muted.
class MooverSectionHeader extends StatelessWidget {
  const MooverSectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      header: true,
      child: Row(
        children: [
          Expanded(child: Text(title, style: textTheme.titleMedium)),
          if (trailing != null)
            Text(
              trailing!,
              style: textTheme.labelLarge?.copyWith(
                color: MooverColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}

/// Rute asal–tujuan: titik isi (asal) dan cincin (tujuan) dihubungkan garis
/// vertikal; nama lokasi di samping titik, boleh membungkus beberapa baris.
/// Dibaca pembaca layar sebagai satu kalimat "Dari … ke …"; titik dan garis
/// dekoratif tidak dibaca.
///
/// Kontras (hitungan WCAG) di latar halaman / kartu putih: teks abyss ≥16:1,
/// titik steel ≥8:1. [onDark] (kartu steel): teks putih 8,76:1, titik mist
/// 6,60:1, garis surf 4,62:1. Garis teal di latar terang 2,81:1: dekoratif,
/// penanda asal/tujuan adalah titik dan teks.
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
    final dotColor = onDark ? MooverColors.mist : MooverColors.steel;
    final lineColor = onDark ? MooverColors.surf : MooverColors.teal;
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

/// Item trip tanpa kartu: langsung di latar halaman, dipisah hairline oleh
/// pemanggil. Hierarki: waktu (+ badge, turun baris bila tidak muat), rute
/// ([MooverRouteTimeline]), penumpang (opsional, muted 6,00:1 di latar). Dibaca TalkBack sebagai satu
/// item.
class MooverTripItem extends StatelessWidget {
  const MooverTripItem({
    super.key,
    required this.time,
    required this.origin,
    required this.destination,
    required this.status,
    required this.tone,
    this.passengers,
  });

  final String time;
  final String origin;
  final String destination;
  final String status;
  final StatusTone tone;
  final String? passengers;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: MooverSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: MooverSpace.sm,
              runSpacing: 6,
              children: [
                Text(
                  time,
                  style: textTheme.titleLarge?.copyWith(
                    fontFeatures: tabularFigures, // D2
                  ),
                ),
                StatusBadge(label: status, tone: tone),
              ],
            ),
            // 10/6: komposisi optik waktu–rute–penumpang (sama dengan Agenda).
            const SizedBox(height: 10),
            MooverRouteTimeline(origin: origin, destination: destination),
            if (passengers != null) ...[
              const SizedBox(height: 6),
              Text(
                passengers!,
                style: textTheme.bodyMedium?.copyWith(
                  color: MooverColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Baris yang sejajar kiri-kanan bila muat, turun ke baris baru bila tidak
/// (teks 200% di layar 320dp).
Widget _spread(Widget start, Widget end) => Wrap(
  alignment: WrapAlignment.spaceBetween,
  crossAxisAlignment: WrapCrossAlignment.center,
  spacing: MooverSpace.sm,
  runSpacing: 6,
  children: [start, end],
);

/// Kartu Agenda Hari Ini: satu-satunya blok berwarna di Beranda.
/// Gradient steel → abyss; kontras terendah ada di ujung steel: putih
/// 8,76:1, mist 6,60:1. Status clock-in: abyss di atas pill mist 13,6:1.
/// Hanya menampilkan status; tidak ada aksi clock-in (aturan belum ada).
class MooverAgendaCard extends StatelessWidget {
  const MooverAgendaCard({
    super.key,
    required this.tripCount,
    required this.nextTime,
    required this.origin,
    required this.destination,
    required this.clockInStatus,
    required this.operatingHours,
  });

  final int tripCount;
  final String nextTime;
  final String origin;
  final String destination;
  final String clockInStatus;
  final String operatingHours;

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [MooverColors.steel, MooverColors.abyss],
  );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const onCard = MooverColors.surface;
    const muted = MooverColors.mist;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(MooverRadius.card),
      ),
      // 18 di atas: kompensasi optik line height label; 20 = padding kartu.
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _spread(
              Text(
                'Agenda hari ini',
                style: textTheme.labelLarge?.copyWith(color: muted),
              ),
              Text(
                '$tripCount trip',
                style: textTheme.titleSmall?.copyWith(color: onCard),
              ),
            ),
            const SizedBox(height: MooverSpace.lg),
            MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Berikutnya',
                    style: textTheme.labelMedium?.copyWith(color: muted),
                  ),
                  // Ukuran sama dengan waktu di MooverTripItem.
                  Text(
                    nextTime,
                    style: textTheme.titleLarge?.copyWith(
                      color: onCard,
                      fontFeatures: tabularFigures, // D2
                    ),
                  ),
                  const SizedBox(height: 10),
                  MooverRouteTimeline(
                    origin: origin,
                    destination: destination,
                    onDark: true,
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            // Satu-satunya aksen teal (dekoratif).
            Padding(
              padding: const EdgeInsets.symmetric(vertical: MooverSpace.lg),
              child: Divider(
                height: 1,
                color: MooverColors.teal.withValues(alpha: 0.5),
              ),
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: MooverSpace.md,
              runSpacing: MooverSpace.sm,
              children: [
                DecoratedBox(
                  decoration: const ShapeDecoration(
                    color: muted,
                    shape: StadiumBorder(),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MooverSpace.md,
                      vertical: 6, // pill ringkas, sama dengan badge
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const ExcludeSemantics(
                          child: Icon(
                            Icons.schedule,
                            size: 18,
                            color: MooverColors.abyss,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            clockInStatus,
                            style: textTheme.labelLarge?.copyWith(
                              color: MooverColors.abyss,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  operatingHours,
                  style: textTheme.bodySmall?.copyWith(
                    color: muted,
                    fontFeatures: tabularFigures,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Baris pengajuan reimburse (dipakai di Beranda dan tab Reimburse):
/// ikon kategori, kategori + nominal, tanggal + badge status.
class MooverReimburseItem extends StatelessWidget {
  const MooverReimburseItem({
    super.key,
    required this.category,
    required this.icon,
    required this.amount,
    required this.date,
    required this.status,
    required this.tone,
  });

  final String category;
  final IconData icon;
  final String amount;
  final String date;
  final String status;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(MooverSpace.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: CircleAvatar(
              radius: 20,
              backgroundColor: MooverColors.background,
              foregroundColor: MooverColors.primary,
              child: Icon(icon, size: 20),
            ),
          ),
          const SizedBox(width: MooverSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: MooverSpace.xs,
              children: [
                _spread(
                  Text(category, style: textTheme.titleSmall),
                  Text(
                    amount,
                    style: textTheme.titleMedium?.copyWith(
                      fontFeatures: tabularFigures, // D2
                    ),
                  ),
                ),
                _spread(
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
    );
  }
}

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
        // label tetap terbaca. Abyss di atas mist 13,6:1; spinner (steel)
        // 6,60:1. Nonaktif lain tetap bawaan M3.
        style: FilledButton.styleFrom(
          disabledBackgroundColor: MooverColors.mist,
          disabledForegroundColor: MooverColors.abyss,
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
      // Usulan aktif: 10 horizontal sengaja di luar skala (pill ringkas).
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: MooverSpace.xs,
      ),
      decoration: ShapeDecoration(
        color: tone.background,
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        // labelMedium 12sp (UD3: ≥12sp). w600: pengecualian yang disengaja,
        // bukan peran judul (w700).
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(fontWeight: FontWeight.w600, color: tone.foreground),
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
