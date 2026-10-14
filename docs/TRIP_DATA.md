# Data Trip yang Dibutuhkan Aplikasi Driver

Status: **Usulan** dari tim mobile (2026-10-14), untuk dibahas dengan backend. Kontrak API trip (U10–U18 di `API_CONTRACT.md`) **belum Terverifikasi**.

Sumber aturan: KAK §5.1.3–5.1.8, §6.1, §6.2 (`BUSINESS_RULES.md` §1.4). Layar: S06 Jadwal hari ini, S07 Detail, S08 Active Trip, S09 Tambah tujuan, S10 QR Feedback, S11 Add New Trip (Tipe A), S12–S13 Riwayat.

Untuk demo, trip Tipe A dan hasil simulasi Start/Cancel/End disimpan di SQLite perangkat (`lib/ui/trip/trip_store.dart`, tabel `trip`, `trip_state`, dan `trip_stop`). Jadwal dari Admin/GA masih konstanta mock.

## 1. Enum

| Field | Nilai (API) | Label UI | Sumber |
|---|---|---|---|
| `type` | `A`, `B` | — (Tipe A: input driver; Tipe B: request pegawai) | KAK §6.2 |
| `status` | `scheduled`, `on_trip`, `waiting_feedback`, `completed`, `canceled` | Terjadwal, Dalam Perjalanan, Menunggu Feedback, Selesai, Dibatalkan | DESIGN.md §4.7 |

Penamaan nilai enum di API: **Perlu konfirmasi**. Mobile dapat memetakan nilai apa pun. Demo menyimpan `on_trip`, `waiting_feedback`, `canceled`; Terjadwal = tanpa baris.

## 2. Trip (S06, S07, S12, S13)

| Field | Tipe | Wajib | Catatan |
|---|---|---|---|
| `id` | string/int | ya | ID server |
| `number` | string | ya | diterbitkan sistem. Format `TRP-YYYYMMDD-NNNN` hanya dari mock web |
| `type` | enum | ya | §1 |
| `request_number` | string \| null | saat `B` | nomor request pegawai (KAK §6.2) |
| `scheduled_at` | datetime ISO 8601 + zona waktu | ya | waktu jemput; UI menampilkan WIB. Tipe A: saat dibuat (seperti mock web), **Perlu konfirmasi** |
| `origin` | string | ya | lokasi jemput. Untuk Tipe A tidak disebut KAK: **Perlu konfirmasi** (diisi driver atau dari GPS) |
| `destination` | string | ya | tujuan awal |
| `destination_address` | string \| null | tidak | alamat lengkap (S06). Tipe A: diketik driver manual di S11, opsional (permintaan pemilik project 2026-10-14). Demo: kolom `trip.destination_address` |
| `origin_coords`, `destination_coords` | `{lat, lng}` | ya untuk Tipe A (usulan) | untuk peta S07/S08. S11 memilih titik di peta (keputusan pemilik project 2026-10-14); `origin`/`destination` diisi otomatis dari titik (reverse geocoding), tidak diketik, agar nama dan titik tidak berbeda (koreksi 2026-10-14). Demo: Nominatim publik; tidak ditemukan/offline = koordinat. Jadwal tanpa koordinat: peta tidak ditampilkan |
| `stops` | array of `{name, address?, coords?, arrived_at?}` | ya (usulan) | daftar tujuan berurutan, indeks 0 = `destination`. Driver menambah tujuan saat trip berjalan seperti "add stops" Google Maps (keputusan pemilik project 2026-10-14, Q-B4) dan menandai tiba berurutan (KAK §6.1 langkah 4); tujuan terakhir tiba saat End Trip. Driver tidak menghapus/mengubah tujuan: keputusan ada di pemesan dan alurnya lewat approval (keputusan pemilik project 2026-10-14, belum diimplementasikan). `address` diketik manual, opsional. Bentuk mirip `TripDestination` web (`arrivedAt`). Demo: tabel `trip_stop (trip_number, seq, name, address, lat, lng, arrived_at)` |
| `passengers` | array of `{name, division}` | ya | KAK §5.1.6. Demo: satu penumpang. Teks bebas atau pilih karyawan (ID): **Perlu konfirmasi** (K5) |
| `status` | enum | ya | §1 |
| `started_at` | datetime \| null | saat `on_trip` dst. | memulihkan trip berjalan setelah app dibuka ulang |
| `ended_at` | datetime \| null | saat selesai | jam tiba (S13) |
| `cancel_reason` | string \| null | saat `canceled` | wajib atau tidak: **Perlu konfirmasi** (Q-B3) |
| `feedback` | `{rating 1–5, comment?}` \| null | saat `completed` | dari QR feedback penumpang (S10, S13) |

Daftar hari ini (S06) dan riwayat (S12) cukup memuat `id, number, scheduled_at, origin, destination, passengers, status`. Riwayat: pencarian, filter status dan rentang tanggal (KAK §5.1.8). Paging: **Belum ditentukan**.

## 3. Request dari mobile

| Aksi | Body | Respons yang dibutuhkan |
|---|---|---|
| Add New Trip (U17) | `passengers: [{name, division}], destination, destination_address?`, usulan `origin`, `origin_coords`, `destination_coords` | Trip §2 (nomor untuk konfirmasi S11) |
| Start Trip (U11) | — | `status, started_at` |
| Cancel Trip (U12) | `reason?` | `status` |
| Tambah tujuan (U13) | `name, address?, coords` | `stops` |
| Tiba di tujuan (U14) | `seq` (atau `stop_id`) | `stops` |
| End Trip (U15) | — | `status, ended_at`, data QR (U16) |
| Hari ini / Detail (U10) | — | §2 |
| Riwayat (U18) | query `q?, status?, from?, to?` | §2 ringkas; detail + `feedback` |

Error per field (mis. `{"field": "destination", "message": "..."}`) dibutuhkan untuk validasi per field di S11. Format error: **Belum ditentukan**.

## 4. Pertanyaan terbuka

- Q-B1: definisi "Available" dan siapa yang boleh membuat Add New Trip. Demo: hanya setelah clock-in.
- K5: format input penumpang (teks bebas atau daftar karyawan), jumlah penumpang per trip.
- Lokasi jemput Tipe A: diisi driver, dari GPS (terkait Q-T4), atau tidak ada.
- Rute jalan (garis peta S07/S08/S11) untuk produksi: lewat backend (Q-T6). Demo memanggil OSRM publik langsung dari HP; gagal/offline = garis lurus.
- Pencarian tempat (search bar S11) untuk produksi: lewat backend; demo memanggil Nominatim publik `/search` (tanpa autocomplete, sesuai kebijakannya).
- Reverse geocoding untuk produksi: lewat backend (demo memanggil Nominatim publik langsung dari HP; kebijakannya maks. 1 permintaan/detik, tidak untuk produksi).
- Q-B4 lanjutan: perubahan tujuan (hapus/urut ulang) diajukan pemesan; alur approval-nya **Belum ditentukan**. Driver tidak bisa mengubah tujuan (keputusan pemilik project 2026-10-14). End Trip wajib menunggu semua tujuan antara ditandai tiba? Demo: End menandai sisa tujuan tiba.
- Panjang maksimum alamat manual: 200 karakter (keputusan pemilik project 2026-10-14, sementara).
- Q-B2: clock-in wajib sebelum Start Trip.
- Q-B3: kapan boleh membatalkan; alasan wajib atau tidak.
- Q-T3: isi dan keamanan QR feedback.
- Q-T5: aksi saat offline (antrean di perangkat atau tolak).
