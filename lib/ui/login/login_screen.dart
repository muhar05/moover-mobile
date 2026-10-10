import 'package:flutter/material.dart';

import '../core/themes/theme.dart';
import '../core/widgets/widgets.dart';
import '../main_menu/main_menu_screen.dart';

// MOCK/DEMO: kredensial hardcode sementara, bukan autentikasi. Tidak ada
// server, token, atau sesi tersimpan.
// ponytail: hapus saat login API (API_CONTRACT U1) Terverifikasi.
const demoEmployeeId = 'DEMO001';
const demoPassword = 'demo1234';
const demoDriverName = 'Driver Demo';

// Label normal memakai teks utama (#111111); warna fokus (primary) dan error
// tetap dari tema. Diuji ≥4,5:1 di test/login_test.dart.
final _labelStyle = WidgetStateTextStyle.resolveWith(
  (s) => s.contains(WidgetState.focused) || s.contains(WidgetState.error)
      ? const TextStyle()
      : const TextStyle(color: MooverColors.text),
);

/// S02 Login (DESIGN.md §6.3, Usulan aktif). Employee ID + password; akun
/// dibuat admin (KAK §5.1.1). Lupa password: Perlu konfirmasi (Q-B8), tidak
/// ditampilkan. Text field memakai bawaan M3 (gaya input Belum ditentukan).
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              // Pesan validasi hilang saat field diperbaiki.
              autovalidateMode: AutovalidateMode.onUserInteractionIfError,
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const MooverLogo(height: 40),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _employeeId,
                      decoration: InputDecoration(
                        labelText: 'Employee ID',
                        labelStyle: _labelStyle,
                        floatingLabelStyle: _labelStyle,
                      ),
                      autocorrect: false,
                      enableSuggestions: false,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Employee ID wajib diisi.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      decoration: InputDecoration(
                        labelText: 'Kata sandi',
                        labelStyle: _labelStyle,
                        floatingLabelStyle: _labelStyle,
                        suffixIcon: IconButton(
                          tooltip: _obscure
                              ? 'Tampilkan kata sandi'
                              : 'Sembunyikan kata sandi',
                          icon: Icon(
                            _obscure ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      obscureText: _obscure,
                      autocorrect: false,
                      enableSuggestions: false,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Kata sandi wajib diisi.'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(label: 'Masuk', onPressed: _submit),
                    if (_message != null) ...[
                      const SizedBox(height: 16),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _message!,
                          textAlign: TextAlign.center,
                          // Warna error M3 (#BA1A1A): 6,00:1 di latar layar.
                          style: textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    // Teks utama (onSurface), keterbacaan maksimal.
                    Text(
                      'Akun dibuat oleh admin.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
