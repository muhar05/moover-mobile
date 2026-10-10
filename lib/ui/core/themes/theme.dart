import 'package:flutter/material.dart';

// Token desain Moover Driver. Label status mengikuti
// `moover-mobile-planning/DESIGN.md`: "Disetujui" = final; "Usulan aktif" =
// nilai sementara, ubah hanya di file ini.
//
// Palet mengikuti web dashboard (`moover-web/.../src/assets/main.css`) dan
// D1 (Disetujui): primary #074A97 + skala biru g*. Teks utama #111111
// (Usulan aktif), teks sekunder #6B7280 (D5). Rasio kontras di komentar =
// hitungan WCAG, diuji di test/ui/core/design_system_test.dart.

abstract final class MooverColors {
  // Skala biru brand (nama token sama dengan web). Jangan dipakai untuk teks
  // tanpa cek kontras: g500 4,38:1 dan g300 2,40:1 terhadap putih.
  static const g900 = Color(0xFF074A97);
  static const g700 = Color(0xFF0A5BB5);
  static const g600 = Color(0xFF1167C4);
  static const g500 = Color(0xFF1A7AD6);
  static const g300 = Color(0xFF5AAEF0);
  static const g100 = Color(0xFFB8DCFA);
  static const g50 = Color(0xFFE8F2FD);

  // Semantik.
  static const primary = g900; // putih di atasnya 8,62:1
  static const text = Color(0xFF111111); // 17,7:1 di latar, 18,9:1 di surface
  // D5. 4,54:1 di latar, 4,83:1 di surface.
  static const textMuted = Color(0xFF6B7280);
  // Panel web #F5F6F5 sedikit dicerahkan: muted di atas #F5F6F5 hanya
  // 4,46:1 (gagal D9). Keputusan pemilik project 2026-10-10.
  static const background = Color(0xFFF7F8F7);
  static const surface = Color(0xFFFFFFFF);
  // Garis pemisah dekoratif (divider, tepi kartu), --border web. Bukan batas
  // kontrol, jadi tidak wajib 3:1; batas kontrol memakai outline.
  static const hairline = Color(0xFFE4E7E4);
}

/// Tone warna status. Disetujui (prinsip) D6: makna tone mengikuti web.
///
/// Nilai [foreground] adalah KANDIDAT: warna web yang digelapkan (hue tetap)
/// sampai ≥4,5:1 terhadap [background] menurut hitungan WCAG. Belum diuji di
/// perangkat, belum final. Web asli: ok #2E8B57, warn #B7860B, err #E0524D,
/// info #2563EB, neutral #6B7280. Hijau/kuning/merah sengaja tidak diganti
/// palet agar status tetap mudah dibedakan.
enum StatusTone {
  ok(Color(0xFF287A4C), Color(0xFFE6F4EA)),
  warn(Color(0xFF8E6809), Color(0xFFFFF6DC)),
  err(Color(0xFFCA2923), Color(0xFFFDE8E7)),
  info(Color(0xFF1759EA), Color(0xFFE8EFFD)),
  indigo(Color(0xFF4F46E5), Color(0xFFECEBFD)),
  neutral(Color(0xFF656C79), Color(0xFFF0F1F0));

  const StatusTone(this.foreground, this.background);
  final Color foreground;
  final Color background;
}

// Usulan aktif (audit typography/spacing 2026-10-10), belum di DESIGN.md
// (§4.3 "Belum ditentukan"). Skala kelipatan 4. Nilai lain (6, 10, 18, 28)
// sengaja dipertahankan di tempat pemakaiannya untuk komposisi optik.
abstract final class MooverSpace {
  static const xs = 4.0, sm = 8.0, md = 12.0, lg = 16.0, xl = 24.0, xxl = 32.0;
  // Padding horizontal layar. Baru Main Menu; Landing/Login (24) menyusul.
  static const screen = 20.0;
}

// Usulan aktif, belum di DESIGN.md. card: kartu biasa dan Agenda (20, tetap);
// lg: bar navigasi mengambang.
abstract final class MooverRadius {
  static const sm = 12.0, md = 16.0, card = 20.0, lg = 24.0;
}

// Disetujui (D2): font dibundel sebagai aset.
const mooverFontFamily = 'PlusJakartaSans';

// Disetujui (D2): angka jam, timer, dan nominal memakai tabular figures.
const tabularFigures = [FontFeature.tabularFigures()];

ThemeData mooverTheme() {
  final scheme =
      ColorScheme.fromSeed(
        // Seed #074A97 (UD3): warna turunan M3 (surfaceContainer dialog/nav
        // bar) ikut keluarga biru brand. Tanpa dark mode di v1 (UD3).
        seedColor: MooverColors.primary,
      ).copyWith(
        primary: MooverColors.primary,
        onPrimary: MooverColors.surface,
        // Container lembut: teks di atas g100 13,2:1.
        primaryContainer: MooverColors.g100,
        onPrimaryContainer: MooverColors.text,
        // Aksen g700: putih 6,61:1 (g500 hanya 4,38:1).
        secondary: MooverColors.g700,
        onSecondary: MooverColors.surface,
        // Elemen terpilih (indikator M3 bawaan): teks di atas g300 7,87:1.
        secondaryContainer: MooverColors.g300,
        onSecondaryContainer: MooverColors.text,
        surface: MooverColors.surface,
        // Turunan seed #074A97 terlalu gelap untuk muted D5 (4,15:1); samakan
        // dengan latar (4,54:1). Dipakai NavigationBar/menu bawaan M3.
        surfaceContainer: MooverColors.background,
        onSurface: MooverColors.text,
        onSurfaceVariant: MooverColors.textMuted,
        outline: MooverColors.textMuted,
        outlineVariant: MooverColors.hairline, // warna bawaan Divider
        // error tetap bawaan M3 #BA1A1A: 6,07:1 di latar, 6,46:1 di surface.
      );

  return ThemeData(
    colorScheme: scheme,
    fontFamily: mooverFontFamily,
    // Usulan aktif: peran judul tebal (w700) ditetapkan sekali di sini.
    // Ukuran dan line height tetap bawaan M3. headlineSmall tidak diubah:
    // dipakai judul dialog bawaan.
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontWeight: FontWeight.w700),
      titleLarge: TextStyle(fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontWeight: FontWeight.w700),
      titleSmall: TextStyle(fontWeight: FontWeight.w700),
    ),
    scaffoldBackgroundColor: MooverColors.background,
    // Disetujui (D9): target sentuh ≥48dp. Belum diuji di perangkat.
    materialTapTargetSize: MaterialTapTargetSize.padded,
    // Usulan aktif (UD3): kartu flat tanpa shadow, tepi hairline. Radius 20:
    // usulan redesign Main Menu, belum di DESIGN.md. Tombol pill = bawaan M3.
    cardTheme: const CardThemeData(
      elevation: 0,
      color: MooverColors.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(MooverRadius.card)),
        side: BorderSide(color: MooverColors.hairline),
      ),
    ),
    // Sementara (teknis): desain app bar Belum ditentukan. Samakan dengan latar
    // dan matikan tint scroll M3 sampai desain app bar ditetapkan.
    appBarTheme: const AppBarTheme(
      backgroundColor: MooverColors.background,
      scrolledUnderElevation: 0,
    ),
    // Dialog putih polos, bukan tint M3: teks dan tombol diuji di atas surface.
    dialogTheme: const DialogThemeData(backgroundColor: MooverColors.surface),
    // Segmen terpilih primary + teks putih (8,62:1); tepi outline (4,83:1).
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: MooverColors.surface,
        foregroundColor: MooverColors.text,
        selectedBackgroundColor: MooverColors.primary,
        selectedForegroundColor: MooverColors.surface,
        side: const BorderSide(color: MooverColors.textMuted),
      ),
    ),
  );
}
