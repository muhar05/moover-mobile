# DESIGN.md: Gaya Visual Moover Driver (Flutter)

Ringkasan gaya visual yang **sudah diimplementasikan** di app driver. Keputusan desain dan statusnya (Disetujui / Usulan aktif / Belum ditentukan) tetap bersumber di `../moover-mobile-planning/DESIGN.md`; file ini tidak menggantikannya. Bila berbeda, planning yang benar, lalu laporkan konfliknya.

Tema: palet **web dashboard** (`../moover-web/Fe-Moover-Dashboard-/src/assets/main.css`, D1 Disetujui; diselaraskan 2026-10-10), gaya "Clean Bright": latar abu sangat terang, kartu putih flat bertepi hairline tanpa shadow, satu blok berwarna (Kartu Agenda) per layar, pill untuk tombol/badge/nav. Jangan menyalin layout web.

Semua token di `lib/ui/core/themes/theme.dart`. Jangan hardcode warna atau spacing di layar; tambah token hanya di file itu.

## Token

```dart
// Skala biru brand (MooverColors, nama sama dengan web)
g900 #074A97  // primary (D1)
g700 #0A5BB5  // secondary; putih 6,61:1
g600 #1167C4
g500 #1A7AD6  // nonteks saja (4,38:1 di putih)
g300 #5AAEF0  // nonteks saja (2,40:1 di putih)
g100 #B8DCFA  // container lembut, pill terpilih; teks #111111 13,2:1
g50  #E8F2FD

// Semantik
primary    = g900      // putih di atasnya 8,62:1
text       #111111     // 17,7:1 di latar
textMuted  #6B7280     // D5; 4,54:1 di latar, 4,83:1 di surface
background #F7F8F7     // web #F5F6F5 dicerahkan: muted di sana hanya 4,46:1
surface    #FFFFFF
hairline   #E4E7E4     // --border web; divider & tepi kartu (dekoratif)

// StatusTone (foreground / background), kandidat, D6
ok #287A4C / #E6F4EA · warn #8E6809 / #FFF6DC · err #CA2923 / #FDE8E7
info #1759EA / #E8EFFD · indigo #4F46E5 / #ECEBFD · neutral #656C79 / #F0F1F0

// MooverSpace
xs 4 · sm 8 · md 12 · lg 16 · xl 24 · xxl 32 · screen 20
// MooverRadius
sm 12 · md 16 · card 20 · lg 24
```

- Nilai di luar skala (6, 10, 18, 28) boleh dipakai untuk komposisi optik, **wajib diberi komentar**.
- Gradient hanya dari palet: Kartu Agenda g700→g900 (sama dengan tombol primary web); Splash #111111→g900→g500.

Font: **Plus Jakarta Sans** dibundel di `assets/fonts/` (Regular, Medium 500, SemiBold 600, Bold 700; OFL). Peran judul (`headlineMedium`, `titleLarge`, `titleMedium`, `titleSmall`) w700 dari tema; ukuran dan line height bawaan M3. Jam, nominal, dan timer: `tabularFigures`.

## Layout

- **Layar**: latar `background`, padding horizontal `screen` 20 dp (Main Menu). Landing/Login masih 24 dp sampai ditinjau.
- **Main Menu** (UD1): 4 tab Beranda / Trip / Reimburse / Akun dalam `IndexedStack` (state tiap tab dipertahankan). Tanpa AppBar; judul tab `headlineMedium` ikut scroll, lalu jarak `xl`, antarbagian 28 dp.
- **Bottom navigation** mengambang: bar putih radius `lg` 24, tepi hairline, shadow `text` 8% blur 24. Margin `md` dari tepi dan safe area. Tab aktif: ikon dalam pill g100 56×32, label w700 `text`, garis g500 16×3 di bawah. Tak aktif: `textMuted` w500. Tinggi tap ≥64 dp; label dibatasi 130% skala teks.
- **Beranda**: sapaan "Halo," (`titleMedium` muted w500) + nama (`headlineMedium`), Kartu Agenda, "Jadwal hari ini", "Reimburse terakhir".
- **Splash**: gradient #111111→g900→g500, logo di bidang putih, fade + scale 600 ms, total ±1,2 dtk. **Landing**: ilustrasi Lottie 35% tinggi layar, diputar sekali. Reduced motion: tanpa animasi.
- Tanpa banner "Data contoh" (dihapus 2026-10-10). Data mock ditandai di kode, bukan di UI.

## Komponen

- **Tombol**: `PrimaryButton` = `FilledButton` pill g900, teks putih, label w500, tinggi visual 40 dp (target sentuh 48). `busy`: spinner 18 dp + nonaktif, latar g100 dan label `text` (13,2:1). Secondary: `OutlinedButton` pill tepi `textMuted`. Text: `TextButton` (dialog). Destruktif dan tinggi 52 dp untuk action bar: **ditunda / Belum ditentukan**.
- **Kartu**: putih, radius `card` 20, tepi hairline, tanpa shadow, margin nol. Baris di dalamnya dipisah `Divider` hairline ber-indent 16.
- **Kartu Agenda** (`MooverAgendaCard`): satu-satunya blok berwarna di Beranda. Gradient g700→g900, radius 20, padding 20/18/20/20. Isi: label g100 + jumlah trip, "Berikutnya" + jam `titleLarge` putih, rute `onDark`, divider g300 50%, pill g100 berisi status clock-in (teks `text` w700) dan jam operasional. **Status saja, tanpa aksi clock-in.**
- **Item trip** (`MooverTripItem`): tanpa kartu, langsung di latar. Jam `titleLarge` + `StatusBadge` (turun baris bila tak muat), rute, penumpang muted. Dibaca TalkBack sebagai satu item.
- **Rute** (`MooverRouteTimeline`): titik isi (asal) dan cincin (tujuan) 10 dp dihubungkan garis 2 dp. Latar terang: titik g900, garis g500. `onDark`: teks putih, titik dan garis g100. Teks boleh membungkus; pembaca layar: "Dari … ke …". Tidak memakai "→".
- **Item reimburse** (`MooverReimburseItem`): avatar ikon bulat r20 (latar `background`, ikon primary), kategori `titleSmall` + nominal `titleMedium` tabular, tanggal muted + badge.
- **StatusBadge**: pill tint (bg muda + teks tone), tinggi ≥24, padding 10/4, `labelMedium` 12sp **w600** (pengecualian disengaja). Selalu teks + warna (D7).
- **Section header**: judul `titleMedium` + trailing `labelLarge` muted (mis. "2 trip").
- **Segmented** (Trip: Hari ini / Riwayat): terpilih g900 + teks putih, tak terpilih putih, tepi `textMuted`.
- **Dialog**: latar putih polos (bukan tint M3). Logout wajib konfirmasi.
- **Avatar akun**: lingkaran g100 r32, inisial `text` `titleLarge`.
- **State** (D10): `SkeletonBox` statis, `ErrorView` (ikon + pesan + "Coba lagi"), `EmptyView` (satu kalimat, aksi opsional).
- Ikon: Material Icons (outlined untuk tak aktif, filled untuk aktif).

## Aksesibilitas (D9)

- Target sentuh ≥48×48 dp; kontras teks ≥4,5:1, nonteks ≥3:1 (cek di setiap stop gradient).
- Layout utuh pada teks 200% di layar 320 dp: baris kiri–kanan memakai `Wrap`, bukan `Row` kaku.
- Header ditandai `Semantics(header)`; elemen dekoratif dikecualikan; item digabung agar dibaca berurutan.
- Rasio kontras ditulis di komentar kode dan diuji di `test/ui/core/design_system_test.dart`.
