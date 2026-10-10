import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../core/widgets/widgets.dart';
import '../login/login_screen.dart';

/// S01 Landing (DESIGN.md §6.3, Usulan aktif; KAK §5.1.1). Copy, ilustrasi,
/// dan motion adalah usulan pemilik project, belum dicatat di DESIGN.md.
/// Register tidak ditampilkan: registrasi melalui admin (KAK §5.1.1).
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Reduced motion (setelan aksesibilitas OS): frame pertama, statis.
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Ilustrasi dekoratif, diputar sekali lalu diam di frame
                // terakhir (benchmark emulator: setelah ±2 dtk biayanya sama
                // dengan statis). Controller milik Lottie, di-dispose bersama
                // widget.
                ExcludeSemantics(
                  child: SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.35,
                    child: Lottie.asset(
                      'assets/animations/driving.json',
                      animate: !reduceMotion,
                      repeat: false,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Reliable Drivers for Every Business Trip',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                // Teks utama (bodyLarge = onSurface), keterbacaan maksimal.
                Text(
                  'Manage driver attendance and ensure every trip runs on '
                  'time and as scheduled.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Login',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const LoginScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
