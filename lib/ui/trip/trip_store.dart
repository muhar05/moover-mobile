import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:sqflite/sqflite.dart';

import '../core/themes/theme.dart';
import '../main_menu/main_menu_screen.dart' show formatDate;
import '../main_menu/mock_data.dart';

/// Penyimpanan trip di SQLite perangkat (keputusan pemilik project
/// 2026-10-14, belum di DESIGN.md): trip tambahan Tipe A (S11) dan hasil
/// simulasi Start/Cancel/End semua trip, agar tetap ada saat app dibuka
/// ulang. Jadwal dari Admin/GA tetap konstanta mock (data server). Tipe dan
/// skema di sini jadi usulan data ke backend (docs/TRIP_DATA.md); API
/// U10–U18 masih Usulan (API_CONTRACT.md).
/// ponytail: tanpa server, tanpa sinkronisasi, tanpa reset per hari (sama
/// dengan [clockIn]); ganti dengan klien API saat U11–U17 Terverifikasi
/// (offline/antrean: Q-T5).

/// Isian S11 Add New Trip (KAK §5.1.6: nama dan divisi penumpang, tujuan).
/// Satu penumpang per trip; format input penumpang (pilih karyawan atau
/// teks bebas) Perlu konfirmasi (K5). [origin]: lokasi jemput, tidak disebut
/// KAK (bisa dari GPS, Q-T4): Perlu konfirmasi. Titik dipilih di peta
/// (keputusan pemilik project 2026-10-14).
typedef NewTrip = ({
  String passengerName,
  String passengerDivision,
  String origin,
  String destination,
  LatLng originPoint,
  LatLng destinationPoint,
  // Alamat lengkap tujuan, diketik manual, opsional (2026-10-14).
  String? destinationAddress,
});

/// Path DB; tes menggantinya dengan [inMemoryDatabasePath]. File terpisah
/// dari reimburse: tiap store punya versi skema sendiri.
@visibleForTesting
String tripDbPath = 'trip.db';

/// Nilai DB status hasil simulasi; Terjadwal = tanpa baris.
const _statuses = {
  'on_trip': onTrip,
  'waiting_feedback': waitingFeedback,
  'canceled': canceled,
};

class TripStore {
  Future<Database>? _db;
  Database? _opened; // untuk [reset]
  Future<void>? _loaded;

  // Future disimpan (bukan Database): pemanggil serentak memakai satu DB.
  Future<Database> _open() => _db ??= _openNew();

  Future<Database> _openNew() async => _opened = await openDatabase(
    tripDbPath,
    version: 4,
    // Sudah satu instance lewat [_db]; tanpa ini sqflite memakai ulang DB
    // lain dengan path sama (tes: ':memory:' reimburse).
    singleInstance: false,
    onCreate: (db, _) async {
      for (final sql in [
        ...tripSchema,
        ..._addPoints,
        _addStops,
        ..._addAddress,
      ]) {
        await db.execute(sql);
      }
    },
    // v1 (tanpa titik peta) di HP demo: trip lama tetap, tanpa peta.
    onUpgrade: (db, from, _) async {
      if (from < 2) {
        for (final sql in _addPoints) {
          await db.execute(sql);
        }
      }
      if (from < 3) await db.execute(_addStops);
      if (from < 4) {
        for (final sql in _addAddress) {
          await db.execute(sql);
        }
      }
    },
  );

  /// Muat sekali ke [extraTrips], [tripStatus], [tripResults], [activeTrip].
  /// Nilai di memori menang (sudah diisi simulasi lebih dulu).
  Future<void> load() => _loaded ??= _load();

  Future<void> _load() async {
    try {
      final db = await _open();
      extraTrips.value = [
        for (final r in await db.query('trip', orderBy: 'created_at'))
          _tripFromRow(r),
        ...extraTrips.value,
      ];
      final trips = {for (final t in todayTrips()) t.number: t};
      final statuses = <String, TripStatus>{};
      for (final s in await db.query('trip_state')) {
        final number = s['trip_number']! as String;
        final status = _statuses[s['status']! as String]!;
        statuses[number] = status;
        tripResults.putIfAbsent(
          number,
          () => (
            start: s['start_time'] as String?,
            arrival: s['arrival_time'] as String?,
            rating: s['rating'] as int?,
            comment: s['comment'] as String?,
            reason: s['cancel_reason'] as String?,
          ),
        );
        if ((status, s['started_at'], trips[number]) case (
          onTrip,
          final String at,
          final trip?,
        )) {
          activeTrip.value ??= (trip: trip, startedAt: DateTime.parse(at));
        }
      }
      final stops = <String, List<TripStop>>{};
      for (final r in await db.query('trip_stop', orderBy: 'seq')) {
        (stops[r['trip_number']! as String] ??= []).add((
          name: r['name']! as String,
          address: r['address'] as String?,
          point: switch ((r['lat'], r['lng'])) {
            (final num lat, final num lng) => LatLng(
              lat.toDouble(),
              lng.toDouble(),
            ),
            _ => null,
          },
          arrivedAt: switch (r['arrived_at']) {
            final String at => DateTime.parse(at),
            _ => null,
          },
        ));
      }
      tripStops.value = {...stops, ...tripStops.value};
      // Terakhir: pendengar [tripStatus] membaca [tripResults].
      tripStatus.value = {...statuses, ...tripStatus.value};
    } on Exception catch (e) {
      // App tetap jalan dengan data mock; simulasi hanya di memori.
      debugPrint('Trip gagal dimuat dari perangkat: $e');
    }
  }

  /// Simpan trip Tipe A baru (Terjadwal, jemput sekarang, seperti mock web)
  /// dan tampilkan di jadwal hari ini.
  Future<Trip> add(NewTrip n) async {
    await load();
    final db = await _open();
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final day = '${now.year}-${two(now.month)}-${two(now.day)}';
    final prefix = 'TRP-${day.replaceAll('-', '')}-';
    // Rute disimpan "Asal → Tujuan": panah di isian akan memecah rute.
    String clean(String v) => v.trim().replaceAll('→', '-');
    final trip = await db.transaction((tx) async {
      final taken = {
        for (final t in [...tripsToday, ...tripHistory]) t.number,
        for (final r in await tx.query('trip', columns: ['number']))
          r['number']! as String,
      }.where((number) => number.startsWith(prefix)).length;
      final row = {
        // Format nomor dari mock web (belum Terverifikasi); di server nomor
        // diterbitkan sistem.
        'number': '$prefix${(taken + 1).toString().padLeft(4, '0')}',
        'trip_date': day,
        'pickup_time': '${two(now.hour)}:${two(now.minute)}',
        'origin': clean(n.origin),
        'destination': clean(n.destination),
        'passenger_name': clean(n.passengerName),
        'passenger_division': clean(n.passengerDivision),
        'created_at': now.toIso8601String(),
        'origin_lat': n.originPoint.latitude,
        'origin_lng': n.originPoint.longitude,
        'destination_lat': n.destinationPoint.latitude,
        'destination_lng': n.destinationPoint.longitude,
        'destination_address': n.destinationAddress,
      };
      await tx.insert('trip', row);
      return _tripFromRow(row);
    });
    extraTrips.value = [...extraTrips.value, trip];
    return trip;
  }

  /// Dari [setTripStatus]; baris lama ditimpa. [startedAt] memulihkan trip
  /// berjalan saat app dibuka ulang. Gagal simpan: status tetap di memori.
  Future<void> saveState(
    String number,
    TripStatus status,
    TripResult? r,
    DateTime? startedAt,
  ) async {
    try {
      // Muat dulu: data DB hanya digabung sekali, sebelum perubahan baru.
      await load();
      final db = await _open();
      await db.insert('trip_state', {
        'trip_number': number,
        'status': _statuses.entries.firstWhere((e) => e.value == status).key,
        'started_at': startedAt?.toIso8601String(),
        'start_time': r?.start,
        'arrival_time': r?.arrival,
        'rating': r?.rating,
        'comment': r?.comment,
        'cancel_reason': r?.reason,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } on Exception catch (e) {
      debugPrint('Status trip $number gagal disimpan: $e');
    }
  }

  /// Dari [setTripStops]: seluruh daftar tujuan trip ditulis ulang.
  Future<void> saveStops(String number, List<TripStop> stops) async {
    try {
      await load();
      final db = await _open();
      await db.transaction((tx) async {
        await tx.delete(
          'trip_stop',
          where: 'trip_number = ?',
          whereArgs: [number],
        );
        for (final (seq, s) in stops.indexed) {
          await tx.insert('trip_stop', {
            'trip_number': number,
            'seq': seq,
            'name': s.name,
            'address': s.address,
            'lat': s.point?.latitude,
            'lng': s.point?.longitude,
            'arrived_at': s.arrivedAt?.toIso8601String(),
          });
        }
      });
    } on Exception catch (e) {
      debugPrint('Tujuan trip $number gagal disimpan: $e');
    }
  }

  /// Tidak menunggu [_db]: future dari zona waktu palsu tes sebelumnya bisa
  /// tidak pernah selesai.
  @visibleForTesting
  Future<void> reset() async {
    final db = _opened;
    _db = null;
    _opened = null;
    _loaded = null;
    for (final t in extraTrips.value) {
      tripPoints.remove(t.number);
    }
    extraTrips.value = const [];
    tripStops.value = const {};
    await db?.close();
  }
}

final tripStore = TripStore();

/// Skema SQLite (lihat docs/TRIP_DATA.md).
const tripSchema = [
  // Trip tambahan Tipe A (S11). Semua isian wajib (KAK §5.1.6).
  '''
CREATE TABLE trip (
  number TEXT PRIMARY KEY,
  trip_date TEXT NOT NULL,
  pickup_time TEXT NOT NULL,
  origin TEXT NOT NULL CHECK (origin <> ''),
  destination TEXT NOT NULL CHECK (destination <> ''),
  passenger_name TEXT NOT NULL CHECK (passenger_name <> ''),
  passenger_division TEXT NOT NULL CHECK (passenger_division <> ''),
  created_at TEXT NOT NULL
)''',
  // Hasil simulasi per nomor trip (jadwal mock maupun Tipe A).
  '''
CREATE TABLE trip_state (
  trip_number TEXT PRIMARY KEY,
  status TEXT NOT NULL
    CHECK (status IN ('on_trip','waiting_feedback','canceled')),
  started_at TEXT,
  start_time TEXT,
  arrival_time TEXT,
  rating INTEGER CHECK (rating BETWEEN 1 AND 5),
  comment TEXT,
  cancel_reason TEXT
)''',
];

/// Migrasi v2: titik peta trip Tipe A (kosong untuk trip v1).
const _addPoints = [
  'ALTER TABLE trip ADD COLUMN origin_lat REAL',
  'ALTER TABLE trip ADD COLUMN origin_lng REAL',
  'ALTER TABLE trip ADD COLUMN destination_lat REAL',
  'ALTER TABLE trip ADD COLUMN destination_lng REAL',
];

/// Migrasi v3: daftar tujuan (S09) semua trip. seq 0 = tujuan awal, seq > 0
/// = ditambah saat trip berjalan; arrived_at null = belum tiba.
const _addStops = '''
CREATE TABLE trip_stop (
  trip_number TEXT NOT NULL,
  seq INTEGER NOT NULL CHECK (seq >= 0),
  name TEXT NOT NULL CHECK (name <> ''),
  lat REAL,
  lng REAL,
  arrived_at TEXT,
  PRIMARY KEY (trip_number, seq)
)''';

/// Migrasi v4: alamat lengkap manual (opsional) tujuan trip Tipe A dan
/// tiap tujuan S09.
const _addAddress = [
  'ALTER TABLE trip ADD COLUMN destination_address TEXT',
  'ALTER TABLE trip_stop ADD COLUMN address TEXT',
];

/// Juga mendaftarkan titik peta ke [tripPoints].
Trip _tripFromRow(Map<String, Object?> r) {
  final trip = _tripOf(r);
  if (r case {
    'origin_lat': final num oLat,
    'origin_lng': final num oLng,
    'destination_lat': final num dLat,
    'destination_lng': final num dLng,
  }) {
    tripPoints[trip.number] = (
      LatLng(oLat.toDouble(), oLng.toDouble()),
      LatLng(dLat.toDouble(), dLng.toDouble()),
    );
  }
  return trip;
}

Trip _tripOf(Map<String, Object?> r) => (
  number: r['number']! as String,
  date: formatDate(DateTime.parse(r['trip_date']! as String)).split(', ').last,
  time: '${(r['pickup_time']! as String).replaceAll(':', '.')} WIB',
  route: '${r['origin']} → ${r['destination']}',
  address: r['destination_address'] as String?,
  passengers: '${r['passenger_name']} (${r['passenger_division']})',
  status: 'Terjadwal',
  tone: StatusTone.neutral,
);
