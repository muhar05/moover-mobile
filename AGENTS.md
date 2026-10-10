# AGENTS.md — Moover Driver (Flutter, Mock/Demo)

> Panduan untuk AI coding agent (Claude Code, Codex, Cursor, dll.) dan developer yang mengerjakan **aplikasi mobile driver Moover** untuk PT. Siaga Abdi Utama.
> Baca seluruh file ini sebelum menulis kode. Untuk keputusan desain dan bisnis, sumber kebenarannya adalah dokumen planning (§3), bukan file ini.

---

## 1. Ringkasan Project

Moover adalah sistem pengelolaan layanan transportasi internal perusahaan:

- **aplikasi mobile Flutter untuk driver** — repo ini;
- backend Golang REST API + PostgreSQL;
- portal web pegawai;
- web dashboard pengelola/approver (`../moover-web/`).

Fase saat ini **frontend dengan data MOCK/DEMO**:

- Tidak ada backend. Login memakai kredensial demo hardcode di `lib/ui/login/login_screen.dart`.
- Tidak ada sesi tersimpan, token, atau panggilan jaringan.
- Data layar (trip, reimburse) adalah konstanta mock di `mock_data.dart` fitur, ditandai `MOCK/DEMO`.

---

## 2. Ruang Lingkup

### In scope (sudah ada)

| Layar | File | Catatan |
|---|---|---|
| S00 Splash | `lib/ui/splash/splash_screen.dart` | selalu lanjut ke Landing (cek sesi belum ada) |
| S01 Landing | `lib/ui/landing/landing_screen.dart` | ilustrasi Lottie, hormati reduced motion |
| S02 Login | `lib/ui/login/login_screen.dart` | Employee ID + kata sandi, mock |
| Main Menu | `lib/ui/main_menu/main_menu_screen.dart` | 4 tab: Beranda, Trip, Reimburse, Akun |

### Out of scope (jangan dikerjakan tanpa keputusan pemilik project)

- Backend, autentikasi sungguhan, penyimpanan sesi, push notification sungguhan.
- Aksi clock-in/out, Start/End Trip, form reimburse: aturannya masih **Perlu konfirmasi**.
- Kamera, GPS, peta, QR: penanganan izin ditolak **Belum ditentukan**.
- Repo web dan dokumen planning: **hanya dibaca**.

---

## 3. Sumber Kebenaran

Dokumen planning ada di `../moover-mobile-planning/` dan **read-only**:

| File | Isi |
|---|---|
| `CLAUDE.md` | aturan kerja agent untuk project ini |
| `PROJECT_CONTEXT.md` | titik mulai; baca ini dulu |
| `DESIGN.md` | keputusan desain (D1–D11, UD1–UD4), spesifikasi layar S00–S22 |
| `BUSINESS_RULES.md` | aturan bisnis dan pertanyaan terbuka (Q-B*, Q-T*) |
| `API_CONTRACT.md` | kontrak API; hanya baris **Terverifikasi** yang boleh dianggap ada |
| `KAK_EXTRACT.md` | ekstrak KAK |
| `WEB_AUDIT.md` | audit repo web; mock web **bukan** aturan |

Aturan:

- Prioritas sumber: **KAK > keputusan pemilik project > mock web**.
- Status label di `DESIGN.md`: hanya **Disetujui** yang final. **Usulan aktif** boleh dipakai tetapi bukan keputusan final.
- Yang belum pasti diberi label **Belum ditentukan / Belum terverifikasi / Perlu konfirmasi**. Jangan menebak.
- Bila sumber bertentangan, catat konfliknya dan tanya pemilik project.
- Keputusan pemilik project yang belum tercatat di `DESIGN.md` ditulis sebagai komentar di kode (dengan tanggal), bukan dengan mengedit `DESIGN.md`.

---

## 4. Tech Stack

| Area | Pilihan |
|---|---|
| SDK | Flutter 3.47.1 / Dart 3.13.1 (`sdk: ^3.13.1`) |
| UI | Material 3, tema custom `mooverTheme()` |
| Font | Plus Jakarta Sans, dibundel di `assets/fonts/` (OFL) |
| Animasi | `lottie` (satu-satunya dependency runtime) |
| Lint | `flutter_lints` |
| Test | `flutter_test` |
| App ID | `com.siagaabdiutama.moover_driver` |

**Belum ditentukan:** state management, routing package, HTTP client, struktur folder lanjutan.

**Jangan** upgrade Flutter, menambah dependency, atau mengubah konfigurasi (`pubspec.yaml`, `analysis_options.yaml`, `.gitignore`, Gradle, Info.plist, app ID) tanpa melapor dan mendapat persetujuan.

---

## 5. Perintah

```bash
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run                                   # debug di emulator/perangkat
flutter build apk --profile --target-platform android-arm64
```

**Sebelum menyatakan task selesai, wajib lolos:** `dart format lib test && flutter analyze && flutter test`.

---

## 6. Struktur Folder

```
lib/
  main.dart              # MainApp, lisensi font, home = SplashScreen
  ui/                    # pola "ui/core + ui/<fitur>" (panduan arsitektur Flutter)
    core/
      themes/theme.dart  # token: MooverColors, StatusTone, MooverSpace, MooverRadius, mooverTheme()
      widgets/           # satu file per komponen (lihat §7.3); impor lewat widgets.dart (barrel)
    splash/splash_screen.dart
    landing/landing_screen.dart
    login/login_screen.dart
    main_menu/
      main_menu_screen.dart
      mock_data.dart     # MOCK/DEMO: data trip & reimburse
test/                    # mencerminkan lib/
  ui/core/design_system_test.dart  # token, kontras, komponen; ekspor helper contrast()
  ui/<fitur>/<fitur>_screen_test.dart
assets/
  animations/  brand/  fonts/
```

- Nama file `snake_case`; layar = `<fitur>_screen.dart`, kelas `<Fitur>Screen`.
- Fitur baru: folder baru di `lib/ui/<fitur>/` + tes di `test/ui/<fitur>/`.
- Fewest files: jangan membuat folder/abstraksi baru (`data/`, `domain/`, view model, repository, service, provider) sebelum ada kebutuhan nyata (mis. backend) dan persetujuan.

---

## 7. Design System

Ringkasan visual yang sudah diimplementasikan: `DESIGN.md` di root repo ini. Keputusan final tetap di `../moover-mobile-planning/DESIGN.md`.

### 7.1 Token (`lib/ui/core/themes/theme.dart`)

- **Warna — palet web dashboard** (`main.css`, D1 Disetujui): skala biru g900 `#074A97` (primary), g700 `#0A5BB5`, g600 `#1167C4`, g500 `#1A7AD6`, g300 `#5AAEF0`, g100 `#B8DCFA`, g50 `#E8F2FD`; teks `#111111`, muted `#6B7280` (D5), latar `#F7F8F7`, hairline `#E4E7E4`.
  - Pakai nama semantik (`MooverColors.primary`, `text`, `textMuted`, `background`, `surface`, `hairline`).
  - **g500 dan g300 tidak boleh dipakai sebagai warna teks di atas putih** (kontras gagal).
  - Latar sengaja `#F7F8F7`, bukan `#F5F6F5` web: muted di atas `#F5F6F5` hanya 4,46:1.
  - Jangan hardcode warna di layar. Tambah token hanya di `theme.dart`.
- **StatusTone:** ok, warn, err, info, indigo, neutral. Status selalu **teks + warna** (D7); tone tidak disamakan.
- **Spacing `MooverSpace`:** xs 4, sm 8, md 12, lg 16, xl 24, xxl 32; `screen` 20 (padding horizontal layar).
- **Radius `MooverRadius`:** sm 12, md 16, card 20, lg 24.
- **Nilai di luar skala** (6, 10, 18, 28) boleh dipertahankan untuk komposisi optik, **dengan komentar** alasannya. Jangan memaksa semua nilai ke kelipatan 4.
- **Typography:** `headlineMedium`, `titleLarge`, `titleMedium`, `titleSmall` = w700 (dari tema). Ukuran dan line height bawaan M3. Angka jam/nominal memakai `tabularFigures`.

### 7.2 Keputusan yang sudah diambil pemilik project (2026-10-10)

- Padding layar 20 dp: baru diterapkan di Main Menu dan widgets. Landing, Login, Splash menyusul **setelah ditinjau**.
- `StatusBadge` tetap **w600** (pengecualian disengaja).
- Radius kartu biasa dan Kartu Agenda tetap **20 dp**.
- Banner "Data contoh" / MOCK-DEMO **dihapus** dari semua tab. Jangan mengembalikannya. (`DESIGN.md` D10 belum diperbarui.)
- Letter spacing 0.5 pada badge dan label navigasi (dari `labelMedium`) dibiarkan.
- Palet mengikuti web dashboard: latar `#F7F8F7`, Kartu Agenda g700→g900, Splash `#111111`→g900→g500.
- `PrimaryButton` saat `busy`: latar g100 + label `text` (13,2:1). Tinggi 52 dp untuk aksi utama **ditunda** sampai action bar didesain. Weight label tombol tetap 500.

### 7.3 Komponen (`lib/ui/core/widgets/`)

| Komponen | Fungsi |
|---|---|
| `MooverLogo` | logo brand |
| `MooverBottomNavigation` | bottom nav mengambang 4 tab, semantik tab terpilih |
| `MooverSectionHeader` | judul bagian + trailing muted |
| `MooverRouteTimeline` | rute asal → tujuan vertikal; `onDark` untuk latar gelap; satu label semantik |
| `MooverTripItem` | baris trip (jam, status, rute, penumpang) |
| `MooverAgendaCard` | kartu Agenda Hari Ini (gradient g700→g900), **status clock-in saja, tanpa aksi** |
| `MooverReimburseItem` | baris pengajuan reimburse |
| `PrimaryButton` | tombol aksi utama; `busy` = spinner + nonaktif (D10) |
| `StatusBadge` | label status + tone |
| `ErrorView`, `EmptyView`, `SkeletonBox` | state UI (D10) |

Aturan komponen:

- Periksa komponen yang ada sebelum membuat yang baru.
- Komponen reusable menerima data lewat **parameter**, tidak membaca data mock.
- Layar memakai adapter tipis (`_TripItem`, `_ReimburseItem`) dari tipe mock ke komponen.
- Jangan membuat wrapper untuk satu widget sederhana tanpa manfaat reuse atau pemisahan tanggung jawab.
- Tombol sekunder/text memakai `OutlinedButton`/`TextButton` bawaan yang sudah di-theme. Varian destructive **Belum ditentukan**.

---

## 8. Aturan Bisnis

- Ikuti `BUSINESS_RULES.md` dan `DESIGN.md` §4.7 (label status). Jangan mengarang aturan.
- **Clock-in:** UI hanya menampilkan status. Jangan membuat tombol, GPS, selfie, atau pesan "berhasil" palsu.
- **Success** hanya ditampilkan setelah server mengonfirmasi (D10). Saat ini belum ada server.
- Disabled karena aturan bisnis: **Perlu konfirmasi** (Q-B1, Q-B2).
- Navigasi saat ini:
  - Landing → Login → Main Menu memakai `pushAndRemoveUntil`; Back dari Main Menu tidak kembali ke Login.
  - Logout lewat dialog konfirmasi, lalu ke Login tanpa riwayat.
- Jangan mengubah data mock, navigasi, login/logout, atau alur clock-in kecuali diminta.

---

## 9. Konvensi UI/UX

- **Bahasa UI: Bahasa Indonesia.** Istilah KAK dipakai apa adanya: *driver, trip, reimburse, clock-in/out, Start/End Trip*.
- **Format (D4):** `Rp 45.000`, `8 Okt 2026`, `09.30 WIB`, `Jam operasional 07.30–16.30`.
- **Aksesibilitas (D9):**
  - target sentuh ≥48×48 dp;
  - kontras teks ≥4,5:1, elemen non-teks ≥3:1 (cek setiap stop gradient);
  - layout utuh pada teks 200% di layar 320 dp;
  - semantik: header ditandai, label tombol ikon, item digabung (`MergeSemantics`) agar dibaca berurutan;
  - hormati reduced motion (`MediaQuery.disableAnimationsOf`).
- State loading (skeleton / spinner tombol), empty, dan error mengikuti D10.
- Jangan menyalin layout web.

---

## 10. Konvensi Kode

- **Identifier** dalam bahasa Inggris; **komentar dan teks UI** dalam Bahasa Indonesia (ikuti gaya file yang ada).
- Komentar mencatat status keputusan (`Disetujui (Dx)`, `Usulan aktif`, `Belum ditentukan`) dan rasio kontras bila relevan.
- Penyederhanaan yang disengaja ditandai `// ponytail:` beserta batas dan jalur upgrade-nya.
- Kode privat layar diawali `_`. Komponen publik di `lib/ui/core/widgets/` diawali `Moover`; komponen baru = file baru + baris `export` di `widgets.dart`.
- Ikuti `dart format`; tanpa warning `flutter analyze`.
- Tidak ada secret atau API key di kode, log, atau laporan.

---

## 11. Testing

- **Jangan menghapus atau melemahkan tes lama.** Bila komponen dihapus atas permintaan, ubah tesnya menjadi pemeriksaan ketiadaan, lalu laporkan.
- Pola yang dipakai:
  - `contrast()` dari `design_system_test.dart` untuk kontras WCAG;
  - `tester.view.physicalSize = Size(960, 1704)` + `devicePixelRatio = 3` untuk layar 320 dp, `TextScaler.linear(2)` untuk teks 200%;
  - `isSemantics(...)` untuk label pembaca layar;
  - `meetsGuideline(androidTapTargetGuideline / labeledTapTargetGuideline)`;
  - `skipOffstage: false` untuk memeriksa tab yang tidak tampil (`IndexedStack`).
- Data di tes komponen memakai nilai **non-mock** agar terbukti datang dari parameter.
- Untuk tes baru yang penting, lakukan **uji mutasi**: rusak kodenya sementara, pastikan tes gagal, lalu kembalikan.

---

## 12. Verifikasi Emulator (opsional)

- AVD `Pixel_4` (API 34, 1080×2280); `adb` di `~/Library/Android/sdk/platform-tools`.
- Install: build APK profile (§5), lalu `adb install -r build/app/outputs/flutter-apk/app-profile.apk`.
- Teks 200%: `adb shell settings put system font_scale 2.0`; **kembalikan ke 1.0** setelah selesai.
- Screenshot: `adb exec-out screencap -p > shot.png`.
- **Jangan mengklaim verifikasi emulator, perangkat fisik, TalkBack, atau iOS bila belum benar-benar dilakukan.**

---

## 13. Definition of Done

- [ ] Sesuai `DESIGN.md` / keputusan pemilik project; tidak ada perubahan di luar cakupan task.
- [ ] Token dipakai; tidak ada warna/spacing hardcode tanpa alasan.
- [ ] Kontras, target sentuh, teks 200%, dan semantik diuji.
- [ ] Tes baru untuk perilaku baru; tes lama tetap ada.
- [ ] `dart format`, `flutter analyze`, `flutter test` lolos.
- [ ] Diff ditinjau; laporan menyebut file yang berubah, hasil tes, dan **hal yang belum diverifikasi**.

---

## 14. Larangan untuk Agent

- ❌ Commit atau push tanpa diminta.
- ❌ Mengubah dokumen planning (`../moover-mobile-planning/`), termasuk `DESIGN.md`, tanpa persetujuan.
- ❌ Mengubah repo web (`../moover-web/`).
- ❌ Membaca atau menampilkan file secret (`.env*`, `9router.json`) atau API key.
- ❌ Upgrade Flutter, menambah dependency, atau mengubah konfigurasi/app ID tanpa persetujuan.
- ❌ Mengembalikan banner "Data contoh" / MOCK-DEMO.
- ❌ Membuat aksi clock-in, GPS, atau selfie palsu; menampilkan success sebelum dikonfirmasi server.
- ❌ Menganggap endpoint ada bila belum **Terverifikasi** di `API_CONTRACT.md`.
- ❌ Memakai data pribadi asli.
- ❌ Mengubah Landing, Login, atau Splash sebelum tahap peninjauannya disetujui.
- ❌ Melanjutkan ke layar/sprint berikutnya tanpa berhenti untuk ditinjau bila diminta.
