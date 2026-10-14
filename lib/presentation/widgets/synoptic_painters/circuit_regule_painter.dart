import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// Données temps réel pour le circuit régulé
class CircuitReguleData {
  final double? tempDepart;
  final double? positionV3V;
  final bool pompeActive;
  final bool v3vActive;

  const CircuitReguleData({
    this.tempDepart,
    this.positionV3V,
    this.pompeActive = false,
    this.v3vActive = false,
  });
}

/// Widget animé pour le circuit de régulation (CR)
class CircuitReguleWidget extends StatefulWidget {
  final CircuitReguleData data;
  final VoidCallback? onPompeTap;
  final VoidCallback? onV3VTap;
  final VoidCallback? onTempTap;

  const CircuitReguleWidget({
    super.key,
    required this.data,
    this.onPompeTap,
    this.onV3VTap,
    this.onTempTap,
  });

  @override
  State<CircuitReguleWidget> createState() => _CircuitReguleWidgetState();
}

class _CircuitReguleWidgetState extends State<CircuitReguleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.data.pompeActive) {
      _animController.repeat();
    }
  }

  @override
  void didUpdateWidget(CircuitReguleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data.pompeActive && !_animController.isAnimating) {
      _animController.repeat();
    } else if (!widget.data.pompeActive && _animController.isAnimating) {
      _animController.stop();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _CircuitRegulePainter(
                data: widget.data,
                pumpRotation: _animController.value * 2 * math.pi,
                isDark: Theme.of(context).brightness == Brightness.dark,
                pumpLabel: AppLocalizations.of(context)!.widgetPumpLabel,
              ),
              child: _buildInteractiveOverlay(constraints),
            );
          },
        );
      },
    );
  }

  Widget _buildInteractiveOverlay(BoxConstraints constraints) {
    // Zones cliquables proportionnelles
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;

    return Stack(
      children: [
        // Zone température
        Positioned(
          left: w * 0.05,
          top: h * 0.12,
          width: w * 0.25,
          height: h * 0.1,
          child: GestureDetector(
            onTap: widget.onTempTap,
            child: Container(color: Colors.transparent),
          ),
        ),
        // Zone pompe
        Positioned(
          left: w * 0.35,
          top: h * 0.35,
          width: w * 0.3,
          height: h * 0.15,
          child: GestureDetector(
            onTap: widget.onPompeTap,
            child: Container(color: Colors.transparent),
          ),
        ),
        // Zone V3V
        Positioned(
          left: w * 0.15,
          top: h * 0.6,
          width: w * 0.25,
          height: h * 0.15,
          child: GestureDetector(
            onTap: widget.onV3VTap,
            child: Container(color: Colors.transparent),
          ),
        ),
      ],
    );
  }
}

class _CircuitRegulePainter extends CustomPainter {
  final CircuitReguleData data;
  final double pumpRotation;
  final bool isDark;
  final String pumpLabel;

  _CircuitRegulePainter({
    required this.data,
    required this.pumpRotation,
    required this.isDark,
    required this.pumpLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Couleurs adaptées au thème
    final bgColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);
    final pipeColor = isDark ? const Color(0xFF4A90D9) : const Color(0xFF2196F3);
    final pipeReturnColor = isDark ? const Color(0xFFD97A4A) : const Color(0xFFFF7043);
    final metalColor = isDark ? const Color(0xFF808080) : const Color(0xFF9E9E9E);
    final textColor = isDark ? Colors.white : Colors.black87;
    final activeColor = const Color(0xFF4CAF50);
    final inactiveColor = isDark ? const Color(0xFF666666) : const Color(0xFFBDBDBD);

    // Fond
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = bgColor,
    );

    // === TUYAUX ===
    final pipePaint = Paint()
      ..color = pipeColor
      ..strokeWidth = w * 0.03
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final pipeReturnPaint = Paint()
      ..color = pipeReturnColor
      ..strokeWidth = w * 0.03
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Tuyau départ (bleu) - horizontal en haut
    canvas.drawLine(
      Offset(w * 0.1, h * 0.2),
      Offset(w * 0.9, h * 0.2),
      pipePaint,
    );

    // Tuyau vertical gauche (vers le bas)
    canvas.drawLine(
      Offset(w * 0.1, h * 0.2),
      Offset(w * 0.1, h * 0.8),
      pipePaint,
    );

    // Tuyau retour (orange) - horizontal en bas
    canvas.drawLine(
      Offset(w * 0.1, h * 0.8),
      Offset(w * 0.9, h * 0.8),
      pipeReturnPaint,
    );

    // Tuyau vertical droit (vers le haut)
    canvas.drawLine(
      Offset(w * 0.9, h * 0.2),
      Offset(w * 0.9, h * 0.8),
      pipeReturnPaint,
    );

    // === SONDE TEMPÉRATURE ===
    _drawTemperatureSensor(canvas, Offset(w * 0.15, h * 0.2), w * 0.08, textColor);

    // Affichage température
    if (data.tempDepart != null) {
      _drawValueBox(
        canvas,
        Offset(w * 0.15, h * 0.08),
        '${data.tempDepart!.toStringAsFixed(1)}°C',
        textColor,
        w,
      );
    }

    // === POMPE ===
    _drawPump(
      canvas,
      Offset(w * 0.5, h * 0.42),
      w * 0.1,
      data.pompeActive ? activeColor : inactiveColor,
      metalColor,
    );

    // LED pompe
    _drawLed(
      canvas,
      Offset(w * 0.65, h * 0.38),
      w * 0.02,
      data.pompeActive,
    );

    // === VANNE 3 VOIES ===
    _drawV3V(
      canvas,
      Offset(w * 0.25, h * 0.65),
      w * 0.12,
      data.v3vActive ? activeColor : metalColor,
      metalColor,
    );

    // LED V3V
    _drawLed(
      canvas,
      Offset(w * 0.38, h * 0.62),
      w * 0.02,
      data.v3vActive,
    );

    // Affichage position V3V
    if (data.positionV3V != null) {
      _drawValueBox(
        canvas,
        Offset(w * 0.25, h * 0.78),
        '${data.positionV3V!.toStringAsFixed(0)}%',
        textColor,
        w,
      );
    }

    // === LABELS ===
    _drawLabel(canvas, Offset(w * 0.5, h * 0.52), pumpLabel, textColor, w);
    _drawLabel(canvas, Offset(w * 0.25, h * 0.58), 'V3V', textColor, w);
  }

  void _drawTemperatureSensor(Canvas canvas, Offset center, double size, Color textColor) {
    final paint = Paint()
      ..color = const Color(0xFF795548)
      ..style = PaintingStyle.fill;

    // Corps de la sonde (rectangle arrondi)
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: size * 0.4, height: size),
      Radius.circular(size * 0.1),
    );
    canvas.drawRRect(rect, paint);

    // Bulbe en bas
    canvas.drawCircle(
      Offset(center.dx, center.dy + size * 0.35),
      size * 0.25,
      Paint()..color = const Color(0xFFE53935),
    );
  }

  void _drawPump(Canvas canvas, Offset center, double radius, Color activeColor, Color metalColor) {
    // Corps de la pompe (cercle)
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = metalColor,
    );

    // Cercle intérieur
    canvas.drawCircle(
      center,
      radius * 0.7,
      Paint()..color = activeColor,
    );

    // Pales de la pompe (rotation)
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = radius * 0.15
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      final angle = pumpRotation + (i * 2 * math.pi / 3);
      final start = Offset(
        center.dx + math.cos(angle) * radius * 0.2,
        center.dy + math.sin(angle) * radius * 0.2,
      );
      final end = Offset(
        center.dx + math.cos(angle) * radius * 0.55,
        center.dy + math.sin(angle) * radius * 0.55,
      );
      canvas.drawLine(start, end, paint);
    }

    // Cercle central
    canvas.drawCircle(
      center,
      radius * 0.15,
      Paint()..color = metalColor,
    );
  }

  void _drawV3V(Canvas canvas, Offset center, double size, Color bodyColor, Color metalColor) {
    // Corps triangulaire de la vanne
    final path = Path();
    path.moveTo(center.dx - size * 0.5, center.dy - size * 0.3);
    path.lineTo(center.dx + size * 0.5, center.dy - size * 0.3);
    path.lineTo(center.dx, center.dy + size * 0.4);
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = bodyColor
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = metalColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Actionneur (rectangle sur le dessus)
    final actuatorRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - size * 0.5),
        width: size * 0.4,
        height: size * 0.3,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(actuatorRect, Paint()..color = metalColor);
  }

  void _drawLed(Canvas canvas, Offset center, double radius, bool isOn) {
    final color = isOn ? const Color(0xFF4CAF50) : const Color(0xFFE53935);

    // Glow effect si allumé
    if (isOn) {
      canvas.drawCircle(
        center,
        radius * 2,
        Paint()
          ..color = color.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    // LED
    canvas.drawCircle(center, radius, Paint()..color = color);

    // Reflet
    canvas.drawCircle(
      Offset(center.dx - radius * 0.3, center.dy - radius * 0.3),
      radius * 0.3,
      Paint()..color = Colors.white.withValues(alpha: 0.5),
    );
  }

  void _drawValueBox(Canvas canvas, Offset center, String value, Color textColor, double canvasWidth) {
    final fontSize = canvasWidth * 0.04;

    final textPainter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: Colors.greenAccent,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Fond noir
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: textPainter.width + 16,
        height: textPainter.height + 8,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(bgRect, Paint()..color = Colors.black87);

    // Texte
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawLabel(Canvas canvas, Offset center, String label, Color textColor, double canvasWidth) {
    final fontSize = canvasWidth * 0.03;

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: textColor.withValues(alpha: 0.7),
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _CircuitRegulePainter oldDelegate) {
    return oldDelegate.data.pompeActive != data.pompeActive ||
        oldDelegate.data.v3vActive != data.v3vActive ||
        oldDelegate.data.tempDepart != data.tempDepart ||
        oldDelegate.data.positionV3V != data.positionV3V ||
        oldDelegate.pumpRotation != pumpRotation ||
        oldDelegate.isDark != isDark ||
        oldDelegate.pumpLabel != pumpLabel;
  }
}
