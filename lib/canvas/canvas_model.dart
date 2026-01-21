import 'package:flutter/material.dart';

class CanvasPoint {
  final double x;
  final double y;

  CanvasPoint({required this.x, required this.y});

  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
    };
  }

  factory CanvasPoint.fromMap(Map<String, dynamic> map) {
    return CanvasPoint(
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
    );
  }
}

class Stroke {
  final String id;
  final List<CanvasPoint> points;
  final Color color;
  final double strokeWidth;

  Stroke({
    required this.id,
    required this.points,
    required this.color,
    required this.strokeWidth,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'points': points.map((p) => p.toMap()).toList(),
      'color': color.value,
      'strokeWidth': strokeWidth,
    };
  }

  factory Stroke.fromMap(Map<String, dynamic> map) {
    return Stroke(
      id: map['id'] ?? '',
      points: (map['points'] as List<dynamic>)
          .map((p) => CanvasPoint.fromMap(p as Map<String, dynamic>))
          .toList(),
      color: Color(map['color'] as int),
      strokeWidth: (map['strokeWidth'] as num).toDouble(),
    );
  }
}
