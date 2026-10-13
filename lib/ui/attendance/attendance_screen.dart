import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/themes/theme.dart';
import '../core/widgets/spread.dart';
import '../core/widgets/widgets.dart';
import '../main_menu/main_menu_screen.dart' show formatClock, formatDate;
import '../main_menu/mock_data.dart' show Punch;
import '../time_log/time_log_screen.dart' show shiftEnd;

/// S04 Absensi: clock-in dengan foto + lokasi + waktu (KAK §5.1.2, §6.1),
/// gaya V2.1 "Clock in". Keputusan pemilik project 2026-10-11 (belum di
/// DESIGN.md): clock-in disimulasikan di aplikasi, kamera via image_picker
/// (diuji di HP Android, tidak wajib di emulator), lokasi MOCK.
/// Tidak ada server (API U5 masih Usulan): "Kirim" hanya menutup layar dan
/// mengembalikan waktu clock-in ke pemanggil, tanpa klaim berhasil (D10).
/// ponytail: latar V2.1 #0B1220 diganti navy (token yang ada); garis oval
/// putus-putus + garis pindai beranimasi diganti oval garis penuh.
/// [clockOut]: layar yang sama untuk clock-out (KAK §6.1: foto + lokasi +
/// waktu juga wajib), keputusan pemilik project 2026-10-13.
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key, this.clockOut = false});

  final bool clockOut;

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _now = DateTime.now();
  late final Timer _timer;

  /// Waktu foto diambil; null = belum ada foto.
  DateTime? _shotAt;

  /// File foto kamera; null bersama [_shotAt] = foto simulasi (emulator).
  String? _photoPath;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _now = DateTime.now()),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    setState(() => _error = null);
    try {
      // Kamera depan (selfie). Galeri tidak dipakai (Q-B6 Perlu konfirmasi).
      final photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1080,
        imageQuality: 70,
      );
      if (photo == null || !mounted) return; // dibatalkan
      setState(() {
        _photoPath = photo.path;
        _shotAt = DateTime.now();
      });
    } on Exception {
      // ponytail: tombol ke Pengaturan perangkat (S04, Usulan aktif) butuh
      // dependency baru; tambahkan saat penanganan izin diputuskan.
      if (mounted) {
        setState(
          () => _error = 'Kamera tidak dapat dibuka. Izinkan akses kamera, lalu coba lagi.',
        );
      }
    }
  }

  void _retake() => setState(() {
    _photoPath = null;
    _shotAt = null;
  });

  Future<void> _submit() async {
    setState(() => _busy = true);
    // Simulasi jeda kirim agar state busy (D10) bisa ditinjau.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      Navigator.of(context).pop<Punch>((at: DateTime.now(), photo: _photoPath));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final shot = _shotAt;
    final kind = widget.clockOut ? 'clock-out' : 'clock-in';
    // KAK §6.8: clock-out sebelum jam operasional berakhir = Tidak Lengkap.
    final early = widget.clockOut && _now.hour * 60 + _now.minute < shiftEnd;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: MooverColors.navy,
        // Tinggi layar cukup: area kamera mengisi sisa; tidak cukup (320dp,
        // teks 200%): seluruh isi digulir.
        body: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      MooverSpace.screen,
                      MediaQuery.paddingOf(context).top + MooverSpace.screen,
                      MooverSpace.screen,
                      0,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Kembali',
                          onPressed: () => Navigator.of(context).maybePop(),
                          style: IconButton.styleFrom(
                            fixedSize: const Size.square(48),
                            backgroundColor: const Color(0x1FFFFFFF),
                            foregroundColor: MooverColors.surface,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(MooverRadius.input),
                              ),
                            ),
                          ),
                          icon: const Icon(LucideIcons.chevronLeft),
                        ),
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(
                              widget.clockOut ? 'Clock-out' : 'Clock-in',
                              textAlign: TextAlign.center,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: MooverColors.surface,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox.square(dimension: 48),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 280),
                      margin: const EdgeInsets.fromLTRB(
                        MooverSpace.screen,
                        MooverSpace.lg,
                        MooverSpace.screen,
                        0,
                      ),
                      padding: const EdgeInsets.all(MooverSpace.lg),
                      decoration: BoxDecoration(
                        color: const Color(0x14FFFFFF), // putih 8% (V2.1)
                        borderRadius: BorderRadius.circular(28), // V2.1
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 14, // V2.1
                        children: [
                          if (shot == null) ...[
                            // Bingkai wajah dekoratif. V2.1 180×228,
                            // diperkecil agar tombol Kirim muat tanpa gulir
                            // di layar ±830dp (Pixel 4).
                            Container(
                              width: 140,
                              height: 176,
                              decoration: const ShapeDecoration(
                                shape: OvalBorder(
                                  side: BorderSide(
                                    color: MooverColors.cyan,
                                    width: 3,
                                  ),
                                ),
                              ),
                            ),
                            // Sky di bidang kamera (#1A3869) 7,6:1.
                            Text(
                              'Posisikan wajah di dalam bingkai',
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: MooverColors.sky,
                              ),
                            ),
                          ] else ...[
                            _Photo(path: _photoPath, kind: kind),
                            Text(
                              'Foto diambil · ${formatClock(shot)}',
                              textAlign: TextAlign.center,
                              style: textTheme.titleSmall?.copyWith(
                                color: MooverColors.surface,
                                fontFeatures: tabularFigures,
                              ),
                            ),
                          ],
                          if (_error case final error?)
                            // Amber di bidang kamera 8,1:1.
                            Text(
                              error,
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: MooverColors.amber,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          if (shot == null) ...[
                            IconButton(
                              tooltip: 'Ambil foto',
                              onPressed: _busy ? null : _takePhoto,
                              style: IconButton.styleFrom(
                                fixedSize: const Size.square(72),
                                padding: const EdgeInsets.all(5),
                                side: const BorderSide(
                                  color: MooverColors.surface,
                                  width: 4,
                                ),
                              ),
                              icon: const SizedBox.square(
                                dimension: 54,
                                child: DecoratedBox(
                                  decoration: ShapeDecoration(
                                    shape: CircleBorder(),
                                    color: MooverColors.surface,
                                  ),
                                ),
                              ),
                            ),
                            // Emulator tanpa kamera: foto diganti tanda
                            // simulasi. Tidak ada di build release.
                            if (!kReleaseMode)
                              TextButton(
                                onPressed: () =>
                                    setState(() => _shotAt = DateTime.now()),
                                style: TextButton.styleFrom(
                                  foregroundColor: MooverColors.sky,
                                  minimumSize: const Size(48, 48),
                                ),
                                child: const Text('Simulasi tanpa kamera'),
                              ),
                          ] else
                            OutlinedButton.icon(
                              onPressed: _busy ? null : _retake,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: MooverColors.surface,
                                side: const BorderSide(color: MooverColors.sky),
                              ),
                              icon: const Icon(LucideIcons.rotateCcw),
                              label: const Text('Ulangi'),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: MooverSpace.lg),
                  _Sheet(
                    now: _now,
                    // Usulan aktif (UD2): aksi utama di bawah, ≥52dp.
                    warning: early
                        ? 'Sebelum 16.30: status kehadiran hari ini Tidak '
                              'Lengkap.'
                        : null,
                    action: shot == null
                        ? const PrimaryButton(
                            label: 'Ambil foto untuk lanjut',
                            onPressed: null,
                          )
                        : PrimaryButton(
                            label: 'Kirim $kind',
                            onPressed: _submit,
                            busy: _busy,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Foto selfie bulat bertepi cyan + tanda centang (V2.1). [path] null =
/// foto simulasi (emulator).
class _Photo extends StatelessWidget {
  const _Photo({required this.path, required this.kind});

  final String? path;
  final String kind;

  @override
  Widget build(BuildContext context) {
    final path = this.path;
    return Stack(
      children: [
        Container(
          width: 168,
          height: 168,
          clipBehavior: Clip.antiAlias,
          decoration: const ShapeDecoration(
            shape: CircleBorder(
              side: BorderSide(color: MooverColors.cyan, width: 4),
            ),
            color: MooverColors.blueTint,
          ),
          child: path == null
              ? const Icon(
                  LucideIcons.scanFace,
                  size: 72,
                  color: MooverColors.primary,
                  semanticLabel: 'Foto simulasi',
                )
              : Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  semanticLabel: 'Foto $kind Anda',
                ),
        ),
        Positioned(
          right: 6,
          bottom: 6,
          child: Container(
            width: 40,
            height: 40,
            decoration: ShapeDecoration(
              color: StatusTone.ok.foreground,
              shape: const CircleBorder(
                side: BorderSide(color: MooverColors.navy, width: 3),
              ),
            ),
            child: const Icon(
              LucideIcons.check,
              size: 20,
              color: MooverColors.surface,
            ),
          ),
        ),
      ],
    );
  }
}

/// Lembar putih bawah: tanggal + jam berjalan, jam operasional, lokasi
/// MOCK, [warning] opsional, lalu [action].
class _Sheet extends StatelessWidget {
  const _Sheet({required this.now, this.warning, required this.action});

  final DateTime now;
  final String? warning;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: MooverColors.textMuted);
    final strong = textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: MooverColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          MooverSpace.screen,
          22, // V2.1
          MooverSpace.screen,
          MooverSpace.xl + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 14, // V2.1
          children: [
            spread(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: MooverSpace.xs,
                children: [
                  Text(formatDate(now), style: muted),
                  Text(
                    formatClock(now),
                    style: textTheme.headlineMedium?.copyWith(
                      fontSize: 32,
                      height: 1,
                      fontWeight: FontWeight.w600,
                      fontFeatures: tabularFigures,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: MooverSpace.xs,
                children: [
                  Text('Jam operasional', style: muted),
                  Text(
                    '07.30–16.30', // KAK §5.1.2
                    style: strong?.copyWith(fontFeatures: tabularFigures),
                  ),
                ],
              ),
            ),
            // MOCK/DEMO: lokasi simulasi, belum GPS (keputusan pemilik
            // project 2026-10-11). Radius area kantor: Belum ditentukan,
            // jadi tidak ada klaim "di dalam area".
            MergeSemantics(
              child: Container(
                padding: const EdgeInsets.all(14), // V2.1
                decoration: BoxDecoration(
                  color: MooverColors.background,
                  borderRadius: BorderRadius.circular(MooverRadius.md),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: MooverSpace.md,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: MooverColors.blueTint,
                        borderRadius: BorderRadius.circular(MooverRadius.sm),
                      ),
                      child: const Icon(
                        LucideIcons.mapPin,
                        size: 20,
                        color: MooverColors.primary,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: MooverSpace.xs,
                        children: [
                          spread(
                            Text('Kantor Pusat (contoh)', style: strong),
                            const StatusBadge(
                              label: 'Lokasi simulasi',
                              tone: StatusTone.info,
                            ),
                          ),
                          Text(
                            'Jl. Contoh No. 1, Jakarta (fiktif). Belum '
                            'memakai GPS.',
                            style: muted?.copyWith(height: 1.45),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (warning case final warning?)
              // Teks + warna (D7): warn di putih 6,4:1.
              Text(
                warning,
                style: textTheme.bodyMedium?.copyWith(
                  color: StatusTone.warn.foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            action,
          ],
        ),
      ),
    );
  }
}
