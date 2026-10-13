part of 'main_menu_screen.dart';

/// Tab Trip mengikuti V2.1 "Trip tab" (keputusan pemilik project
/// 2026-10-10, belum di DESIGN.md): status Available, kartu trip tambahan,
/// jenis trip tambahan, kendaraan, tips, lalu Riwayat (S12). Segmen "Hari
/// ini" dihapus: jadwal hari ini sudah di Beranda. V2.1 memakai toggle
/// Available manual; di sini Available = clock-in, belum clock-out (keputusan
/// 2026-10-10), jadwal hanya ditampilkan.
class _TripTab extends StatelessWidget {
  const _TripTab();

  // MOCK/DEMO. ponytail: form Add New Trip (S11) belum dibuat (Q-B1);
  // ganti dengan navigasi ke S11 saat aturannya dikonfirmasi.
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([clockIn, clockOut]),
    builder: (context, _) => _build(
      context,
      clockedIn: clockIn.value != null && clockOut.value == null,
    ),
  );

  Widget _build(BuildContext context, {required bool clockedIn}) {
    final textTheme = Theme.of(context).textTheme;
    return _TabPage(
      header: Padding(
        padding: EdgeInsets.fromLTRB(
          MooverSpace.screen,
          _topInset(context),
          MooverSpace.screen,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6, // V2.1
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: MooverSpace.md,
              runSpacing: MooverSpace.sm,
              children: [
                Semantics(
                  header: true,
                  child: Text('Trip', style: _titleStyle(context)),
                ),
                // D7: teks + warna. Bukan toggle (Available mengikuti
                // clock-in).
                clockedIn
                    ? const StatusBadge(label: 'Available', tone: StatusTone.ok)
                    : const StatusBadge(
                        label: 'Tidak bertugas',
                        tone: StatusTone.neutral,
                      ),
              ],
            ),
            Text(
              clockedIn
                  ? 'Anda siap menerima trip tambahan.'
                  : 'Status Available aktif setelah clock-in.',
              style: textTheme.bodyMedium?.copyWith(
                color: MooverColors.textMuted,
              ),
            ),
          ],
        ),
      ),
      children: [
        MooverExtraTripCard(
          available: clockedIn,
          onAdd: () => _notYet(context, 'Form trip baru'),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: MooverSpace.md,
          children: [
            const MooverSectionHeader('Trip tambahan untuk'),
            // V2.1: tiga tile tautan ke Add Trip. Di sini informasi saja
            // (tanpa aksi): satu jalur ke form, lewat tombol di kartu.
            LayoutBuilder(
              builder: (context, constraints) {
                const tiles = [
                  _ReasonTile(
                    LucideIcons.timer,
                    'Antar-jemput mendadak',
                    StatusTone.info,
                  ),
                  _ReasonTile(
                    LucideIcons.mapPinPlus,
                    'Permintaan trip baru',
                    StatusTone.live,
                  ),
                  _ReasonTile(
                    LucideIcons.calendarPlus,
                    'Perubahan jadwal atau shift',
                    StatusTone.info,
                  ),
                ];
                // Tiga kolom memotong kata ("jempu/t") bila lebar per skala
                // teks sempit (320 dp, teks 200%): tumpuk ke bawah.
                // ponytail: ambang 340 dp empiris untuk label di atas; ukur
                // kata terpanjang bila label berubah.
                final scale = MediaQuery.textScalerOf(context).scale(1);
                if (constraints.maxWidth / scale < 340) {
                  return const Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 10,
                    children: tiles,
                  );
                }
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 10,
                    children: [for (final t in tiles) Expanded(child: t)],
                  ),
                );
              },
            ),
          ],
        ),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: MooverSpace.md,
          children: [
            MooverSectionHeader('Kendaraan Anda'),
            _VehicleCard(vehicle),
          ],
        ),
        const _TipsCard(),
        // Riwayat dikelompokkan per tanggal (urutan data), termasuk trip
        // hari ini yang diakhiri/dibatalkan di simulasi. Cari & filter di
        // S12; item membuka S13 (2026-10-13).
        ListenableBuilder(
          listenable: tripStatus,
          builder: (context, _) {
            final trips = pastTrips();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: MooverSpace.lg,
              children: [
                spread(
                  Semantics(
                    header: true,
                    child: Text(
                      'Riwayat',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TripHistoryScreen(),
                      ),
                    ),
                    icon: const Icon(LucideIcons.search),
                    label: const Text('Cari & filter'),
                  ),
                ),
                for (final date in {for (final t in trips) t.date})
                  _Section(
                    title: date,
                    trailing:
                        '${trips.where((t) => t.date == date).length} trip',
                    children: [
                      for (final t in trips.where((t) => t.date == date))
                        _TripItem(
                          t,
                          history: true,
                          onTap: () => openTrip(context, t),
                        ),
                    ],
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Tile jenis trip tambahan (V2.1): ikon di tile berwarna tone + label.
/// Ikon dekoratif; ikon tone di background tone ≥4,5:1 (D6).
class _ReasonTile extends StatelessWidget {
  const _ReasonTile(this.icon, this.label, this.tone);

  final IconData icon;
  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) => Card(
    shape: const RoundedRectangleBorder(
      // V2.1: 18, tile kecil di antara md dan kartu.
      borderRadius: BorderRadius.all(Radius.circular(18)),
      side: BorderSide(color: MooverColors.hairline),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MooverSpace.md,
        vertical: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tone.background,
              borderRadius: BorderRadius.circular(MooverRadius.sm),
            ),
            child: Icon(icon, size: 20, color: tone.foreground),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12.5, // V2.1
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Kartu kendaraan (V2.1 "Your vehicle", KAK §5.1.10). Foto PLACEHOLDER
/// (dekoratif; model ditulis). Dibaca TalkBack sebagai satu item.
class _VehicleCard extends StatelessWidget {
  const _VehicleCard(this.vehicle);

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    Widget labelled(String label, String value) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(color: MooverColors.textMuted),
        ),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
    return MergeSemantics(
      child: Card(
        shape: const RoundedRectangleBorder(
          // V2.1: 22, di antara kartu (20) dan lg (24).
          borderRadius: BorderRadius.all(Radius.circular(22)),
          side: BorderSide(color: MooverColors.hairline),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: MooverSpace.md,
            children: [
              Row(
                spacing: 14,
                children: [
                  Image.asset(
                    vehicle.image,
                    width: 128,
                    height: 86,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 6,
                      children: [
                        Text(
                          vehicle.model,
                          style: textTheme.titleMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        // Pelat nomor (V2.1): tepi Ink 1,5, radius 6.
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: MooverSpace.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: MooverColors.text,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            vehicle.plate,
                            semanticsLabel: 'Nomor polisi ${vehicle.plate}',
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                              fontFeatures: tabularFigures,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 1),
              Wrap(
                spacing: MooverSpace.xl,
                runSpacing: MooverSpace.md,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  labelled('Kapasitas', vehicle.capacity),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: MooverSpace.sm,
                    children: [
                      // V2.1: foto driver; di sini avatar inisial (tanpa
                      // foto asli).
                      const _Avatar(
                        size: 30,
                        ring: 1.5,
                        border: MooverColors.surface,
                      ),
                      Flexible(child: labelled('Driver', demoDriverName)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tips berkendara (V2.1): bidang tone ok. Teks ok.foreground di
/// ok.background ≥4,5:1 (D6). Ikon dan tanda ✓ dekoratif.
class _TipsCard extends StatelessWidget {
  const _TipsCard();

  static const tips = [
    'Patuhi rambu lalu lintas.',
    'Hindari mengemudi agresif.',
    'Pastikan penumpang sesuai dengan trip.',
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const tone = StatusTone.ok;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(22), // sama dengan kartu kendaraan
      ),
      child: Padding(
        padding: const EdgeInsets.all(MooverSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: MooverSpace.md,
          children: [
            Row(
              spacing: 10,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: tone.foreground,
                    borderRadius: BorderRadius.circular(MooverRadius.sm),
                  ),
                  child: const Icon(
                    LucideIcons.shieldCheck,
                    size: 20,
                    color: MooverColors.surface,
                  ),
                ),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      'Tips berkendara',
                      style: textTheme.titleSmall?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: tone.foreground,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            for (final tip in tips)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: MooverSpace.sm,
                children: [
                  ExcludeSemantics(
                    child: Text(
                      '✓',
                      style: textTheme.bodyMedium?.copyWith(
                        color: tone.foreground,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      tip,
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 13.5, // V2.1
                        color: tone.foreground,
                      ),
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
