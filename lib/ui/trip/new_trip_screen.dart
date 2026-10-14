import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/themes/theme.dart';
import '../core/widgets/widgets.dart';
import '../main_menu/mock_data.dart' show Trip;
import 'trip_detail_screen.dart'
    show LocationPickerScreen, PickedLocation, RouteMap;
import 'trip_store.dart';

/// S11 Add New Trip, Tipe A (KAK §5.1.6, §6.2). Usulan aktif. Disimpan di
/// SQLite perangkat (keputusan pemilik project 2026-10-14), tanpa server:
/// tidak ada pesan "berhasil" (D10). Trip baru Terjadwal, jemput sekarang
/// (seperti mock web), lalu dijalankan lewat Start/End Trip biasa.
/// Siapa yang boleh membuat: Perlu konfirmasi (Q-B1); demo mengikuti tombol
/// di tab Trip (hanya saat Available = sudah clock-in, keputusan 2026-10-10).
/// Lokasi: dipilih di peta, nama terisi otomatis dari titik dan tidak bisa
/// diketik (keputusan + koreksi pemilik project 2026-10-14: nama ketikan
/// bisa berbeda dengan titik). Titik dipakai peta rute S07/S08.
/// Hasil pop: [Trip] yang disimpan.
class NewTripScreen extends StatefulWidget {
  const NewTripScreen({super.key});

  @override
  State<NewTripScreen> createState() => _NewTripScreenState();
}

class _NewTripScreenState extends State<NewTripScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _division = TextEditingController();
  final _origin = TextEditingController();
  final _destination = TextEditingController();
  final _address = TextEditingController();
  final _points = <TextEditingController, LatLng>{};
  bool _busy = false;
  String? _saveError;

  @override
  void dispose() {
    for (final c in [_name, _division, _origin, _destination, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saveError = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final trip = await tripStore.add((
        passengerName: _name.text,
        passengerDivision: _division.text,
        origin: _origin.text,
        destination: _destination.text,
        originPoint: _points[_origin]!,
        destinationPoint: _points[_destination]!,
        destinationAddress: _address.text.trim().isEmpty
            ? null
            : _address.text.trim(),
      ));
      if (mounted) Navigator.of(context).pop(trip);
    } on Exception {
      if (mounted) {
        setState(() {
          _busy = false;
          _saveError = 'Trip gagal disimpan. Coba lagi.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: MooverColors.textMuted);
    Widget field(TextEditingController c, String label, String error) =>
        TextFormField(
          controller: c,
          enabled: !_busy,
          maxLength: 100, // ponytail: batas panjang Belum ditentukan.
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: label, counterText: ''),
          validator: (v) => (v ?? '').trim().isEmpty ? error : null,
        );
    // Read-only: diisi dari pemilih lokasi, nama + titik selalu sepasang.
    Widget location(TextEditingController c, String label, String title) {
      Future<void> pick() async {
        final picked = await Navigator.of(context).push<PickedLocation>(
          MaterialPageRoute(
            builder: (_) =>
                LocationPickerScreen(title: title, initial: _points[c]),
          ),
        );
        if (picked == null) return;
        setState(() => _points[c] = picked.point); // preview rute
        c.text = picked.name;
      }

      return TextFormField(
        controller: c,
        enabled: !_busy,
        readOnly: true,
        onTap: pick,
        maxLines: null,
        decoration: InputDecoration(
          labelText: label,
          hintText: 'Pilih di peta',
          suffixIcon: const Icon(LucideIcons.mapPin),
        ),
        validator: (v) =>
            (v ?? '').isEmpty || _points[c] == null ? '$title di peta.' : null,
        // Galat lama hilang setelah lokasi dipilih.
        autovalidateMode: AutovalidateMode.onUserInteraction,
      );
    }

    Widget header(String text) =>
        Semantics(header: true, child: Text(text, style: textTheme.titleSmall));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Trip baru',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            MooverSpace.screen,
            MooverSpace.sm,
            MooverSpace.screen,
            MooverSpace.xxl,
          ),
          children: [
            Text(
              'Trip di luar jadwal (Tipe A). Waktu jemput: sekarang.',
              style: muted,
            ),
            const SizedBox(height: MooverSpace.xl),
            // Format input penumpang (teks bebas atau pilih karyawan) Perlu
            // konfirmasi (K5); demo teks bebas, satu penumpang.
            header('Penumpang'),
            const SizedBox(height: MooverSpace.md),
            field(_name, 'Nama penumpang', 'Isi nama penumpang.'),
            const SizedBox(height: MooverSpace.lg),
            field(_division, 'Divisi', 'Isi divisi penumpang.'),
            const SizedBox(height: MooverSpace.xl),
            header('Rute'),
            const SizedBox(height: MooverSpace.md),
            location(_origin, 'Lokasi jemput', 'Pilih lokasi jemput'),
            const SizedBox(height: MooverSpace.lg),
            location(_destination, 'Tujuan', 'Pilih tujuan'),
            const SizedBox(height: MooverSpace.lg),
            // Alamat lengkap diketik manual, opsional (permintaan pemilik
            // project 2026-10-14): nama dari peta sering kurang rinci.
            TextFormField(
              controller: _address,
              enabled: !_busy,
              maxLength:
                  200, // disetujui pemilik project 2026-10-14 (sementara).
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Alamat lengkap tujuan (opsional)',
                hintText: 'Nama jalan, nomor, gedung',
                counterText: '',
              ),
            ),
            // Preview rute setelah kedua titik dipilih (permintaan pemilik
            // project 2026-10-14); dibuat ulang bila titik diubah.
            if ((_points[_origin], _points[_destination]) case (
              final origin?,
              final destination?,
            )) ...[
              const SizedBox(height: MooverSpace.lg),
              RouteMap(
                [origin, destination],
                key: ValueKey((origin, destination)),
                height: 180,
              ),
            ],
            const SizedBox(height: MooverSpace.xl),
            if (_saveError case final error?) ...[
              Text(
                error,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: StatusTone.err.foreground, // ≥4,5:1 di latar (diuji)
                ),
              ),
              const SizedBox(height: MooverSpace.sm),
            ],
            PrimaryButton(
              label: 'Simpan trip',
              onPressed: _submit,
              busy: _busy,
            ),
            const SizedBox(height: MooverSpace.sm),
            Text(
              'Demo: trip disimpan di perangkat, belum dikirim ke server.',
              textAlign: TextAlign.center,
              style: muted,
            ),
          ],
        ),
      ),
    );
  }
}
