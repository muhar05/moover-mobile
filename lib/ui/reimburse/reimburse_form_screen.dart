import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/themes/theme.dart';
import '../core/widgets/widgets.dart';
import '../main_menu/mock_data.dart' show pastTrips, tripDestination;
import 'reimburse_detail_screen.dart' show RejectionNote, shortDate;
import 'reimburse_store.dart';

/// S15 Form Reimburse, baru dan ajukan ulang ([resubmit]) (KAK §5.1.15,
/// §6.4). Usulan aktif. Disimpan di SQLite perangkat (keputusan pemilik
/// project 2026-10-14), tanpa server: tidak ada pesan "berhasil" (D10).
/// Semua field wajib kecuali trip terkait (KAK hanya menandai trip
/// opsional). Batas nominal dan foto dari galeri: Q-B6 (tidak dipakai).
/// Form panjang: Kirim di akhir isi yang digulir, bukan bar bawah (S15).
/// Hasil pop: nomor reimburse (baru) atau '' (ajukan ulang).
class ReimburseFormScreen extends StatefulWidget {
  const ReimburseFormScreen({super.key, this.resubmit});

  final Reimbursement? resubmit;

  @override
  State<ReimburseFormScreen> createState() => _ReimburseFormScreenState();
}

class _ReimburseFormScreenState extends State<ReimburseFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _old = widget.resubmit?.draft;
  late DateTime _date = _old?.date ?? DateUtils.dateOnly(DateTime.now());
  late ReimburseCategory? _category = _old?.category;
  late final _amount = TextEditingController(text: _old?.amount.toString());
  late final _description = TextEditingController(text: _old?.description);
  late String? _trip = _old?.tripNumber;

  /// Foto nota: path file; [_simulated] = foto simulasi (non-release).
  late String? _photo = _old?.receiptPhoto;
  late bool _simulated = _old != null && _old.receiptPhoto == null;
  bool _photoMissing = false;
  String? _cameraError;
  String? _saveError;
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    // ponytail: batas tanggal mundur Belum ditentukan; 1 tahun ke belakang.
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(today.year - 1, today.month, today.day),
      lastDate: today,
      helpText: 'Tanggal pengeluaran',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _takePhoto() async {
    setState(() => _cameraError = null);
    try {
      // Kamera belakang; galeri Q-B6 Perlu konfirmasi.
      final photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        imageQuality: 75,
      );
      if (photo == null) return; // dibatalkan
      final kept = await keepReceiptPhoto(photo.path);
      if (!mounted) return;
      setState(() {
        _photo = kept;
        _simulated = false;
        _photoMissing = false;
      });
    } on Exception {
      if (mounted) {
        setState(
          () => _cameraError = 'Kamera tidak dapat dibuka. Izinkan akses kamera, lalu coba lagi.',
        );
      }
    }
  }

  Future<void> _submit() async {
    final hasPhoto = _photo != null || _simulated;
    setState(() {
      _photoMissing = !hasPhoto;
      _saveError = null;
    });
    if (!_form.currentState!.validate() || !hasPhoto) return;
    setState(() => _busy = true);
    final draft = (
      date: _date,
      category: _category!,
      amount: int.parse(_amount.text),
      description: _description.text.trim(),
      tripNumber: _trip,
      receiptPhoto: _photo,
    );
    try {
      final old = widget.resubmit;
      final number = old == null
          ? await reimburseStore.submit(draft)
          : await reimburseStore.resubmit(old.id, draft).then((_) => '');
      if (mounted) Navigator.of(context).pop(number);
    } on Exception {
      if (mounted) {
        setState(() {
          _busy = false;
          _saveError = 'Pengajuan gagal disimpan. Coba lagi.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final old = widget.resubmit;
    final note = old == null ? null : rejectionNote(old);
    final errorStyle = textTheme.bodySmall?.copyWith(
      color: StatusTone.err.foreground, // 6,54:1 di putih
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          old == null ? 'Ajukan reimburse' : 'Ajukan ulang',
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
            if (old != null) ...[
              Text(
                old.number,
                style: textTheme.bodySmall?.copyWith(
                  color: MooverColors.textMuted,
                  fontFeatures: tabularFigures,
                ),
              ),
              const SizedBox(height: MooverSpace.sm),
              if (note != null) RejectionNote(note),
              const SizedBox(height: MooverSpace.lg),
            ],
            TextFormField(
              key: ValueKey(_date),
              initialValue: shortDate(_date),
              readOnly: true,
              onTap: _busy ? null : _pickDate,
              decoration: const InputDecoration(
                labelText: 'Tanggal',
                suffixIcon: Icon(LucideIcons.calendar),
              ),
            ),
            const SizedBox(height: MooverSpace.lg),
            DropdownButtonFormField<ReimburseCategory>(
              initialValue: _category,
              isExpanded: true, // teks 200% di 320dp
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: [
                for (final c in ReimburseCategory.values)
                  DropdownMenuItem(value: c, child: Text(c.label)),
              ],
              onChanged: _busy ? null : (c) => setState(() => _category = c),
              validator: (c) => c == null ? 'Pilih kategori.' : null,
            ),
            const SizedBox(height: MooverSpace.lg),
            TextFormField(
              controller: _amount,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: const InputDecoration(
                labelText: 'Nominal',
                prefixText: 'Rp ',
              ),
              validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0
                  ? 'Isi nominal lebih dari 0.'
                  : null,
            ),
            const SizedBox(height: MooverSpace.lg),
            TextFormField(
              controller: _description,
              enabled: !_busy,
              minLines: 2,
              maxLines: 4,
              maxLength: 200, // ponytail: batas panjang Belum ditentukan.
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Keterangan'),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Isi keterangan.' : null,
            ),
            const SizedBox(height: MooverSpace.sm),
            DropdownButtonFormField<String?>(
              initialValue: _trip,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Trip terkait (opsional)',
              ),
              items: [
                const DropdownMenuItem(child: Text('Tanpa trip')),
                for (final t in pastTrips())
                  DropdownMenuItem(
                    value: t.number,
                    child: Text(
                      '${t.date} · ${tripDestination(t)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: _busy ? null : (t) => setState(() => _trip = t),
            ),
            const SizedBox(height: MooverSpace.xl),
            Semantics(
              header: true,
              child: Text('Foto nota', style: textTheme.titleSmall),
            ),
            const SizedBox(height: MooverSpace.sm),
            if (_photo != null || _simulated) ...[
              ReceiptPhoto(_photo),
              const SizedBox(height: MooverSpace.sm),
            ],
            OutlinedButton.icon(
              onPressed: _busy ? null : _takePhoto,
              icon: const Icon(LucideIcons.camera),
              label: Text(
                _photo != null || _simulated ? 'Foto ulang' : 'Ambil foto nota',
              ),
            ),
            // Emulator tanpa kamera; tidak ada di build release.
            if (!kReleaseMode && _photo == null && !_simulated)
              TextButton(
                onPressed: () => setState(() {
                  _simulated = true;
                  _photoMissing = false;
                }),
                child: const Text('Simulasi tanpa kamera'),
              ),
            for (final e in [
              if (_photoMissing) 'Ambil foto nota.',
              ?_cameraError,
            ])
              Padding(
                padding: const EdgeInsets.only(top: MooverSpace.sm),
                child: Text(e, style: errorStyle),
              ),
            const SizedBox(height: MooverSpace.xl),
            if (_saveError case final error?) ...[
              Text(error, style: errorStyle, textAlign: TextAlign.center),
              const SizedBox(height: MooverSpace.sm),
            ],
            PrimaryButton(
              label: old == null ? 'Kirim pengajuan' : 'Kirim ulang',
              onPressed: _submit,
              busy: _busy,
            ),
            const SizedBox(height: MooverSpace.sm),
            Text(
              'Demo: pengajuan disimpan di perangkat, belum dikirim ke server.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: MooverColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Foto nota; [path] null = foto contoh/simulasi.
class ReceiptPhoto extends StatelessWidget {
  const ReceiptPhoto(this.path, {super.key});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final path = this.path;
    final file = path == null ? null : File(path);
    return ClipRRect(
      borderRadius: BorderRadius.circular(MooverRadius.md),
      child: Container(
        height: 180,
        color: MooverColors.blueTint,
        alignment: Alignment.center,
        child: file != null && file.existsSync()
            ? Image.file(
                file,
                fit: BoxFit.cover,
                width: double.infinity,
                semanticLabel: 'Foto nota',
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                spacing: MooverSpace.sm,
                children: [
                  const Icon(
                    LucideIcons.receipt,
                    size: 48,
                    color: MooverColors.primary,
                  ),
                  // muted di blueTint 5,58:1.
                  Text(
                    'Foto nota contoh',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: MooverColors.textMuted),
                  ),
                ],
              ),
      ),
    );
  }
}
