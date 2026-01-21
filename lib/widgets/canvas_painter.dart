import 'package:flutter/material.dart';
import '../canvas/canvas_model.dart'; // Ensure correct import

class CanvasPainter extends CustomPainter {
  final List<Stroke> strokes;

  CanvasPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..color = stroke.isHighlight ? stroke.color.withOpacity(0.5) : stroke.color
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke.strokeWidth
        ..style = PaintingStyle.stroke;
      
      if (stroke.isHighlight) {
          paint.blendMode = BlendMode.multiply;
      }

      final path = Path();
      if (stroke.points.length > 1) {
        path.moveTo(stroke.points[0].x, stroke.points[0].y);
        for (int i = 1; i < stroke.points.length; i++) {
          path.lineTo(stroke.points[i].x, stroke.points[i].y);
        }
      } else {
        // Draw a point if there is only one coordinate
        canvas.drawCircle(
            Offset(stroke.points[0].x, stroke.points[0].y),
            stroke.strokeWidth / 2,
            paint..style = PaintingStyle.fill);
        continue;
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) {
    return true; // Simple approach: always repaint when strokes change
  }
}
