import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/themes/theme.dart';
import '../core/widgets/spread.dart';
import '../core/widgets/widgets.dart';
import '../main_menu/main_menu_screen.dart' show formatClock, formatDate;
import '../main_menu/mock_data.dart' show Punch;
import '../time_log/time_log_screen.dart' show shiftEnd;

/// S04 Absensi: clock-in dengan foto + lokasi + waktu (KAK §5.1.2, §6.1),
/// gaya V2.1 "Clock in". Keputusan pemilik project 2026-10-11 (belum di
/// DESIGN.md): clock-in disimulasikan di aplikasi, lokasi MOCK. Kamera
/// tampil di dalam bingkai wajah (paket camera, disetujui pemilik project
/// 2026-10-14), bukan aplikasi kamera bawaan; diuji di HP Android.
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

class _AttendanceScreenState extends State<AttendanceScreen>
    with WidgetsBindingObserver {
  DateTime _now = DateTime.now();
  late final Timer _timer;

  /// Waktu foto diambil; null = belum ada foto.
  DateTime? _shotAt;

  /// File foto kamera; null bersama [_shotAt] = foto simulasi (emulator).
  String? _photoPath;
  String? _error;
  bool _busy = false;

  /// Preview kamera; null = belum siap, gagal, atau sudah ada foto.
  CameraController? _camera;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _now = DateTime.now()),
    );
    _startCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    _camera?.dispose();
    super.dispose();
  }

  // Kamera dilepas saat app ke latar belakang (dipakai app lain), lalu
  // dibuka lagi saat kembali bila belum ada foto.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _stopCamera();
    } else if (state == AppLifecycleState.resumed &&
        _shotAt == null &&
        _camera == null) {
      _startCamera();
    }
  }

  void _stopCamera() {
    final camera = _camera;
    if (camera == null) return;
    setState(() => _camera = null);
    camera.dispose();
  }

  Future<void> _startCamera() async {
    setState(() => _error = null);
    CameraController? camera;
    try {
      // Kamera depan (selfie). Galeri tidak dipakai (Q-B6 Perlu konfirmasi).
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw CameraException('no_camera', null);
      camera = CameraController(
        cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        ),
        ResolutionPreset.medium,
        enableAudio: false, // tanpa izin mikrofon
      );
      await camera.initialize();
      if (!mounted) {
        await camera.dispose();
        return;
      }
      setState(() => _camera = camera);
    } on Exception {
      await camera?.dispose();
      // ponytail: tombol ke Pengaturan perangkat (S04, Usulan aktif) butuh
      // dependency baru; tambahkan saat penanganan izin diputuskan.
      if (mounted) {
        setState(
          () => _error = 'Kamera tidak dapat dibuka. Izinkan akses kamera, lalu coba lagi.',
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    final camera = _camera;
    if (camera == null) return _startCamera(); // "Coba lagi" setelah galat
    if (camera.value.isTakingPicture) return;
    try {
      final photo = await camera.takePicture();
      if (!mounted) return;
      setState(() {
        _photoPath = photo.path;
        _shotAt = DateTime.now();
      });
      _stopCamera(); // hemat baterai; Ulangi membuka lagi
    } on Exception {
      if (mounted) {
        setState(() => _error = 'Foto gagal diambil. Coba lagi.');
      }
    }
  }

  void _retake() {
    setState(() {
      _photoPath = null;
      _shotAt = null;
    });
    _startCamera();
  }

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
                    // Koreksi pemilik project 2026-10-14: preview memenuhi
                    // kotak kamera, oval hanya panduan wajah di tengahnya.
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 280),
                      margin: const EdgeInsets.fromLTRB(
                        MooverSpace.screen,
                        MooverSpace.lg,
                        MooverSpace.screen,
                        0,
                      ),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: const Color(0x14FFFFFF), // putih 8% (V2.1)
                        borderRadius: BorderRadius.circular(28), // V2.1
                      ),
                      child: Stack(
                        children: [
                          if (shot == null && _camera != null)
                            Positioned.fill(child: _Preview(_camera!)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(MooverSpace.lg),
                                  child: Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: shot == null
                                          ? _oval
                                          : _Photo(
                                              path: _photoPath,
                                              kind: kind,
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              _controls(context, shot, scrim: _camera != null),
                            ],
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

  /// Bingkai wajah (panduan) di atas preview. V2.1 180×228, diperkecil agar
  /// tombol Kirim muat tanpa gulir di layar ±830dp (Pixel 4).
  static const _oval = SizedBox(
    width: 140,
    height: 176,
    child: DecoratedBox(
      decoration: ShapeDecoration(
        shape: OvalBorder(side: BorderSide(color: MooverColors.cyan, width: 3)),
      ),
    ),
  );

  /// Petunjuk, galat, dan tombol di bawah kotak kamera. [scrim]: preview
  /// tampil di belakangnya, jadi diberi lapisan [_scrimColor] (pudar di
  /// atas) agar teks terbaca di atas gambar apa pun, termasuk putih penuh
  /// (kontras diuji). Tanpa preview: bidang kamera #1A3869, sky 7,6:1.
  Widget _controls(
    BuildContext context,
    DateTime? shot, {
    required bool scrim,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final color = scrim ? _scrimColor : const Color(0x00000000);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: MooverSpace.xl,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color.withValues(alpha: 0), color],
            ),
          ),
        ),
        ColoredBox(
          color: color,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              MooverSpace.lg,
              0,
              MooverSpace.lg,
              MooverSpace.lg,
            ),
            child: Column(
              spacing: 14, // V2.1
              children: [
                if (shot == null)
                  Text(
                    'Posisikan wajah di dalam bingkai',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: MooverColors.sky,
                    ),
                  )
                else
                  Text(
                    'Foto diambil · ${formatClock(shot)}',
                    textAlign: TextAlign.center,
                    style: textTheme.titleSmall?.copyWith(
                      color: MooverColors.surface,
                      fontFeatures: tabularFigures,
                    ),
                  ),
                if (_error case final error?)
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
                    // Nonaktif selama kamera disiapkan; setelah galat,
                    // ketuk = buka kamera lagi.
                    onPressed: _camera == null && _error == null
                        ? null
                        : _takePhoto,
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
                  // Emulator tanpa kamera: foto diganti tanda simulasi.
                  // Tidak ada di build release.
                  if (!kReleaseMode)
                    TextButton(
                      onPressed: () {
                        setState(() => _shotAt = DateTime.now());
                        _stopCamera();
                      },
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
      ],
    );
  }
}

/// Lapisan di bawah teks/tombol saat preview tampil (navy 85%).
const _scrimColor = Color(0xD906275C);

/// Preview kamera memenuhi bingkai (dipotong, rasio tetap). Dekoratif bagi
/// pembaca layar: petunjuk ada di teks bawahnya.
class _Preview extends StatelessWidget {
  const _Preview(this.camera);

  final CameraController camera;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        // Preview potret: lebar = sisi pendek sensor.
        width: 100,
        height: 100 * camera.value.aspectRatio,
        child: CameraPreview(camera),
      ),
    ),
  );
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
