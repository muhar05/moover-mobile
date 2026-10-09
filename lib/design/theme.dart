import 'package:flutter/material.dart';

// Token desain Moover Driver. Label status mengikuti
// `moover-mobile-planning/DESIGN.md`: "Disetujui" = final; "Usulan aktif" =
// nilai sementara, ubah hanya di file ini.
//
// Palet Aqua Nebula (usulan pemilik project 2026-10-09) menggantikan biru D1
// (#074A97), teks muted D5 (#6B7280), dan latar/teks UD3. Belum dicatat di
// DESIGN.md. Rasio kontras di komentar = hitungan WCAG, diuji di
// test/design_system_test.dart.

abstract final class MooverColors {
  // Palet sumber. Jangan dipakai langsung untuk teks tanpa cek kontras:
  // teal 3,02:1 dan surf 1,90:1 terhadap putih (gagal untuk teks normal).
  static const abyss = Color(0xFF061826); // Midnight Abyss
  static const steel = Color(0xFF1C4E75); // Atlantic Steel
  static const teal = Color(0xFF2FA0C6); // Tidepool Teal
  static const surf = Color(0xFF58C9F3); // Summer Surf
  static const mist = Color(0xFFBDE5FF); // Glacier Mist

  // Semantik.
  static const primary = steel; // putih di atasnya 8,76:1
  static const text = abyss; // 16,7:1 di latar, 18,0:1 di surface
  // Turunan steel yang lebih terang (bukan warna palet): teks sekunder,
  // garis input, outline. 6,00:1 di latar, 6,46:1 di surface.
  static const textMuted = Color(0xFF46617A);
  // Glacier Mist 25% di atas putih: latar lembut. Mist penuh membuat kartu
  // putih nyaris tak terbedakan (1,33:1) dan muted turun ke 4,86:1.
  static const background = Color(0xFFEEF8FF);
  static const surface = Color(0xFFFFFFFF);
  // Garis pemisah dekoratif (divider, tepi kartu). Bukan batas kontrol, jadi
  // tidak wajib 3:1; batas kontrol (input, tombol outline) memakai outline.
  static const hairline = Color(0xFFD7E6F2);
}

/// Tone warna status. Disetujui (prinsip) D6: makna tone mengikuti web.
///
/// Nilai [foreground] adalah KANDIDAT: warna web yang digelapkan (hue tetap)
/// sampai ≥4,5:1 terhadap [background] menurut hitungan WCAG. Belum diuji di
/// perangkat, belum final. Web asli: ok #2E8B57, warn #B7860B, err #E0524D,
/// info #2563EB, neutral #6B7280. Hijau/kuning/merah sengaja tidak diganti
/// palet agar status tetap mudah dibedakan; info memakai steel + mist tipis
/// (lebih jauh dari indigo dibanding biru web).
enum StatusTone {
  ok(Color(0xFF287A4C), Color(0xFFE6F4EA)),
  warn(Color(0xFF8E6809), Color(0xFFFFF6DC)),
  err(Color(0xFFCA2923), Color(0xFFFDE8E7)),
  info(MooverColors.steel, Color(0xFFDDF0FF)),
  indigo(Color(0xFF4F46E5), Color(0xFFECEBFD)),
  neutral(Color(0xFF656C79), Color(0xFFF0F1F0));

  const StatusTone(this.foreground, this.background);
  final Color foreground;
  final Color background;
}

// Disetujui (D2): font dibundel sebagai aset.
const mooverFontFamily = 'PlusJakartaSans';

// Disetujui (D2): angka jam, timer, dan nominal memakai tabular figures.
const tabularFigures = [FontFeature.tabularFigures()];

ThemeData mooverTheme() {
  final scheme =
      ColorScheme.fromSeed(
        // Seed steel: warna turunan M3 (surfaceContainer dialog/nav bar)
        // ikut keluarga Aqua Nebula. Tanpa dark mode di v1 (UD3).
        seedColor: MooverColors.steel,
      ).copyWith(
        primary: MooverColors.primary,
        onPrimary: MooverColors.surface,
        // Container lembut: abyss di atas mist 13,6:1.
        primaryContainer: MooverColors.mist,
        onPrimaryContainer: MooverColors.abyss,
        // Aksen: teks di atas teal harus abyss (5,97:1), bukan putih (3,02:1).
        secondary: MooverColors.teal,
        onSecondary: MooverColors.abyss,
        // Elemen terpilih (indikator M3 bawaan): abyss 9,49:1.
        secondaryContainer: MooverColors.surf,
        onSecondaryContainer: MooverColors.abyss,
        surface: MooverColors.surface,
        onSurface: MooverColors.text,
        onSurfaceVariant: MooverColors.textMuted,
        outline: MooverColors.textMuted,
        outlineVariant: MooverColors.hairline, // warna bawaan Divider
        // error tetap bawaan M3 #BA1A1A: 6,00:1 di latar, 6,46:1 di surface.
      );

  return ThemeData(
    colorScheme: scheme,
    fontFamily: mooverFontFamily,
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
        borderRadius: BorderRadius.all(Radius.circular(20)),
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
    // Segmen terpilih steel + teks putih (8,76:1); tepi outline (6,46:1).
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
