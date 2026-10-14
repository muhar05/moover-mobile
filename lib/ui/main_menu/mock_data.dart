import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../core/themes/theme.dart';
import '../trip/trip_store.dart';

// MOCK/DEMO: data contoh untuk kerangka UI, bukan data server. Label status
// dari DESIGN.md §4.7, tone dari Lampiran A.2. Format D4.
typedef Trip = ({
  // Format nomor TRP-YYYYMMDD-NNNN dari mock web (belum Terverifikasi).
  String number,
  String date,
  String time,
  String route,
  // Alamat tujuan, hanya di jadwal hari ini (V2.1 Home). Fiktif.
  String? address,
  String? passengers,
  String status,
  StatusTone tone,
});

const tripsToday = <Trip>[
  (
    number: 'TRP-20261009-0001',
    date: '9 Okt 2026',
    time: '09.30 WIB',
    route: 'Kantor Pusat → Kantor Cabang (contoh)',
    address: 'Jl. Contoh Raya No. 10, Jakarta Selatan (contoh)',
    passengers: '2 penumpang',
    status: 'Terjadwal',
    tone: StatusTone.neutral,
  ),
  (
    number: 'TRP-20261009-0002',
    date: '9 Okt 2026',
    time: '13.00 WIB',
    route: 'Kantor Cabang → Kantor Pusat (contoh)',
    address: 'Jl. Contoh Utama No. 1, Jakarta Pusat (contoh)',
    passengers: '1 penumpang',
    status: 'Terjadwal',
    tone: StatusTone.neutral,
  ),
];

/// Trip tambahan Tipe A dari S11, disimpan di SQLite ([tripStore]).
final extraTrips = ValueNotifier<List<Trip>>(const []);

/// Jadwal hari ini: jadwal mock lalu trip tambahan (urutan dibuat).
List<Trip> todayTrips() => [...tripsToday, ...extraTrips.value];

const tripHistory = <Trip>[
  (
    number: 'TRP-20261008-0003',
    date: '8 Okt 2026',
    time: '14.00 WIB',
    route: 'Kantor Pusat → Bandara (contoh)',
    address: null,
    passengers: null,
    status: 'Selesai',
    tone: StatusTone.ok,
  ),
  (
    number: 'TRP-20261008-0001',
    date: '8 Okt 2026',
    time: '08.00 WIB',
    route: 'Kantor Pusat → Kantor Cabang (contoh)',
    address: null,
    passengers: null,
    status: 'Menunggu Feedback',
    tone: StatusTone.warn,
  ),
  (
    number: 'TRP-20261007-0002',
    date: '7 Okt 2026',
    time: '10.00 WIB',
    route: 'Kantor Cabang → Kantor Pusat (contoh)',
    address: null,
    passengers: null,
    status: 'Dibatalkan',
    tone: StatusTone.err,
  ),
];

// Simulasi Start/Cancel/End Trip (keputusan pemilik project 2026-10-13,
// belum di DESIGN.md): status trip hari ini disimpan per nomor trip dan
// menimpa status mock. Label §4.7; tone: On Trip = indigo, sama dengan web
// (A.2), bukan live V2.1 (keputusan pemilik project 2026-10-13). Indigo di
// latarnya ≥4,5:1 (diuji di design_system_test).
// Disimpan juga di SQLite perangkat ([tripStore], 2026-10-14).
// ponytail: ganti dengan data server saat API trip Terverifikasi.
typedef TripStatus = (String, StatusTone);
const onTrip = ('Dalam Perjalanan', StatusTone.indigo);
const waitingFeedback = ('Menunggu Feedback', StatusTone.warn);
const canceled = ('Dibatalkan', StatusTone.err);

final tripStatus = ValueNotifier<Map<String, TripStatus>>({});

/// Trip yang sedang berjalan + waktu Start; null = tidak ada. Satu trip
/// berjalan dalam satu waktu: Usulan, Perlu konfirmasi (Q-B2).
typedef ActiveTrip = ({Trip trip, DateTime startedAt});
final activeTrip = ValueNotifier<ActiveTrip?>(null);

TripStatus statusOf(Trip t) => tripStatus.value[t.number] ?? (t.status, t.tone);

/// [result] dicatat lebih dulu agar pendengar [tripStatus] membacanya.
/// Start Trip: set [activeTrip] dulu agar waktu Start ikut disimpan.
void setTripStatus(Trip t, TripStatus status, [TripResult? result]) {
  if (result != null) tripResults[t.number] = result;
  tripStatus.value = {...tripStatus.value, t.number: status};
  final active = activeTrip.value;
  tripStore.saveState(
    t.number,
    status,
    result,
    active?.trip.number == t.number ? active!.startedAt : null,
  );
}

/// Satu tujuan trip; [arrivedAt] null = belum tiba. Driver bisa menambah
/// tujuan saat trip berjalan (S09, KAK §5.1.5) dan menyelesaikan tiap tujuan
/// berurutan (KAK §6.1 langkah 4), seperti "add stops" Google Maps
/// (keputusan pemilik project 2026-10-14, Q-B4). Tujuan terakhir tiba saat
/// End Trip. Driver tidak menghapus/mengubah tujuan: keputusan pemesan dan
/// alur approval-nya Belum ditentukan (keputusan pemilik project
/// 2026-10-14, jangan diimplementasikan dulu). [address]: alamat lengkap diisi
/// driver manual, opsional (permintaan 2026-10-14). Bentuk mengikuti
/// `TripDestination` web (`arrivedAt`).
typedef TripStop = ({
  String name,
  String? address,
  LatLng? point,
  DateTime? arrivedAt,
});

/// Daftar tujuan per nomor trip yang tujuannya pernah diubah; urutan 0 =
/// tujuan awal. Disimpan juga di SQLite ([tripStore]).
final tripStops = ValueNotifier<Map<String, List<TripStop>>>({});

/// Tujuan berurutan; belum diubah = tujuan awal saja.
List<TripStop> stopsOf(Trip t) =>
    tripStops.value[t.number] ??
    [
      (
        name: tripDestination(t),
        address: t.address,
        point: tripPoints[t.number]?.$2,
        arrivedAt: null,
      ),
    ];

void setTripStops(Trip t, List<TripStop> stops) {
  tripStops.value = {...tripStops.value, t.number: stops};
  tripStore.saveStops(t.number, stops);
}

/// Tandai tujuan ke-[i] tiba sekarang.
void arriveAt(Trip t, int i) {
  final stops = [...stopsOf(t)];
  stops[i] = (
    name: stops[i].name,
    address: stops[i].address,
    point: stops[i].point,
    arrivedAt: DateTime.now(),
  );
  setTripStops(t, stops);
}

/// Hasil trip untuk S13: jam Start/End Trip ("HH.MM WIB"), rating 1–5 +
/// komentar penumpang (KAK §5.2.1), alasan batal. null = tidak ada/belum.
typedef TripResult = ({
  String? start,
  String? arrival,
  int? rating,
  String? comment,
  String? reason,
});

// Riwayat contoh (fiktif) + hasil simulasi End/Cancel per nomor trip.
// Hasil simulasi juga disimpan di SQLite ([tripStore]).
// ponytail: ganti dengan data server saat API trip dan feedback
// Terverifikasi.
final tripResults = <String, TripResult>{
  'TRP-20261008-0003': (
    start: '14.05 WIB',
    arrival: '14.50 WIB',
    rating: 4,
    comment: 'Perjalanan nyaman dan tepat waktu. (contoh)',
    reason: null,
  ),
  'TRP-20261008-0001': (
    start: '08.00 WIB',
    arrival: '08.40 WIB',
    rating: null,
    comment: null,
    reason: null,
  ),
  'TRP-20261007-0002': (
    start: null,
    arrival: null,
    rating: null,
    comment: null,
    reason: 'Jadwal berubah',
  ),
};

/// Trip yang sudah lewat, terbaru dulu: trip hari ini yang diakhiri atau
/// dibatalkan di simulasi, lalu [tripHistory].
List<Trip> pastTrips() => [
  for (final t in todayTrips().reversed)
    if (!{'Terjadwal', onTrip.$1}.contains(statusOf(t).$1)) t,
  ...tripHistory,
];

/// Satu absensi: waktu + foto bukti. [photo] null = foto simulasi/contoh.
typedef Punch = ({DateTime at, String? photo});

/// Satu hari di Time Log (S05).
typedef TimeLog = ({Punch clockIn, Punch clockOut});

// Absensi hari ini; null = belum. Available = sudah clock-in dan belum
// clock-out (keputusan pemilik project 2026-10-10; Q-B1/K2 belum di
// DESIGN.md; mock web juga begitu). Diisi simulasi S04 (keputusan
// 2026-10-11; clock-out 2026-10-13).
// ponytail: hanya di memori, hilang saat app ditutup dan tidak reset per
// hari; ganti dengan data server saat API absensi (U5) Terverifikasi.
final clockIn = ValueNotifier<Punch?>(null);
final clockOut = ValueNotifier<Punch?>(null);

// Riwayat contoh, terbaru dulu (nilai V2.1 Time log). Tanpa foto.
final pastTimeLogs = <TimeLog>[
  (
    clockIn: (at: DateTime(2026, 10, 9, 7, 30), photo: null),
    clockOut: (at: DateTime(2026, 10, 9, 16, 30), photo: null),
  ),
  (
    clockIn: (at: DateTime(2026, 10, 8, 7, 55), photo: null),
    clockOut: (at: DateTime(2026, 10, 8, 14, 30), photo: null),
  ),
  (
    clockIn: (at: DateTime(2026, 10, 7, 7, 45), photo: null),
    clockOut: (at: DateTime(2026, 10, 7, 16, 45), photo: null),
  ),
];

/// Hari ini (setelah clock-out) lalu riwayat contoh.
List<TimeLog> timeLogs() => [
  if ((clockIn.value, clockOut.value) case (final i?, final o?))
    (clockIn: i, clockOut: o),
  ...pastTimeLogs,
];

typedef Vehicle = ({String model, String plate, String capacity, String image});

// Sumber data kendaraan (default driver atau kendaraan trip aktif): Perlu
// konfirmasi (Q-B8). Pelat fiktif.
const vehicle = (
  model: 'BYD Sealion 7',
  plate: 'B 1234 XYZ',
  capacity: '6 kursi',
  image: 'assets/images/vehicles/vehicle-placeholder.jpg',
);

// Email driver di kartu profil Akun. Fiktif (keputusan pemilik project
// 2026-10-10); domain .example dicadangkan RFC 2606, tidak milik siapa pun.
const demoDriverEmail = 'driver.demo@moover.example';

// ponytail: data mock menyimpan rute sebagai "Asal → Tujuan"; dipecah di
// sini tanpa mengubah datanya. Hapus saat data trip punya asal/tujuan
// terpisah (kontrak API trip).
List<String> _routeParts(Trip t) {
  final parts = t.route.split(' → ');
  assert(parts.length == 2, 'rute mock harus "Asal → Tujuan": ${t.route}');
  return parts;
}

String tripOrigin(Trip t) => _routeParts(t).first;
String tripDestination(Trip t) => _routeParts(t).last;

// Titik asal → tujuan trip hari ini untuk peta S07/S08 (Leaflet/OSM, KAK
// §9.2; paket flutter_map disetujui pemilik project 2026-10-13). Koordinat
// fiktif di Jakarta Pusat/Selatan, sesuai alamat contoh.
// ponytail: dipisah per nomor trip agar tipe [Trip] tidak berubah; pindah ke
// data trip saat kontrak API trip Terverifikasi. Trip Tipe A (S11) ditambah
// [tripStore].
const kantorPusat = LatLng(-6.1865, 106.8340);
const kantorCabang = LatLng(-6.2607, 106.8105);
final tripPoints = <String, (LatLng, LatLng)>{
  'TRP-20261009-0001': (kantorPusat, kantorCabang),
  'TRP-20261009-0002': (kantorCabang, kantorPusat),
};
