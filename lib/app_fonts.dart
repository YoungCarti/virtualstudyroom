import 'package:flutter/material.dart';

/// App-wide font configuration using Clash Grotesk
class AppFonts {
  static const String fontFamily = 'ClashGrotesk';
  
  /// Create a TextStyle with Clash Grotesk font
  static TextStyle clashGrotesk({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    double? wordSpacing,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    FontStyle? fontStyle,
    TextBaseline? textBaseline,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    TextOverflow? overflow,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
      fontStyle: fontStyle,
      textBaseline: textBaseline,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      overflow: overflow,
    );
  }
}

