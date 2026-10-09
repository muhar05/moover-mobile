import 'package:flutter/material.dart';

import '../design/theme.dart';
import '../design/widgets.dart';

// D5: label bawaan M3 (#6B7280) di atas latar #F5F6F5 hanya 4,46:1. Label
// normal memakai teks utama; warna fokus dan error tetap bawaan M3.
final _labelStyle = WidgetStateTextStyle.resolveWith(
  (s) => s.contains(WidgetState.focused) || s.contains(WidgetState.error)
      ? const TextStyle()
      : const TextStyle(color: MooverColors.text),
);

/// S02 Login (DESIGN.md §6.3, Usulan aktif). Employee ID + password; akun
/// dibuat admin (KAK §5.1.1). Lupa password: Perlu konfirmasi (Q-B8), tidak
/// ditampilkan. Text field memakai bawaan M3 (gaya input Belum ditentukan).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  String? _message;

  void _submit() {
    setState(() => _message = null);
    if (!_formKey.currentState!.validate()) return;
    // ponytail: autentikasi belum ada (API_CONTRACT U1 = Usulan). Ganti dengan
    // panggilan login + state kredensial salah / akun nonaktif / tanpa koneksi
    // saat kontrak backend Terverifikasi.
    setState(
      () => _message =
          'Masuk belum tersedia: aplikasi belum terhubung ke server.',
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
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    // Teks utama, bukan textMuted: latar #F5F6F5 (D5).
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
