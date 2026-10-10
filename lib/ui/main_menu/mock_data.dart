import 'package:flutter/material.dart';

import '../core/themes/theme.dart';

// MOCK/DEMO: data contoh untuk kerangka UI, bukan data server. Label status
// dari DESIGN.md §4.7, tone dari Lampiran A.2. Format D4.
typedef Trip = ({
  String date,
  String time,
  String route,
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
    passengers: '2 penumpang',
    status: 'Terjadwal',
    tone: StatusTone.neutral,
  ),
  (
    date: '9 Okt 2026',
    time: '13.00 WIB',
    route: 'Kantor Cabang → Kantor Pusat (contoh)',
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
    passengers: null,
    status: 'Selesai',
    tone: StatusTone.ok,
  ),
  (
    date: '8 Okt 2026',
    time: '08.00 WIB',
    route: 'Kantor Pusat → Kantor Cabang (contoh)',
    passengers: null,
    status: 'Menunggu Feedback',
    tone: StatusTone.warn,
  ),
  (
    date: '7 Okt 2026',
    time: '10.00 WIB',
    route: 'Kantor Cabang → Kantor Pusat (contoh)',
    passengers: null,
    status: 'Dibatalkan',
    tone: StatusTone.err,
  ),
];

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
    icon: Icons.toll_outlined,
    amount: 'Rp 45.000',
    date: '8 Okt 2026',
    status: 'Diajukan',
    tone: StatusTone.neutral,
  ),
  (
    category: 'BBM',
    icon: Icons.local_gas_station_outlined,
    amount: 'Rp 300.000',
    date: '6 Okt 2026',
    status: 'Disetujui',
    tone: StatusTone.info,
  ),
  (
    category: 'Parkir',
    icon: Icons.local_parking_outlined,
    amount: 'Rp 20.000',
    date: '3 Okt 2026',
    status: 'Dibayar',
    tone: StatusTone.ok,
  ),
  (
    category: 'Lainnya',
    icon: Icons.receipt_outlined,
    amount: 'Rp 75.000',
    date: '1 Okt 2026',
    status: 'Ditolak',
    tone: StatusTone.err,
  ),
];
