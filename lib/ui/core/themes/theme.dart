import 'package:flutter/material.dart';

// Token desain Moover Driver. Label status mengikuti
// `moover-mobile-planning/DESIGN.md`: "Disetujui" = final; "Usulan aktif" =
// nilai sementara, ubah hanya di file ini.
//
// Keputusan pemilik project 2026-10-10: design system V2.1
// (`docs/Moover V2 — Driver App Redesign (V2.1).html`) menggantikan palet
// web/D1 (#074A97) dan teks sekunder D5 (#6B7280). DESIGN.md planning belum
// diperbarui. Rasio kontras di komentar = hitungan WCAG, diuji di
// test/ui/core/design_system_test.dart.

abstract final class MooverColors {
  // Palet V2.1, diambil dari logo (loop navy → cyan).
  static const navy = Color(0xFF06275C); // header, permukaan gelap
  static const blue700 = Color(0xFF0550AE); // aksi utama, tautan
  // Nonteks saja: 3,96:1 di putih, 3,65:1 di latar.
  static const blue500 = Color(0xFF0A84D8);
  // Hanya di atas navy (aksen/live): 1,67:1 di putih. Label navy di atasnya
  // 8,63:1.
  static const cyan = Color(0xFF08DCF3);
  static const cyanTint = Color(0xFFDDF8FD); // chip "sedang trip"
  static const blueTint = Color(0xFFE8F1FD); // tile ikon, elemen terpilih
  // Teks sekunder di atas navy: 9,54:1 (5,01:1 di blue700).
  static const sky = Color(0xFFBFD3F5);
  // Pill "belum clock-in" (garis + teks) hanya di atas navy/blue700:
  // 10,16:1 di navy, 5,4:1 di blue700.
  static const amber = Color(0xFFFFD27A);

  // Semantik.
  static const primary = blue700; // putih di atasnya 7,59:1
  static const text = Color(0xFF0B1730); // Ink; 16,4:1 di latar
  static const textMuted = Color(
    0xFF56627A,
  ); // Slate; 5,66:1 latar, 6,13:1 putih
  static const background = Color(0xFFF3F6FB); // Ground
  static const surface = Color(0xFFFFFFFF);
  // Line: garis pemisah dekoratif (divider, tepi kartu). Bukan batas kontrol,
  // jadi tidak wajib 3:1; batas kontrol memakai outline.
  static const hairline = Color(0xFFE2E8F2);
}

/// Tone warna status. Disetujui (prinsip) D6. Nilai dari V2.1 (2026-10-10),
/// semua ≥4,5:1 terhadap [background]-nya. Penyimpangan dari HTML: ok
/// #1A7F4B digelapkan ke #187A48 (4,44 → 4,74:1). indigo tidak ada di V2,
/// dipertahankan dari palet lama agar tone tidak disamakan.
enum StatusTone {
  ok(Color(0xFF187A48), Color(0xFFE4F5EC)),
  warn(Color(0xFF8A4B00), Color(0xFFFFF0D6)),
  err(Color(0xFFB3261E), Color(0xFFFCE8E6)),
  info(MooverColors.blue700, MooverColors.blueTint),
  // V2: trip yang sedang berjalan; badge memakai titik cyan.
  live(Color(0xFF04607A), MooverColors.cyanTint),
  indigo(Color(0xFF4F46E5), Color(0xFFECEBFD)),
  neutral(MooverColors.textMuted, Color(0xFFEEF2F8));

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

// Usulan aktif, belum di DESIGN.md. md: tombol (V2.1); input: kolom isian
// (V2.1); card: kartu biasa dan Agenda (20, tetap); lg: bar navigasi.
abstract final class MooverRadius {
  static const sm = 12.0, input = 14.0, md = 16.0, card = 20.0, lg = 24.0;
}

// Disetujui (D2): font dibundel sebagai aset.
const mooverFontFamily = 'PlusJakartaSans';

// Disetujui (D2): angka jam, timer, dan nominal memakai tabular figures.
const tabularFigures = [FontFeature.tabularFigures()];

ThemeData mooverTheme() {
  final scheme =
      ColorScheme.fromSeed(
        // Seed = primary (UD3): warna turunan M3 (surfaceContainer dialog)
        // ikut keluarga biru brand. Tanpa dark mode di v1 (UD3).
        seedColor: MooverColors.primary,
      ).copyWith(
        primary: MooverColors.primary,
        onPrimary: MooverColors.surface,
        // Tint biru V2: teks blue700 di atasnya 6,67:1.
        primaryContainer: MooverColors.blueTint,
        onPrimaryContainer: MooverColors.primary,
        // Navy: putih 14,5:1.
        secondary: MooverColors.navy,
        onSecondary: MooverColors.surface,
        // Elemen terpilih (indikator M3 bawaan): blue700 di blueTint 6,67:1.
        secondaryContainer: MooverColors.blueTint,
        onSecondaryContainer: MooverColors.primary,
        surface: MooverColors.surface,
        // Samakan dengan latar: dipakai NavigationBar/menu bawaan M3.
        surfaceContainer: MooverColors.background,
        onSurface: MooverColors.text,
        onSurfaceVariant: MooverColors.textMuted,
        // Penyimpangan dari V2.1 (D9): tepi input #D5DCE7 (1,38:1) dan tombol
        // sekunder #C9D6EE (1,46:1) gagal 3:1; batas kontrol memakai Slate
        // (6,13:1).
        outline: MooverColors.textMuted,
        outlineVariant: MooverColors.hairline, // warna bawaan Divider
        // V2.1 danger: 6,03:1 di latar, 6,54:1 di surface.
        error: StatusTone.err.foreground,
      );
  // V2.1: tombol tinggi 56, radius 16, label 16/800. ponytail: w800 tampil
  // sebagai Bold (700) karena PlusJakartaSans-ExtraBold belum dibundel;
  // tambahkan file + entri pubspec bila disetujui.
  const buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(MooverRadius.md)),
  );
  const buttonSize = Size(64, 56);
  const buttonLabel = TextStyle(fontSize: 16, fontWeight: FontWeight.w800);
  OutlineInputBorder inputBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(MooverRadius.input),
    borderSide: BorderSide(color: color, width: 1.5),
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
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: buttonSize,
        shape: buttonShape,
        textStyle: buttonLabel,
        // V2.1 disabled: Slate di atas Line 4,98:1.
        disabledBackgroundColor: MooverColors.hairline,
        disabledForegroundColor: MooverColors.textMuted,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: buttonSize,
        shape: buttonShape,
        textStyle: buttonLabel.copyWith(fontSize: 15),
        side: const BorderSide(color: MooverColors.textMuted, width: 1.5),
      ),
    ),
    // V2.1: isian putih, radius 14, tepi 1,5. ponytail: ring fokus #E8F1FD
    // 4px belum ada; tambahkan bila dibutuhkan setelah Login ditinjau.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: MooverColors.surface,
      enabledBorder: inputBorder(MooverColors.textMuted),
      focusedBorder: inputBorder(MooverColors.primary),
      errorBorder: inputBorder(StatusTone.err.foreground),
      focusedErrorBorder: inputBorder(StatusTone.err.foreground),
    ),
    // Segmen terpilih primary + teks putih (7,59:1); tepi outline (6,13:1).
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
