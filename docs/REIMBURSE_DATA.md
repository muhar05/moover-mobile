# Data Reimburse yang Dibutuhkan Aplikasi Driver

Status: **Usulan** dari tim mobile (2026-10-14), untuk dibahas dengan backend. Kontrak API reimburse (U20–U24 di `API_CONTRACT.md`) **belum Terverifikasi**.

Sumber aturan: KAK §5.1.15–16, §5.5.2, §5.6.2, §6.4, §6.7 (`BUSINESS_RULES.md` §1.7). Layar: S14 Daftar, S15 Form (baru/ajukan ulang), S16 Detail & Timeline.

Untuk demo, data ini disimpan di SQLite perangkat (`lib/ui/reimburse/reimburse_store.dart`). Tipe Dart dan skema SQL di file tersebut mencerminkan tabel di bawah.

## 1. Enum

| Field | Nilai (API) | Label UI | Sumber |
|---|---|---|---|
| `category` | `toll`, `parking`, `fuel`, `other` | Tol, Parkir, BBM, Lainnya | KAK §5.1.15 |
| `status` | `submitted`, `approved`, `rejected`, `paid` | Diajukan, Disetujui, Ditolak, Dibayar | KAK §6.7, DESIGN.md §4.7 |

Penamaan nilai enum di API: **Perlu konfirmasi**. Mobile dapat memetakan nilai apa pun.

## 2. Reimbursement (S14, S16)

| Field | Tipe | Wajib | Catatan |
|---|---|---|---|
| `id` | string/int | ya | ID server |
| `number` | string | ya | diterbitkan sistem (KAK §5.1.15). Format `RMB-YYYYMM-NNNN` hanya dari mock web |
| `expense_date` | date (`YYYY-MM-DD`) | ya | tanggal pengeluaran |
| `category` | enum | ya | §1 |
| `amount` | integer (Rupiah) | ya | > 0. Batas maksimum: **Perlu konfirmasi** (Q-B6) |
| `description` | string | ya | keterangan. Batas panjang: **Belum ditentukan** (demo 200 karakter) |
| `trip_number` | string \| null | tidak | trip terkait, opsional (KAK §5.1.15). Perlu konfirmasi: kirim ID atau nomor trip |
| `receipt_photo_url` | string | ya | foto nota. Format, ukuran, dan mekanisme upload: **Perlu konfirmasi** (Q-T1) |
| `status` | enum | ya | status terkini |
| `rejection_note` | string \| null | — | catatan penolakan terakhir. Bisa diturunkan dari timeline; cukup salah satu |
| `transfer` | object \| null | saat `paid` | §4 |
| `timeline` | array | ya (di detail) | §3. Di daftar (S14) boleh tidak dikirim |

Daftar (S14) cukup memuat `id, number, expense_date, category, amount, status`, dengan filter `status` (KAK §5.1.16). Urutan terbaru dulu. Paging: **Belum ditentukan**.

## 3. TimelineEntry (S16)

Setiap tahap mencatat waktu, pelaku, dan catatan (KAK §6.4 langkah 5). Riwayat penolakan **tidak dihapus** saat diajukan ulang (§6.4 langkah 3).

| Field | Tipe | Wajib | Catatan |
|---|---|---|---|
| `status` | enum | ya | status hasil tahap ini |
| `at` | datetime ISO 8601 + zona waktu | ya | UI menampilkan WIB |
| `actor_name` | string | ya | mis. nama Group Head HC / Finance. Nama atau peran: **Perlu konfirmasi** |
| `actor_role` | string | usulan | `driver`, `approver`, `finance` |
| `note` | string \| null | wajib saat `rejected` | KAK §5.5.2 |

## 4. Transfer (S16, saat `paid`)

Finance mengisi tanggal dan nominal transfer serta mengunggah bukti (KAK §5.6.2).

| Field | Tipe | Wajib | Catatan |
|---|---|---|---|
| `transfer_date` | date | ya | |
| `transfer_amount` | integer (Rupiah) | ya | bisa berbeda dari `amount`? **Perlu konfirmasi** |
| `proof_url` | string | ya | gambar atau PDF |
| `proof_mime` | string | usulan | agar mobile tahu cara membuka (gambar/PDF) |

## 5. Request dari mobile

| Aksi | Body | Respons yang dibutuhkan |
|---|---|---|
| Ajukan (U21) | `expense_date, category, amount, description, trip_number?, receipt_photo` | `id, number, status` (nomor untuk konfirmasi S15) |
| Ajukan ulang (U23) | sama dengan Ajukan, hanya untuk status `rejected` | status kembali `submitted`, timeline bertambah |
| Daftar (U22) | query `status?` | §2 ringkas |
| Detail (U22) | — | §2 lengkap + §3 + §4 |

Error per field (mis. `{"field": "amount", "message": "..."}`) dibutuhkan untuk validasi per field di S15 (DESIGN.md S15). Format error: **Belum ditentukan**.

## 6. Pertanyaan terbuka

- Q-B6: foto nota hanya kamera atau juga galeri; batas nominal.
- Q-T1: upload foto (multipart atau URL terpisah, ukuran maksimum).
- Q-T2 / U24: notifikasi perubahan status (push atau polling).
- Q-T5: pengajuan saat offline (antrean di perangkat atau tolak).
- Siapa yang boleh mengubah `trip_number` dan apakah trip harus milik driver itu.
