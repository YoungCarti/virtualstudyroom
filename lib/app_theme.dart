import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central theme system for the LMS app
/// "Ocean Sunset" color palette
class AppTheme {
  // ============ COLORS ============
  
  // Background Colors
  static const Color deepNavy = Color(0xFF0A1929);
  static const Color midnightBlue = Color(0xFF122A46);
  static const Color darkSurface = Color(0xFF1A3A5C);
  
  // Primary Colors
  static const Color electricBlue = Color(0xFF2196F3);
  static const Color skyBlue = Color(0xFF64B5F6);
  static const Color lightBlue = Color(0xFF90CAF9);
  
  // Accent Colors
  static const Color coral = Color(0xFFFF6B6B);
  static const Color coralLight = Color(0xFFFF8E8E);
  static const Color mint = Color(0xFF4ECDC4);
  static const Color mintLight = Color(0xFF7EDDD6);
  static const Color softOrange = Color(0xFFFFB347);
  static const Color amber = Color(0xFFFFC107);
  
  // Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF29B6F6);
  
  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color textMuted = Color(0xFF78909C);
  
  // ============ GRADIENTS ============
  
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [electricBlue, mint],
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [coral, softOrange],
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [deepNavy, midnightBlue],
  );
  
  static LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      darkSurface.withValues(alpha: 0.8),
      midnightBlue.withValues(alpha: 0.6),
    ],
  );
  
  static const LinearGradient mintGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [mint, mintLight],
  );
  
  static const LinearGradient coralGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [coral, coralLight],
  );
  
  // ============ TEXT STYLES ============
  
  static TextStyle get headingLarge => GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );
  
  static TextStyle get headingMedium => GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static TextStyle get headingSmall => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );
  
  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );
  
  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );
  
  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: textMuted,
  );
  
  static TextStyle get buttonText => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  // ============ DECORATIONS ============
  
  static BoxDecoration get cardDecoration => BoxDecoration(
    gradient: cardGradient,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.1),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );
  
  static BoxDecoration get glassDecoration => BoxDecoration(
    color: Colors.white.withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.12),
      width: 1,
    ),
  );
  
  static BoxDecoration accentCardDecoration(Color accentColor) => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        accentColor.withValues(alpha: 0.2),
        accentColor.withValues(alpha: 0.05),
      ],
    ),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: accentColor.withValues(alpha: 0.3),
      width: 1,
    ),
  );
  
  // ============ BUTTON STYLES ============
  
  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
    backgroundColor: electricBlue,
    foregroundColor: textPrimary,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  );
  
  static ButtonStyle get secondaryButton => ElevatedButton.styleFrom(
    backgroundColor: Colors.white.withValues(alpha: 0.1),
    foregroundColor: textPrimary,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  );
  
  static ButtonStyle get accentButton => ElevatedButton.styleFrom(
    backgroundColor: coral,
    foregroundColor: textPrimary,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  );
  
  // ============ SHADOWS ============
  
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];
  
  static List<BoxShadow> glowShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.4),
      blurRadius: 20,
      spreadRadius: -5,
    ),
  ];
  
  // ============ SPACING ============
  
  static const double spacingXS = 4;
  static const double spacingS = 8;
  static const double spacingM = 16;
  static const double spacingL = 24;
  static const double spacingXL = 32;
  static const double spacingXXL = 48;
  
  // ============ BORDER RADIUS ============
  
  static const double radiusS = 8;
  static const double radiusM = 12;
  static const double radiusL = 16;
  static const double radiusXL = 20;
  static const double radiusXXL = 28;
}

/// Reusable gradient text widget
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Gradient gradient;

  const GradientText({
    super.key,
    required this.text,
    required this.style,
    this.gradient = AppTheme.primaryGradient,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(text, style: style),
    );
  }
}

/// Reusable gradient icon widget
class GradientIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Gradient gradient;

  const GradientIcon({
    super.key,
    required this.icon,
    this.size = 24,
    this.gradient = AppTheme.primaryGradient,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Icon(icon, size: size, color: Colors.white),
    );
  }
}
