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
  final bool isHighlight;

  Stroke({
    required this.id,
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.isHighlight = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'points': points.map((p) => p.toMap()).toList(),
      'color': color.value,
      'strokeWidth': strokeWidth,
      'isHighlight': isHighlight,
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
      isHighlight: map['isHighlight'] ?? false,
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

class StickyNoteElement {
  final String id;
  final String text;
  final double x;
  final double y;
  final double width;
  final double height;
  final Color color;
  final double fontSize;

  StickyNoteElement({
    required this.id,
    required this.text,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.color,
    required this.fontSize,
  });

  StickyNoteElement copyWith({
    String? id,
    String? text,
    double? x,
    double? y,
    double? width,
    double? height,
    Color? color,
    double? fontSize,
  }) {
    return StickyNoteElement(
      id: id ?? this.id,
      text: text ?? this.text,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      color: color ?? this.color,
      fontSize: fontSize ?? this.fontSize,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'color': color.value,
      'fontSize': fontSize,
    };
  }

  factory StickyNoteElement.fromMap(Map<String, dynamic> map) {
    return StickyNoteElement(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      width: (map['width'] as num).toDouble(),
      height: (map['height'] as num).toDouble(),
      color: Color(map['color'] as int),
      fontSize: (map['fontSize'] as num).toDouble(),
    );
  }
}
