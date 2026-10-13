# Debug di Emulator (Hot Reload)

Panduan menjalankan Moover Driver di emulator Android supaya perubahan kode langsung terlihat.

## 0. Sekali saja: tambahkan `adb` dan `emulator` ke PATH

Tambahkan ke `~/.zshrc`, lalu buka terminal baru:

```bash
export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools:$HOME/Library/Android/sdk/emulator"
```

## 1. Nyalakan emulator

```bash
flutter emulators                  # daftar AVD (di sini: Pixel_4)
flutter emulators --launch Pixel_4
flutter devices                    # tunggu sampai muncul emulator-5554
```

## 2. Jalankan app dalam mode debug

Hot reload **hanya bekerja** di mode debug, yaitu `flutter run` tanpa `--profile` atau `--release`.
APK profile (`flutter build apk --profile` + `adb install`) tidak bisa di-hot-reload.

```bash
cd ~/Documents/KAMPUS/ProjectWork/moover-mobile
flutter run -d emulator-5554       # cukup `flutter run` bila hanya ada satu device
```

Biarkan terminal ini terbuka. Ubah kode, lalu tekan tombol berikut di terminal tersebut:

| Tombol | Fungsi | Kapan dipakai |
|---|---|---|
| `r` | **Hot reload**: kode baru dimuat, state tetap (tab, scroll, form) | perubahan UI/widget biasa |
| `R` | **Hot restart**: app mulai ulang dari Splash, state hilang | ubah `initState`, konstanta `static`/top-level (mis. `mock_data.dart`), `main.dart` |
| `p` | garis bantu layout (debug paint) | cek padding/overflow |
| `o` | ganti platform Android ↔ iOS | cek tampilan iOS |
| `v` | buka Flutter DevTools di browser | inspector widget, performa |
| `c` | bersihkan layar terminal | |
| `q` | keluar (app di emulator berhenti) | |

Untuk perubahan berikut, `r`/`R` **tidak cukup**: tekan `q` lalu jalankan `flutter run` lagi.

- `pubspec.yaml`: dependency, aset, atau font baru (jalankan `flutter pub get` dulu);
- file native: `android/`, Gradle, `AndroidManifest.xml`, `Info.plist`.

### Reload otomatis saat file disimpan

- **VS Code:** jalankan lewat *Run → Start Debugging* (F5). Hot reload otomatis tiap kali file disimpan, aktif secara default (`dart.flutterHotReloadOnSave`).
- **Android Studio:** *Run* (Shift+F10). Hot reload saat simpan diatur di *Settings → Languages & Frameworks → Flutter → Perform hot reload on save*.

## 3. Login demo

Employee ID `DEMO001`, kata sandi `demo1234` (lihat `lib/ui/login/login_screen.dart`).

## 4. Command `adb` yang sering dipakai

```bash
adb devices                                          # cek emulator terhubung
adb exec-out screencap -p > shot.png                 # screenshot
adb shell settings put system font_scale 2.0         # teks 200% (uji D9)
adb shell settings put system font_scale 1.0         # WAJIB dikembalikan
adb shell settings get system font_scale             # cek nilainya
# Uji reduced motion (Flutter membaca transition_animation_scale), lalu kembalikan ke 1:
adb shell 'settings put global transition_animation_scale 0; settings put global animator_duration_scale 0'
adb shell 'settings put global transition_animation_scale 1; settings put global animator_duration_scale 1'
adb shell input keyevent 4                           # tombol Back
adb logcat -s flutter                                # log print()/debugPrint saja
adb shell am force-stop com.siagaabdiutama.moover  # tutup paksa app
```

Ubah `font_scale` saat `flutter run` sedang berjalan: app langsung menyesuaikan, tidak perlu reload.

## 5. Cek kode sebelum selesai (wajib, AGENTS.md §5)

```bash
dart format lib test && flutter analyze && flutter test
flutter test test/ui/main_menu                        # satu folder
flutter test --plain-name "tab Reimburse"             # satu tes berdasarkan nama
```

## 6. Kalau macet

| Gejala | Solusi |
|---|---|
| `r` tidak mengubah tampilan | coba `R`; bila masih, `q` lalu `flutter run` |
| `No devices found` | emulator belum menyala; `flutter emulators --launch Pixel_4`, tunggu, `flutter devices` |
| `adb: device offline` | `adb kill-server && adb start-server` |
| build Gradle error setelah ganti branch | `flutter clean && flutter pub get && flutter run` |
| app versi lama (APK profile) masih terpasang | `flutter run` akan menimpanya; atau `adb uninstall com.siagaabdiutama.moover` |
| emulator berat/lambat | tutup lalu cold boot: `emulator -avd Pixel_4 -no-snapshot-load` |

## 7. Uji di HP fisik

Keputusan pemilik project 2026-10-13: verifikasi visual dan perangkat dilakukan di HP fisik, bukan emulator. Fitur dibangun sampai lolos tes otomatis (§5), lalu dicek di HP memakai daftar di bawah.

**Android:** aktifkan *Opsi developer → USB debugging*, sambungkan kabel, izinkan sidik jari komputer di HP, lalu:

```bash
flutter devices                    # HP muncul dengan ID-nya
flutter run -d <id-hp>             # debug + hot reload
flutter run -d <id-hp> --profile   # cek kelancaran animasi/scroll
```

**iOS:** buka `ios/Runner.xcworkspace` di Xcode, pilih Team untuk signing, lalu `flutter run -d <id-iphone>`.

### Daftar yang belum terverifikasi (centang setelah dicek di HP)

| Fitur | Yang dicek |
|---|---|
| Clock-in/out (S04) | kamera depan terbuka; izin kamera ditolak → pesan galat muncul, bisa coba lagi; foto tampil di Bukti kehadiran (S05); tombol "Simulasi tanpa kamera" **tidak ada** di build release |
| Time Log (S05) | ringkasan dan filter; foto asli di sheet Bukti kehadiran |
| Trip (S07–S10) | Beranda → ketuk jadwal → Mulai trip (dialog) → S08; tombol Back HP kembali ke Beranda, banner "Trip berjalan · Lanjutkan" tampil di semua tab; Akhiri trip (centang) → S10 → Selesai; Batalkan dengan alasan |
| Riwayat trip (S12–S13) | tab Trip → Riwayat → ketuk item → S13 (rating + komentar / menunggu feedback / alasan batal); "Cari & filter" → S12: ketik kata kunci, chip status, rentang tanggal (kalender), Reset filter; trip yang diakhiri/dibatalkan hari ini muncul di Riwayat |
| TalkBack / VoiceOver | S12, S13 (kartu feedback dibaca "N dari 5"); S07, S08, S10, banner trip; Beranda, S04, S05: urutan baca, header, label tombol ikon, kartu dibaca utuh |
| Teks 200% | *Pengaturan → Ukuran font* maksimum: tidak ada teks terpotong di semua tab, S04, S05, S07, S08, S10, S12, S13, kalender rentang tanggal, sheet Batalkan/Akhiri |
| Reduced motion | *Hapus animasi* aktif: carousel Landing berhenti, animasi mobil diam |
| Performa | build `--profile`: scroll dan transisi halus, tanpa jank |
| iOS | semua baris di atas di iPhone |
