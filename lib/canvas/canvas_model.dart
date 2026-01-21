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

class TextElement {
  final String id;
  final String text;
  final double x;
  final double y;
  final double fontSize;
  final Color color;
  final double width;
  final double rotation;
  final bool isBold;

  TextElement({
    required this.id,
    required this.text,
    required this.x,
    required this.y,
    required this.fontSize,
    required this.color,
    required this.width,
    this.rotation = 0.0,
    this.isBold = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'x': x,
      'y': y,
      'fontSize': fontSize,
      'color': color.value,
      'width': width,
      'rotation': rotation,
      'isBold': isBold,
    };
  }

  factory TextElement.fromMap(Map<String, dynamic> map) {
    return TextElement(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      fontSize: (map['fontSize'] as num).toDouble(),
      color: Color(map['color'] as int),
      width: (map['width'] as num).toDouble(),
      rotation: (map['rotation'] as num?)?.toDouble() ?? 0.0,
      isBold: map['isBold'] ?? false,
    );
  }
}
