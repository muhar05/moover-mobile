part of 'main_menu_screen.dart';

// ponytail: versi disalin manual dari pubspec.yaml (version 0.1.0+1), tanpa
// package_info_plus (dependency baru). Ganti bila versi perlu otomatis.
const appVersion = '0.1.0';

typedef _Menu = (IconData icon, String title, String subtitle);

/// S17 Akun. Gabungan menu DESIGN.md S17 dan V2.1 Settings (keputusan
/// pemilik project 2026-10-10, belum di DESIGN.md): grup Akun dan Bantuan,
/// judul tetap "Akun", email fiktif, versi hardcode. Penempatan Kendaraan dan
/// Time Log di grup Akun: Usulan aktif.
class _AccountTab extends StatelessWidget {
  const _AccountTab();

  static const _account = <_Menu>[
    (LucideIcons.user, 'Informasi profil', 'Nama, email, dan foto'),
    (LucideIcons.lock, 'Ubah kata sandi', 'Perbarui kata sandi akun'),
    (LucideIcons.car, 'Kendaraan', 'Model, nomor polisi, kapasitas'),
    (LucideIcons.history, 'Time Log', 'Riwayat clock-in dan clock-out'),
  ];
  static const _support = <_Menu>[
    (LucideIcons.circleHelp, 'Bantuan & FAQ', 'Jawaban pertanyaan umum'),
    (LucideIcons.headset, 'Hubungi support', 'WhatsApp, email, atau telepon'),
  ];

  Future<void> _logout(BuildContext context) async {
    final textTheme = Theme.of(context).textTheme;
    // V2.1: sheet bawah, bukan dialog. Tombol tinggi 54, radius 16.
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(MooverRadius.md),
    );
    final ok = await showModalBottomSheet<bool>(
      context: context,
      // Tinggi mengikuti isi (teks 200% melebihi batas 9/16 bawaan).
      isScrollControlled: true,
      backgroundColor: MooverColors.surface,
      shape: const RoundedRectangleBorder(
        // V2.1: 28, komposisi optik sheet (di atas lg).
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          MooverSpace.screen,
          MooverSpace.xl,
          MooverSpace.screen,
          MooverSpace.xl + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: MooverSpace.md,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: StatusTone.err.background,
                borderRadius: BorderRadius.circular(MooverRadius.card),
              ),
              child: Icon(
                LucideIcons.logOut,
                size: 30,
                color: StatusTone.err.foreground,
              ),
            ),
            Semantics(
              header: true,
              child: Text(
                'Keluar dari Moover?',
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 290), // V2.1
              child: Text(
                'Pastikan Anda sudah clock-out. Anda memerlukan Employee ID '
                'untuk masuk kembali.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 14.5,
                  height: 1.5,
                  color: MooverColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: MooverSpace.xs),
            Row(
              spacing: 10, // V2.1
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      shape: buttonShape,
                      foregroundColor: MooverColors.text,
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                Expanded(
                  // Putih di err 6,54:1.
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      shape: buttonShape,
                      backgroundColor: StatusTone.err.foreground,
                      foregroundColor: MooverColors.surface,
                      textStyle: textTheme.titleSmall?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: const Text('Keluar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    // DESIGN.md S02: Login dimasuki dari Landing atau logout. Tidak ada sesi
    // tersimpan yang perlu dihapus.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(MooverRadius.lg);
    return _TabPage(
      // V2.1 Settings: judul putih di navy, kartu profil menumpang 52dp di
      // tepi bawah header.
      header: _NavyHeader(
        markTop: 20,
        overlap: Card(
          // Bayangan V2.1 (dekoratif): kartu berada di atas dua latar.
          elevation: 8,
          shadowColor: MooverColors.navy.withValues(alpha: 0.3),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: radius),
          child: MergeSemantics(
            child: Semantics(
              button: true,
              child: InkWell(
                onTap: () => _notYet(context, 'Informasi profil'),
                child: Padding(
                  padding: const EdgeInsets.all(MooverSpace.lg),
                  child: Row(
                    spacing: 14,
                    children: [
                      const _Avatar(
                        size: 64,
                        ring: 3,
                        border: MooverColors.surface,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 3,
                          children: [
                            Text(
                              demoDriverName,
                              style: textTheme.titleMedium?.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              demoDriverEmail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium?.copyWith(
                                fontSize: 13,
                                color: MooverColors.textMuted,
                              ),
                            ),
                            // Chip peran + kendaraan, tone live 6,9:1.
                            Container(
                              margin: const EdgeInsets.only(
                                top: MooverSpace.xs,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9, // V2.1
                                vertical: 3,
                              ),
                              decoration: ShapeDecoration(
                                color: StatusTone.live.background,
                                shape: const StadiumBorder(),
                              ),
                              child: Text(
                                'Driver · ${vehicle.model}',
                                style: textTheme.labelMedium?.copyWith(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0,
                                  color: StatusTone.live.foreground,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        LucideIcons.chevronRight,
                        color: MooverColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    'Akun',
                    style: _titleStyle(context)
                        ?.copyWith(color: MooverColors.surface),
                  ),
                ),
              ),
              Image.asset(
                'assets/brand/moover-logo-reverse.png',
                height: 18,
                opacity: const AlwaysStoppedAnimation(0.8),
                semanticLabel: 'Moover',
              ),
            ],
          ),
        ],
      ),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 18, // V2.1: jarak antargrup
          children: [
            const _MenuGroup('Akun', StatusTone.info, _account),
            const _MenuGroup('Bantuan', StatusTone.live, _support),
            // V2.1 "Log out": tint err + label err (5,86:1), tinggi 52. Varian
            // destructive umum tetap Belum ditentukan; gaya ini khusus logout.
            FilledButton.icon(
              onPressed: () => _logout(context),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: StatusTone.err.background,
                foregroundColor: StatusTone.err.foreground,
                textStyle: textTheme.titleSmall?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              icon: const Icon(LucideIcons.logOut),
              label: const Text('Keluar'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: MooverSpace.sm,
              children: [
                const SizedBox(height: 14, child: MooverMark(opacity: 1)),
                Flexible(
                  child: Text(
                    'Moover v$appVersion',
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 11.5,
                      color: MooverColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// Grup menu V2.1 Settings: judul kapital kecil, kotak putih bertepi
/// hairline, baris ikon + judul + keterangan + chevron. Tiap baris satu
/// tombol bagi pembaca layar.
class _MenuGroup extends StatelessWidget {
  const _MenuGroup(this.title, this.tone, this.items);

  final String title;
  final StatusTone tone;
  final List<_Menu> items;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: MooverSpace.sm,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6), // V2.1
          child: Semantics(
            header: true,
            child: Text(
              title.toUpperCase(),
              // Dibaca sebagai kata, bukan dieja.
              semanticsLabel: title,
              style: textTheme.labelMedium?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.72,
                color: MooverColors.textMuted,
              ),
            ),
          ),
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, (icon, label, sub)) in items.indexed) ...[
                if (i > 0) const Divider(height: 1),
                MergeSemantics(
                  child: Semantics(
                    button: true,
                    child: InkWell(
                      onTap: () => _notYet(context, label),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: MooverSpace.lg,
                          vertical: 14, // V2.1
                        ),
                        child: Row(
                          spacing: 14,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: tone.background,
                                borderRadius: BorderRadius.circular(
                                  MooverRadius.sm,
                                ),
                              ),
                              child: Icon(
                                icon,
                                size: 20,
                                color: tone.foreground,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: 1,
                                children: [
                                  Text(
                                    label,
                                    style: textTheme.titleSmall?.copyWith(
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    sub,
                                    style: textTheme.bodySmall?.copyWith(
                                      fontSize: 12.5,
                                      color: MooverColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              LucideIcons.chevronRight,
                              size: 18,
                              color: MooverColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
