import 'package:flutter/material.dart';

// Token desain Moover Driver. Label status mengikuti
// `moover-mobile-planning/DESIGN.md`: "Disetujui" = final; "Usulan aktif" =
// nilai sementara, ubah hanya di file ini.

abstract final class MooverColors {
  // Disetujui (D1): warna utama dan skala biru.
  static const primary = Color(0xFF074A97);
  static const g700 = Color(0xFF0A5BB5);
  static const g600 = Color(0xFF1167C4);
  static const g500 = Color(0xFF1A7AD6);
  static const g300 = Color(0xFF5AAEF0);
  static const g100 = Color(0xFFB8DCFA);
  static const g50 = Color(0xFFE8F2FD);

  // Disetujui (D5): teks sekunder. Sementara hanya dipakai di atas [surface].
  // Di atas [background] rasionya 4,46:1 (hitungan), di bawah target 4,5:1.
  static const textMuted = Color(0xFF6B7280);

  // Usulan aktif (UD3).
  static const background = Color(0xFFF5F6F5);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF111111);
}

/// Tone warna status. Disetujui (prinsip) D6: makna tone mengikuti web.
///
/// Nilai [foreground] adalah KANDIDAT: warna web yang digelapkan (hue tetap)
/// sampai ≥4,5:1 terhadap [background] menurut hitungan WCAG. Belum diuji di
/// perangkat, belum final. Web asli: ok #2E8B57, warn #B7860B, err #E0524D,
/// info #2563EB, neutral #6B7280.
enum StatusTone {
  ok(Color(0xFF287A4C), Color(0xFFE6F4EA)),
  warn(Color(0xFF8E6809), Color(0xFFFFF6DC)),
  err(Color(0xFFCA2923), Color(0xFFFDE8E7)),
  info(Color(0xFF2060EB), Color(0xFFE8EFFD)),
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
        seedColor: MooverColors.primary, // Usulan aktif (UD3): seed M3.
        // Usulan aktif (UD3): tanpa dark mode di v1.
      ).copyWith(
        primary: MooverColors.primary, // D1
        onPrimary: Colors.white,
        surface: MooverColors.surface, // UD3
        onSurface: MooverColors.text, // UD3
        onSurfaceVariant: MooverColors.textMuted, // D5
      );

  return ThemeData(
    colorScheme: scheme,
    fontFamily: mooverFontFamily,
    scaffoldBackgroundColor: MooverColors.background, // UD3
    // Disetujui (D9): target sentuh ≥48dp. Belum diuji di perangkat.
    materialTapTargetSize: MaterialTapTargetSize.padded,
    // Usulan aktif (UD3): kartu flat tanpa shadow. Radius: Belum ditentukan,
    // memakai bawaan M3. Tombol pill = bawaan M3 (StadiumBorder).
    cardTheme: const CardThemeData(
      elevation: 0,
      color: MooverColors.surface,
      margin: EdgeInsets.zero,
    ),
    // Sementara (teknis): desain app bar Belum ditentukan. Samakan dengan latar
    // dan matikan tint scroll M3 sampai desain app bar ditetapkan.
    appBarTheme: const AppBarTheme(
      backgroundColor: MooverColors.background,
      scrolledUnderElevation: 0,
    ),
  );
}
