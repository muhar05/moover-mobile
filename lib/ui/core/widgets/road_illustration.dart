import 'package:flutter/material.dart';

import '../themes/theme.dart';

/// Ilustrasi 2D jalan + mobil V2.1, dekoratif (tidak dibaca TalkBack), untuk
/// latar navy: kartu trip tambahan dan S08 Active Trip (permintaan pemilik
/// project 2026-10-14). Bergerak terus; diam saat reduced motion (D9) atau
/// tidak tampil (IndexedStack tidak mematikan ticker, tapi melapor lewat
/// Visibility.of).
class MooverRoadIllustration extends StatefulWidget {
  const MooverRoadIllustration({super.key});

  @override
  State<MooverRoadIllustration> createState() => _MooverRoadIllustrationState();
}

class _MooverRoadIllustrationState extends State<MooverRoadIllustration>
    with SingleTickerProviderStateMixin {
  // Satu siklus = satu putaran "roll" V2.1 (3s); marka jalan 3× per siklus.
  late final _motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!MediaQuery.disableAnimationsOf(context) && Visibility.of(context)) {
      if (!_motion.isAnimating) _motion.repeat();
    } else {
      _motion
        ..stop()
        ..value = 0.25; // mobil di tengah (dx 0), seperti versi statis
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ExcludeSemantics(child: CustomPaint(painter: _RoadPainter(_motion)));
}

/// Ilustrasi jalan + mobil V2.1 (SVG 320×120), dekoratif. Warna ilustrasi
/// diambil apa adanya dari SVG, bukan token (tidak dipakai di tempat lain).
/// Animasi V2.1: marka jalan bergeser 28 px/s (road 1s linear), mobil +
/// bayangan bergoyang ±6 px (roll 3s ease-in-out). [motion] 0..1 per 3s.
class _RoadPainter extends CustomPainter {
  _RoadPainter(this.motion) : super(repaint: motion);

  final Animation<double> motion;

  /// Geser mobil: −6 → 6 → −6, ease-in-out per paruh (keyframe CSS).
  static double carShift(double t) =>
      -6 + 12 * Curves.easeInOut.transform(t < 0.5 ? t * 2 : 2 - t * 2);

  @override
  void paint(Canvas canvas, Size size) {
    // viewBox 320×120, preserveAspectRatio "meet": skala seragam, di tengah.
    final s = (size.width / 320).clamp(0, size.height / 120).toDouble();
    canvas
      ..save()
      ..translate((size.width - 320 * s) / 2, (size.height - 120 * s) / 2)
      ..scale(s)
      // Marka yang digeser tidak boleh keluar dari ujung jalan (0..320).
      ..clipRect(const Rect.fromLTWH(0, 0, 320, 120));

    Paint fill(int c) => Paint()..color = Color(c);
    final stroke = Paint()..style = PaintingStyle.stroke;
    const gradient = LinearGradient(
      colors: [MooverColors.blue700, MooverColors.cyan],
    );
    final gradientPaint = Paint()
      ..shader = gradient.createShader(const Rect.fromLTWH(0, 0, 320, 120));

    // Jalan + marka putus-putus.
    canvas.drawLine(
      const Offset(0, 100),
      const Offset(320, 100),
      Paint.from(stroke)
        ..color = const Color(0xFF123A7A)
        ..strokeWidth = 18,
    );
    final dash = Paint.from(stroke)
      ..color = const Color(0xFF5C86C9)
      ..strokeWidth = 2;
    // stroke-dashoffset 0 → −28: pola bergeser ke kiri; mulai −28 agar
    // tepi kiri tetap terisi.
    final shift = (motion.value * 3 % 1) * 28;
    for (var x = -shift; x < 320; x += 28) {
      canvas.drawLine(Offset(x, 100), Offset(x + 14, 100), dash);
    }

    // Gedung.
    final building = fill(0xFF0D3170);
    for (final r in const [
      Rect.fromLTWH(28, 20, 34, 56),
      Rect.fromLTWH(70, 36, 26, 40),
      Rect.fromLTWH(240, 28, 40, 48),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(4)),
        building,
      );
    }

    // Pin tujuan.
    canvas
      ..drawPath(
        Path()
          ..moveTo(268, 6)
          ..cubicTo(259, 6, 252, 13, 252, 22)
          ..cubicTo(252, 33, 268, 48, 268, 48)
          ..cubicTo(268, 48, 284, 33, 284, 22)
          ..cubicTo(284, 13, 277, 6, 268, 6)
          ..close(),
        gradientPaint,
      )
      ..drawCircle(const Offset(268, 22), 6, fill(0xFF06275C));

    // Mobil.
    canvas
      ..save()
      ..translate(carShift(motion.value), 0)
      ..drawOval(
        Rect.fromCenter(center: const Offset(160, 98), width: 124, height: 8),
        fill(0x99041C44),
      )
      ..drawPath(
        Path()
          ..moveTo(100, 86)
          ..relativeCubicTo(0, -8, 5, -12, 14, -13)
          ..relativeLineTo(16, -2)
          ..relativeLineTo(13, -14)
          ..relativeCubicTo(4, -4, 9, -6, 16, -6)
          ..relativeLineTo(26, 0)
          ..relativeCubicTo(7, 0, 12, 3, 17, 8)
          ..relativeLineTo(10, 11)
          ..relativeCubicTo(9, 2, 13, 7, 13, 14)
          ..relativeLineTo(0, 4)
          ..relativeCubicTo(0, 2, -2, 4, -4, 4)
          ..lineTo(104, 94)
          ..relativeCubicTo(-2, 0, -4, -2, -4, -4)
          ..close(),
        fill(0xFFFFFFFF),
      );
    final glass = fill(0xFFBFEFFB);
    canvas
      ..drawPath(
        Path()
          ..moveTo(146, 62)
          ..relativeCubicTo(3, -3, 6, -4, 11, -4)
          ..relativeLineTo(15, 0)
          ..relativeLineTo(0, 13)
          ..relativeLineTo(-37, 0)
          ..close(),
        glass,
      )
      ..drawPath(
        Path()
          ..moveTo(176, 58)
          ..relativeLineTo(7, 0)
          ..relativeCubicTo(5, 0, 9, 2, 12, 6)
          ..relativeLineTo(6, 7)
          ..relativeLineTo(-25, 0)
          ..close(),
        glass,
      )
      ..drawLine(
        const Offset(106, 80),
        const Offset(222, 80),
        Paint.from(gradientPaint)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    for (final x in const [126.0, 200.0]) {
      canvas
        ..drawCircle(Offset(x, 91), 10, fill(0xFF0B1730))
        ..drawCircle(Offset(x, 91), 4, fill(0xFFE2E8F2));
    }
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(216, 76, 6, 4),
          const Radius.circular(2),
        ),
        fill(0xFFFFD27A),
      )
      ..restore()
      ..restore();
  }

  @override
  bool shouldRepaint(_RoadPainter oldDelegate) => oldDelegate.motion != motion;
}
