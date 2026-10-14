part of 'trip_detail_screen.dart';

/// Titik dan nama tempat hasil [LocationPickerScreen].
typedef PickedLocation = ({LatLng point, String name});

/// Nama tempat dari titik peta; null = tidak ditemukan. Tes menggantinya.
/// ponytail: Nominatim publik (OSM) hanya untuk demo: kebijakannya maks.
/// 1 permintaan/detik, wajib User-Agent, tanpa autocomplete, tidak untuk
/// produksi. Ganti dengan geocoding lewat backend (docs/TRIP_DATA.md §4).
@visibleForTesting
Future<String?> Function(LatLng) reverseGeocode = _nominatim;

/// Cari tempat dari teks (maks. 5, Indonesia). Tes menggantinya.
@visibleForTesting
Future<List<PickedLocation>> Function(String) searchPlaces = (q) async =>
    placesFromNominatim(
      await getJson(
        Uri.https('nominatim.openstreetmap.org', '/search', {
          'format': 'jsonv2',
          'q': q,
          'limit': '5',
          'countrycodes': 'id',
          'accept-language': 'id',
        }),
      ),
    );

/// Hasil /search Nominatim (lat/lon berupa teks); entri rusak dilewati.
@visibleForTesting
List<PickedLocation> placesFromNominatim(Object? json) => [
  if (json is List)
    for (final p in json)
      if (p case {
        'lat': final String lat,
        'lon': final String lon,
        'display_name': final String full,
      })
        if ((double.tryParse(lat), double.tryParse(lon)) case (
          final lat?,
          final lng?,
        ))
          (point: LatLng(lat, lng), name: _shortName(full)),
];

/// "Tempat, Jalan, Kelurahan, ...": tiga bagian pertama cukup.
String _shortName(String full) => full.split(', ').take(3).join(', ');

Future<String?> _nominatim(LatLng p) async {
  final json = await getJson(
    Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'jsonv2',
      'lat': '${p.latitude}',
      'lon': '${p.longitude}',
      'accept-language': 'id',
    }),
  );
  return switch (json) {
    {'display_name': final String full} => _shortName(full),
    _ => null,
  };
}

/// Pilih lokasi untuk S11 (Leaflet/OSM, KAK §9.2): cari nama tempat di
/// search bar lalu pilih hasilnya, atau geser peta (pin tetap di tengah);
/// "Pilih titik ini" mengembalikan titik + nama tempat (permintaan pemilik
/// project 2026-10-14: nama terisi otomatis, tidak diketik, agar tidak
/// berbeda dengan titik; search bar ditambahkan di hari yang sama). Hasil
/// pencarian memberi jalur tanpa menggeser peta, termasuk bagi pembaca
/// layar. Nama tidak ditemukan atau offline: koordinat dipakai sebagai nama.
/// Mulai dari [initial], atau Kantor Pusat (contoh) bila kosong; posisi HP
/// butuh GPS (Q-T4, Belum ditentukan).
/// ponytail: cari saat tombol Cari di keyboard ditekan, bukan tiap ketikan
/// (kebijakan Nominatim melarang autocomplete); tambahkan saran saat ketik
/// bila geocoding lewat backend.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, required this.title, this.initial});

  final String title;
  final LatLng? initial;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _map = MapController();
  final _query = TextEditingController();
  bool _failed = false;
  bool _busy = false;

  /// Hasil yang dipilih; dihapus bila peta digeser sesudahnya.
  PickedLocation? _chosen;

  /// null = daftar hasil tertutup; [_searching] = sedang mencari.
  List<PickedLocation>? _results;
  bool _searching = false;
  String? _searchError;

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) return;
    setState(() {
      _searching = true;
      _searchError = null;
      _results = const [];
    });
    try {
      final found = await searchPlaces(q.trim())
          .timeout(const Duration(seconds: 8));
      if (mounted) setState(() => _results = found);
    } on Exception {
      if (mounted) {
        setState(
          () => _searchError = 'Pencarian gagal. Periksa koneksi internet.',
        );
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _choose(PickedLocation place) {
    FocusScope.of(context).unfocus();
    _map.move(place.point, 17);
    setState(() {
      _chosen = place;
      _results = null;
    });
  }

  void _closeResults() => setState(() {
    _query.clear();
    _results = null;
    _searchError = null;
  });

  Future<void> _confirm() async {
    final point = _map.camera.center;
    if (_chosen case final chosen?) {
      Navigator.of(context).pop<PickedLocation>(chosen);
      return;
    }
    setState(() => _busy = true);
    String? name;
    try {
      name = await reverseGeocode(point).timeout(const Duration(seconds: 8));
    } on Exception {
      // offline / timeout: koordinat
    }
    if (!mounted) return;
    Navigator.of(context).pop<PickedLocation>((
      point: point,
      name: (name ?? '').trim().isNotEmpty
          ? name!.trim()
          : 'Titik ${point.latitude.toStringAsFixed(5)}, '
                '${point.longitude.toStringAsFixed(5)}',
    ));
  }

  @override
  void dispose() {
    _map.dispose();
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodyMedium?.copyWith(color: MooverColors.textMuted);
    final results = _results;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MooverSpace.screen,
              0,
              MooverSpace.screen,
              MooverSpace.md,
            ),
            child: TextField(
              controller: _query,
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'Cari nama tempat atau alamat',
                prefixIcon: const Icon(LucideIcons.search),
                suffixIcon: results == null
                    ? null
                    : IconButton(
                        tooltip: 'Tutup pencarian',
                        onPressed: _closeResults,
                        icon: const Icon(LucideIcons.x),
                      ),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                ExcludeSemantics(
                  child: FlutterMap(
                    mapController: _map,
                    options: MapOptions(
                      initialCenter: widget.initial ?? kantorPusat,
                      initialZoom: 16,
                      backgroundColor: MooverColors.blueTint,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                      // Peta digeser setelah memilih hasil: titik baru.
                      onPositionChanged: (_, gesture) {
                        if (gesture && _chosen != null) {
                          setState(() => _chosen = null);
                        }
                      },
                    ),
                    children: [
                      _osmTiles(() {
                        if (!_failed && mounted) {
                          setState(() => _failed = true);
                        }
                      }),
                      _osmAttribution(context),
                    ],
                  ),
                ),
                // Pin tetap di tengah; ujung bawah pin = titik terpilih.
                const IgnorePointer(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Icon(
                        LucideIcons.mapPin,
                        size: 40,
                        color: MooverColors.navy,
                      ),
                    ),
                  ),
                ),
                if (_failed) _mapError(context),
                // Daftar hasil menutupi peta (peta tetap ada untuk [_choose]).
                if (results != null)
                  Positioned.fill(
                    child: Material(
                      color: MooverColors.surface,
                      child: _searching
                          ? const Center(child: CircularProgressIndicator())
                          : _searchError != null || results.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(MooverSpace.screen),
                              child: Text(
                                _searchError ??
                                    'Tempat tidak ditemukan. Coba kata lain '
                                        'atau pilih dari peta.',
                                textAlign: TextAlign.center,
                                style: muted,
                              ),
                            )
                          : ListView(
                              children: [
                                for (final place in results)
                                  ListTile(
                                    leading: const Icon(LucideIcons.mapPin),
                                    title: Text(place.name),
                                    onTap: () => _choose(place),
                                  ),
                              ],
                            ),
                    ),
                  ),
              ],
            ),
          ),
          // Keyboard terbuka: sembunyikan agar peta/hasil tetap muat.
          if (MediaQuery.viewInsetsOf(context).bottom == 0 && results == null)
            // Teks besar di layar pendek: panel digulir, peta tetap dapat
            // ruang. ponytail: batas 40% tinggi layar empiris (320dp, teks
            // 200%).
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.4,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    MooverSpace.screen,
                    MooverSpace.lg,
                    MooverSpace.screen,
                    MooverSpace.lg + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: MooverSpace.md,
                    children: [
                      Text(
                        _chosen?.name ??
                            'Cari tempat, atau geser peta sampai pin '
                                'berada di lokasi.',
                        textAlign: TextAlign.center,
                        style: _chosen == null ? muted : textTheme.titleSmall,
                      ),
                      PrimaryButton(
                        label: 'Pilih titik ini',
                        onPressed: _confirm,
                        busy: _busy,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
