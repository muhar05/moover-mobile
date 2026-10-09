import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'design/theme.dart';
import 'screens/login.dart';

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
      // ponytail: Login langsung jadi layar awal; S01 Landing/Splash dan cek
      // sesi menunggu Q-B9 dan desain sesi.
      home: const LoginPage(),
    );
  }
}
