import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/themes/theme.dart';
import '../core/widgets/spread.dart';
import '../core/widgets/widgets.dart';
import '../main_menu/main_menu_screen.dart' show formatDate;
import '../main_menu/mock_data.dart';
import '../time_log/time_log_screen.dart' show formatHm;

part 'active_trip_screen.dart';
part 'trip_history_screen.dart';

/// Buka trip: S08 bila trip ini sedang berjalan, S07 bila Terjadwal, selain
/// itu (sudah diakhiri/dibatalkan) S13.
void openTrip(BuildContext context, Trip trip) {
  final active = activeTrip.value;
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => active != null && active.trip.number == trip.number
          ? ActiveTripScreen(active: active)
          : statusOf(trip).$1 == 'Terjadwal'
          ? TripDetailScreen(trip: trip)
          : TripSummaryScreen(trip: trip),
    ),
  );
}

/// Alasan pembatalan dari V2.1 "Trip detail". Alasan wajib mengikuti mock
/// web; daftar alasan dan wajib/tidaknya Perlu konfirmasi (Q-B3, K9).
/// ponytail: "Alasan lain" tanpa isian teks; tambah TextField saat Q-B3
/// diputuskan.
const cancelReasons = [
  'Penumpang membatalkan',
  'Jadwal berubah',
  'Kendaraan bermasalah',
  'Alasan lain',
];

/// S07 Detail Daily Task (KAK §5.1.4), gaya V2.1 "Trip detail". Keputusan
/// pemilik project 2026-10-13 (belum di DESIGN.md): Start/Cancel Trip
/// disimulasikan di memori, tanpa server (D10: tanpa klaim berhasil).
/// Start tidak mensyaratkan clock-in, sama dengan mock web: Perlu konfirmasi
/// (Q-B2).
/// ponytail: jarak/estimasi/lalu lintas V2.1 belum ada (sumber rute Q-T6;
/// OSM tanpa data lalu lintas); nama penumpang belum ada di data mock.
class TripDetailScreen extends StatelessWidget {
  const TripDetailScreen({super.key, required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([tripStatus, activeTrip]),
    builder: (context, _) => _build(context),
  );

  Widget _build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (status, tone) = statusOf(trip);
    final muted = textTheme.bodySmall?.copyWith(color: MooverColors.textMuted);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detail trip',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          MooverSpace.screen,
          MooverSpace.sm,
          MooverSpace.screen,
          MooverSpace.xl,
        ),
        children: [
          spread(
            StatusBadge(label: status, tone: tone),
            Text(
              trip.number,
              style: muted?.copyWith(fontFeatures: tabularFigures),
            ),
          ),
          const SizedBox(height: MooverSpace.md),
          if (tripPoints[trip.number] case final points?) ...[
            _RouteMap(points, height: 180),
            const SizedBox(height: MooverSpace.md),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18), // V2.1
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 14, // V2.1
                children: [
                  spread(
                    MergeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: MooverSpace.xs,
                        children: [
                          Text('Waktu jemput', style: muted),
                          Text(
                            trip.time,
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontFeatures: tabularFigures,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      trip.date,
                      style: muted?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Divider(height: 1),
                  MooverRouteTimeline(
                    origin: tripOrigin(trip),
                    destination: tripDestination(trip),
                  ),
                  if (trip.address case final address?)
                    Text(address, style: muted?.copyWith(height: 1.45)),
                ],
              ),
            ),
          ),
          if (trip.passengers case final passengers?) ...[
            const SizedBox(height: MooverSpace.md),
            _Passengers(passengers),
          ],
        ],
      ),
      bottomNavigationBar: _actions(context, status),
    );
  }

  Widget? _actions(BuildContext context, String status) {
    final active = activeTrip.value;
    if (active?.trip.number == trip.number) {
      return _ActionBar(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: () => openTrip(context, trip),
              child: const Text('Lanjutkan trip'),
            ),
          ),
        ],
      );
    }
    if (status != 'Terjadwal') return null;
    final busy = active != null;
    return _ActionBar(
      note: busy
          ? 'Akhiri trip yang sedang berjalan sebelum memulai trip ini.'
          : null,
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _cancel(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: StatusTone.err.foreground, // 6,54:1
              side: BorderSide(color: StatusTone.err.foreground, width: 1.5),
            ),
            child: const Text('Batalkan'),
          ),
        ),
        Expanded(
          flex: 3, // V2.1: 1fr 1.6fr
          child: FilledButton.icon(
            // Satu trip berjalan dalam satu waktu: Perlu konfirmasi (Q-B2).
            onPressed: busy ? null : () => _start(context),
            icon: const Icon(LucideIcons.play),
            label: const Text('Mulai trip'),
          ),
        ),
      ],
    );
  }

  /// D8: konfirmasi sebelum Start Trip.
  Future<void> _start(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mulai trip?'),
        content: Text(
          'Trip ke ${tripDestination(trip)} pukul ${trip.time} akan '
          'berstatus Dalam Perjalanan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mulai'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final active = (trip: trip, startedAt: DateTime.now());
    activeTrip.value = active;
    setTripStatus(trip, onTrip);
    // Back dari S08 kembali ke Beranda, bukan ke S07 (UD1).
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => ActiveTripScreen(active: active)),
    );
  }

  /// D8: sheet alasan = konfirmasi Cancel Trip (V2.1).
  Future<void> _cancel(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: MooverColors.surface,
      shape: const RoundedRectangleBorder(
        // V2.1: 28, sama dengan sheet Keluar.
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _CancelSheet(),
    );
    if (reason == null || !context.mounted) return;
    setTripStatus(trip, canceled, (
      start: null,
      arrival: null,
      rating: null,
      comment: null,
      reason: reason,
    ));
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Trip dibatalkan di simulasi (belum dikirim ke server).',
          ),
        ),
      );
  }
}

class _CancelSheet extends StatefulWidget {
  const _CancelSheet();

  @override
  State<_CancelSheet> createState() => _CancelSheetState();
}

class _CancelSheetState extends State<_CancelSheet> {
  String? _reason;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        MooverSpace.screen,
        0,
        MooverSpace.screen,
        MooverSpace.xl + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: MooverSpace.md,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Batalkan trip ini?',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            'Pilih alasan pembatalan.',
            style: textTheme.bodyMedium?.copyWith(
              color: MooverColors.textMuted,
            ),
          ),
          RadioGroup<String>(
            groupValue: _reason,
            onChanged: (r) => setState(() => _reason = r),
            child: Column(
              children: [
                for (final r in cancelReasons)
                  RadioListTile<String>(
                    value: r,
                    title: Text(r),
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
          Row(
            spacing: 10, // V2.1
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MooverColors.text,
                  ),
                  child: const Text('Kembali'),
                ),
              ),
              Expanded(
                // Putih di err 6,54:1. Nonaktif sampai alasan dipilih.
                child: FilledButton(
                  onPressed: _reason == null
                      ? null
                      : () => Navigator.pop(context, _reason),
                  style: FilledButton.styleFrom(
                    backgroundColor: StatusTone.err.foreground,
                    foregroundColor: MooverColors.surface,
                  ),
                  child: const Text('Batalkan trip'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Jumlah penumpang (V2.1 kartu penumpang, tanpa foto/nama).
class _Passengers extends StatelessWidget {
  const _Passengers(this.passengers);

  final String passengers;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MooverSpace.lg,
        vertical: 14, // V2.1
      ),
      child: Row(
        spacing: MooverSpace.md,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: MooverColors.blueTint,
              borderRadius: BorderRadius.circular(14), // V2.1
            ),
            child: const Icon(LucideIcons.users, color: MooverColors.primary),
          ),
          Expanded(
            child: Text(
              passengers,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Peta rute asal → tujuan (Leaflet/OSM, KAK §9.2) untuk S07/S08. Peta
/// dekoratif bagi pembaca layar: asal, tujuan, dan alamat sudah ada sebagai
/// teks di layar. Tile gagal dimuat → catatan di atas peta, detail teks tetap
/// tampil (DESIGN.md S07).
/// ponytail: garis lurus asal → tujuan dan peta statis (tanpa geser/zoom,
/// tanpa posisi GPS); ganti dengan geometri rute dari server (OSRM lewat
/// backend, Q-T6) dan lokasi driver saat izin GPS diputuskan (Q-T4/Q-T5).
/// Tile OSM publik hanya untuk demo (kebijakan tile.openstreetmap.org); untuk
/// produksi butuh tile server sendiri/penyedia: Belum ditentukan.
class _RouteMap extends StatefulWidget {
  const _RouteMap(this.points, {required this.height});

  final (LatLng, LatLng) points;
  final double height;

  @override
  State<_RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<_RouteMap> {
  bool _failed = false;

  @override
  Widget build(BuildContext context) {
    final (origin, destination) = widget.points;
    return ClipRRect(
      borderRadius: BorderRadius.circular(MooverRadius.card),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            ExcludeSemantics(
              child: FlutterMap(
                options: MapOptions(
                  initialCameraFit: CameraFit.coordinates(
                    coordinates: [origin, destination],
                    padding: const EdgeInsets.all(MooverSpace.xxl),
                  ),
                  backgroundColor: MooverColors.blueTint,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.siagaabdiutama.moover',
                    errorTileCallback: (_, _, _) {
                      if (!_failed && mounted) setState(() => _failed = true);
                    },
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [origin, destination],
                        color: MooverColors.primary,
                        strokeWidth: 4,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: origin,
                        width: 18,
                        height: 18,
                        child: const DecoratedBox(
                          decoration: ShapeDecoration(
                            color: MooverColors.surface,
                            shape: CircleBorder(
                              side: BorderSide(
                                color: MooverColors.primary,
                                width: 4,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Marker(
                        point: destination,
                        width: 36,
                        height: 36,
                        alignment: Alignment.topCenter, // ujung pin di titik
                        child: const Icon(
                          LucideIcons.mapPin,
                          size: 36,
                          color: MooverColors.navy,
                        ),
                      ),
                    ],
                  ),
                  // Atribusi wajib (lisensi ODbL OSM). Bukan
                  // SimpleAttributionWidget: Row-nya overflow di teks 200%.
                  Align(
                    alignment: Alignment.bottomRight,
                    child: ColoredBox(
                      color: MooverColors.surface,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: MooverSpace.xs,
                          vertical: 2,
                        ),
                        child: Text(
                          '© OpenStreetMap',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_failed)
              Positioned(
                top: MooverSpace.sm,
                left: MooverSpace.sm,
                right: MooverSpace.sm,
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: MooverColors.surface,
                      borderRadius: BorderRadius.circular(MooverRadius.sm),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: MooverSpace.md,
                        vertical: MooverSpace.sm,
                      ),
                      child: Text(
                        'Peta tidak dapat dimuat. Periksa koneksi internet.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Action bar bawah (UD2): tombol berdampingan V2.1, [note] di atasnya.
class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.children, this.note});

  final List<Widget> children;
  final String? note;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: MooverColors.surface,
      border: Border(top: BorderSide(color: MooverColors.hairline)),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          MooverSpace.lg,
          MooverSpace.md,
          MooverSpace.lg,
          MooverSpace.screen,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: MooverSpace.sm,
          children: [
            if (note case final note?)
              Text(
                note,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: MooverColors.textMuted),
              ),
            Row(spacing: 10, children: children), // V2.1
          ],
        ),
      ),
    ),
  );
}
