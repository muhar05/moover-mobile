import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/themes/theme.dart';

// MOCK/DEMO: data contoh untuk kerangka UI, bukan data server. Label status
// dari DESIGN.md §4.7, tone dari Lampiran A.2. Format D4.
typedef Trip = ({
  String date,
  String time,
  String route,
  // Alamat tujuan, hanya di jadwal hari ini (V2.1 Home). Fiktif.
  String? address,
  String? passengers,
  String status,
  StatusTone tone,
});

typedef Reimburse = ({
  String category,
  IconData icon,
  String amount,
  String date,
  String status,
  StatusTone tone,
});

const tripsToday = <Trip>[
  (
    date: '9 Okt 2026',
    time: '09.30 WIB',
    route: 'Kantor Pusat → Kantor Cabang (contoh)',
    address: 'Jl. Contoh Raya No. 10, Jakarta Selatan (contoh)',
    passengers: '2 penumpang',
    status: 'Terjadwal',
    tone: StatusTone.neutral,
  ),
  (
    date: '9 Okt 2026',
    time: '13.00 WIB',
    route: 'Kantor Cabang → Kantor Pusat (contoh)',
    address: 'Jl. Contoh Utama No. 1, Jakarta Pusat (contoh)',
    passengers: '1 penumpang',
    status: 'Terjadwal',
    tone: StatusTone.neutral,
  ),
];

const tripHistory = <Trip>[
  (
    date: '8 Okt 2026',
    time: '14.00 WIB',
    route: 'Kantor Pusat → Bandara (contoh)',
    address: null,
    passengers: null,
    status: 'Selesai',
    tone: StatusTone.ok,
  ),
  (
    date: '8 Okt 2026',
    time: '08.00 WIB',
    route: 'Kantor Pusat → Kantor Cabang (contoh)',
    address: null,
    passengers: null,
    status: 'Menunggu Feedback',
    tone: StatusTone.warn,
  ),
  (
    date: '7 Okt 2026',
    time: '10.00 WIB',
    route: 'Kantor Cabang → Kantor Pusat (contoh)',
    address: null,
    passengers: null,
    status: 'Dibatalkan',
    tone: StatusTone.err,
  ),
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

const reimbursements = <Reimburse>[
  (
    category: 'Tol',
    // Lucide tidak punya ikon tol: karcis (pemilik project 2026-10-11).
    icon: LucideIcons.ticket,
    amount: 'Rp 45.000',
    date: '8 Okt 2026',
    status: 'Diajukan',
    tone: StatusTone.neutral,
  ),
  (
    category: 'BBM',
    icon: LucideIcons.fuel,
    amount: 'Rp 300.000',
    date: '6 Okt 2026',
    status: 'Disetujui',
    tone: StatusTone.info,
  ),
  (
    category: 'Parkir',
    icon: LucideIcons.circleParking,
    amount: 'Rp 20.000',
    date: '3 Okt 2026',
    status: 'Dibayar',
    tone: StatusTone.ok,
  ),
  (
    category: 'Lainnya',
    icon: LucideIcons.receipt,
    amount: 'Rp 75.000',
    date: '1 Okt 2026',
    status: 'Ditolak',
    tone: StatusTone.err,
  ),
];
