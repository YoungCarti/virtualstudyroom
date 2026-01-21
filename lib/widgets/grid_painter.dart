import 'package:flutter/material.dart';

class GridPainter extends CustomPainter {
  final double scale;
  final Offset offset;

  GridPainter({this.scale = 1.0, this.offset = Offset.zero});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const double gridSize = 40.0;

    // Calculate start and end points based on the visible area would be better for performance,
    // but for now, we are painting on a large SizedBox inside InteractiveViewer, 
    // so we paint the whole "virtual" size.
    
    // Vertical lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return false;
  }
}
