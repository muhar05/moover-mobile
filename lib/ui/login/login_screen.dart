import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/themes/theme.dart';
import '../core/widgets/widgets.dart';
import '../main_menu/main_menu_screen.dart';

// MOCK/DEMO: kredensial hardcode sementara, bukan autentikasi. Tidak ada
// server, token, atau sesi tersimpan.
// ponytail: hapus saat login API (API_CONTRACT U1) Terverifikasi.
const demoEmployeeId = 'DEMO001';
const demoPassword = 'demo1234';
const demoDriverName = 'Driver Demo';

/// S02 Login (DESIGN.md §6.3, Usulan aktif). Employee ID + kata sandi; akun
/// dibuat admin (KAK §5.1.1).
///
/// Mengikuti halaman Login V2.1 (keputusan pemilik project 2026-10-10, belum
/// di DESIGN.md planning): header navy + watermark, kartu form menumpang,
/// tombol Login di footer. Trade-off yang disetujui: tanpa tab Register
/// (registrasi lewat admin), Work email, Remember me, dan Forgot password
/// (Q-B8 Perlu konfirmasi); "Contact support" diganti "Akun dibuat oleh
/// admin."; aturan minimal 8 karakter tidak dibuat (aturan belum ada); tepi
/// input Slate, bukan #D5DCE7 (gagal 3:1, D9).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _employeeId = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  String? _message;

  @override
  void dispose() {
    _employeeId.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _message = null);
    if (!_formKey.currentState!.validate()) return;
    // MOCK/DEMO. ponytail: ganti dengan panggilan login + state akun nonaktif
    // / tanpa koneksi saat kontrak backend (U1) Terverifikasi.
    if (_employeeId.text.trim() != demoEmployeeId ||
        _password.text != demoPassword) {
      setState(() => _message = 'Employee ID atau kata sandi salah.');
      return;
    }
    // Hapus Landing dan Login dari stack: Back dari Main Menu menutup app.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const MainMenuScreen()),
      (_) => false,
    );
  }

  /// MOCK/DEMO, hanya build debug/profile (permintaan pemilik project
  /// 2026-10-10). ponytail: hapus bersama kredensial demo.
  void _fillDemo() {
    _employeeId.text = demoEmployeeId;
    _password.text = demoPassword;
    setState(() => _message = null);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final canPop = Navigator.of(context).canPop();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: MooverColors.surface, // V2.1: halaman putih
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header navy V2.1: padding 52 24 64 (52 ≈ status bar + 20).
              ColoredBox(
                color: MooverColors.navy,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    const Positioned(
                      right: -60,
                      bottom: -30,
                      width: 230,
                      child: MooverMark(opacity: 0.14),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        MooverSpace.xl,
                        MediaQuery.paddingOf(context).top + MooverSpace.screen,
                        MooverSpace.xl,
                        64,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // V2.1: 44×44, dinaikkan ke 48 (D9).
                              SizedBox.square(
                                dimension: 48,
                                child: canPop
                                    ? IconButton(
                                        tooltip: 'Kembali',
                                        onPressed: () =>
                                            Navigator.of(context).maybePop(),
                                        style: IconButton.styleFrom(
                                          backgroundColor: const Color(
                                            0x1FFFFFFF,
                                          ),
                                          foregroundColor: MooverColors.surface,
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(
                                                MooverRadius.input,
                                              ),
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(
                                          LucideIcons.chevronLeft,
                                        ),
                                      )
                                    : null,
                              ),
                              Expanded(
                                child: Image.asset(
                                  'assets/brand/moover-logo-reverse.png',
                                  height: 24,
                                  semanticLabel: 'Moover',
                                ),
                              ),
                              const SizedBox.square(dimension: 48),
                            ],
                          ),
                          const SizedBox(height: 28), // V2.1
                          Semantics(
                            header: true,
                            child: Text(
                              'Selamat datang kembali',
                              style: textTheme.headlineMedium?.copyWith(
                                fontSize: 28,
                                height: 1.15,
                                letterSpacing: -0.56,
                                fontWeight: FontWeight.w800,
                                color: MooverColors.surface,
                              ),
                            ),
                          ),
                          const SizedBox(height: MooverSpace.sm),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 300),
                            // Sky di navy 9,54:1.
                            child: Text(
                              'Masuk dengan akun pegawai untuk melihat '
                              'jadwal hari ini.',
                              style: textTheme.bodyLarge?.copyWith(
                                fontSize: 15,
                                height: 1.5,
                                color: MooverColors.sky,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // V2.1: kartu menumpang 36dp ke header (margin −36 16 0).
              Transform.translate(
                offset: const Offset(0, -36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: MooverSpace.lg,
                      ),
                      // V2.1: 6 18 20 + padding form 20; tanpa tab Register.
                      padding: const EdgeInsets.fromLTRB(18, 26, 18, 20),
                      decoration: BoxDecoration(
                        color: MooverColors.surface,
                        borderRadius: BorderRadius.circular(MooverRadius.lg),
                        boxShadow: [
                          BoxShadow(
                            color: MooverColors.navy.withValues(alpha: 0.12),
                            blurRadius: 40,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: _form(textTheme),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        MooverSpace.xl,
                        MooverSpace.screen,
                        MooverSpace.xl,
                        MooverSpace.md,
                      ),
                      // Slate di putih 6,13:1.
                      child: Text(
                        'Akun dibuat oleh admin.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: MooverColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // V2.1 footer: putih, garis atas, tombol 56.
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(
            color: MooverColors.surface,
            border: Border(top: BorderSide(color: MooverColors.hairline)),
          ),
          child: SafeArea(
            minimum: const EdgeInsets.only(bottom: MooverSpace.screen),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                MooverSpace.screen,
                MooverSpace.md,
                MooverSpace.screen,
                0,
              ),
              child: PrimaryButton(label: 'Login', onPressed: _submit),
            ),
          ),
        ),
      ),
    );
  }

  Widget _form(TextTheme textTheme) {
    // V2.1: label 13/700 di atas kotak isian, jarak 6. Digabung dengan
    // field-nya agar TalkBack membaca label + isian sebagai satu kontrol.
    Widget field(String label, Widget input) => MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 6,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: MooverColors.text,
            ),
          ),
          input,
        ],
      ),
    );
    final errorStyle = textTheme.bodySmall?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: StatusTone.err.foreground,
    );

    return Form(
      key: _formKey,
      // Pesan validasi hilang saat field diperbaiki.
      autovalidateMode: AutovalidateMode.onUserInteractionIfError,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: MooverSpace.lg,
          children: [
            field(
              'Employee ID',
              TextFormField(
                controller: _employeeId,
                decoration: InputDecoration(
                  hintText: 'ID dari perusahaan Anda',
                  prefixIcon: const Icon(LucideIcons.idCard),
                  errorStyle: errorStyle,
                ),
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.username],
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Employee ID wajib diisi.'
                    : null,
              ),
            ),
            field(
              'Kata sandi',
              TextFormField(
                controller: _password,
                decoration: InputDecoration(
                  hintText: 'Kata sandi Anda',
                  prefixIcon: const Icon(LucideIcons.lock),
                  errorStyle: errorStyle,
                  suffixIcon: IconButton(
                    tooltip: _obscure
                        ? 'Tampilkan kata sandi'
                        : 'Sembunyikan kata sandi',
                    icon: Icon(_obscure ? LucideIcons.eye : LucideIcons.eyeOff),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                obscureText: _obscure,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _submit(),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Kata sandi wajib diisi.' : null,
              ),
            ),
            if (_message != null)
              Semantics(
                liveRegion: true,
                child: Text(
                  _message!,
                  style: errorStyle?.copyWith(fontSize: 14),
                ),
              ),
            if (!kReleaseMode)
              OutlinedButton.icon(
                onPressed: _fillDemo,
                icon: const Icon(LucideIcons.zap),
                label: const Text('Isi akun demo'),
              ),
          ],
        ),
      ),
    );
  }
}
