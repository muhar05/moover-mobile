import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ui/core/themes/theme.dart';
import 'ui/splash/splash_screen.dart';

void main() {
  // Lisensi OFL font yang dibundel, agar tampil di halaman lisensi aplikasi.
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Plus Jakarta Sans',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moover',
      theme: mooverTheme(),
      // ponytail: Splash belum mengecek sesi (menunggu kontrak sesi); selalu
      // lanjut ke Landing.
      home: const SplashScreen(),
    );
  }
}
