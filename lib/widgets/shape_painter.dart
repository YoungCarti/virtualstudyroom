import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../canvas/canvas_model.dart';

class ShapePainter extends CustomPainter {
  final ShapeElement element;

  ShapePainter({required this.element});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = element.color
      ..style = element.isFilled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = element.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final rect = Rect.fromLTWH(0, 0, element.width, element.height);

    switch (element.type) {
      case ShapeType.rectangle:
        canvas.drawRect(rect, paint);
        break;
      case ShapeType.circle:
        canvas.drawOval(rect, paint);
        break;
      case ShapeType.triangle:
        final path = Path();
        path.moveTo(element.width / 2, 0); // Top
        path.lineTo(element.width, element.height); // Bottom Right
        path.lineTo(0, element.height); // Bottom Left
        path.close();
        canvas.drawPath(path, paint);
        break;
      case ShapeType.star:
        _drawStar(canvas, paint, element.width, element.height);
        break;
      case ShapeType.line:
         canvas.drawLine(Offset.zero, Offset(element.width, element.height), paint);
         break;
      case ShapeType.arrow:
        _drawArrow(canvas, paint, Offset.zero, Offset(element.width, element.height));
        break;
    }
  }

  void _drawStar(Canvas canvas, Paint paint, double width, double height) {
    final path = Path();
    final centerX = width / 2;
    final centerY = height / 2;
    final outerRadius = math.min(width, height) / 2;
    final innerRadius = outerRadius / 2.5;
    
    // 5 points
    for (int i = 0; i < 10; i++) {
        double radius = (i % 2 == 0) ? outerRadius : innerRadius;
        double angle = (i * 36 - 90) * math.pi / 180;
        double x = centerX + radius * math.cos(angle);
        double y = centerY + radius * math.sin(angle);
        if (i == 0) {
            path.moveTo(x, y);
        } else {
            path.lineTo(x, y);
        }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawArrow(Canvas canvas, Paint paint, Offset start, Offset end) {
      canvas.drawLine(start, end, paint);
      
      final angle = (end - start).direction;
      final arrowSize = 15.0;
      
      final arrowPath = Path();
      arrowPath.moveTo(end.dx - arrowSize * math.cos(angle - math.pi / 6), end.dy - arrowSize * math.sin(angle - math.pi / 6));
      arrowPath.lineTo(end.dx, end.dy);
      arrowPath.lineTo(end.dx - arrowSize * math.cos(angle + math.pi / 6), end.dy - arrowSize * math.sin(angle + math.pi / 6));
      
      canvas.drawPath(arrowPath, paint..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
