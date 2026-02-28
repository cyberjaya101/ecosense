import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FlutterFlowTheme {
  static FlutterFlowTheme of(BuildContext context) => FlutterFlowTheme();

  Color get primary => const Color(0xFF00FF87);
  Color get secondary => const Color(0xFF1A0826);
  Color get tertiary => const Color(0xFF7A3F91);
  Color get alternate => const Color(0xFF2B0D3E);
  Color get primaryBackground => const Color(0xFF1A0826);
  Color get secondaryBackground => const Color(0xFF2B0D3E);
  Color get primaryText => const Color(0xFFF2EAF7);
  Color get secondaryText => const Color(0xFFC59DD9);
  Color get accent1 => const Color(0xFF00E5FF);
  Color get success => const Color(0xFF00FF87);
  Color get warning => const Color(0xFFF57C00);
  Color get error => const Color(0xFFFF5252);
  Color get info => Colors.white;

  TextStyle get titleLarge => GoogleFonts.inter(
        color: primaryText,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      );
  TextStyle get titleMedium => GoogleFonts.inter(
        color: primaryText,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      );
  TextStyle get titleSmall => GoogleFonts.inter(
        color: primaryText,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      );
  TextStyle get headlineLarge => GoogleFonts.inter(
        color: primaryText,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      );
  TextStyle get headlineMedium => GoogleFonts.inter(
        color: primaryText,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      );
  TextStyle get headlineSmall => GoogleFonts.inter(
        color: primaryText,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      );
  TextStyle get displayLarge => GoogleFonts.inter(
        color: primaryText,
        fontSize: 44,
        fontWeight: FontWeight.bold,
      );
  TextStyle get displayMedium => GoogleFonts.inter(
        color: primaryText,
        fontSize: 36,
        fontWeight: FontWeight.bold,
      );
  TextStyle get displaySmall => GoogleFonts.inter(
        color: primaryText,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      );
  TextStyle get bodyLarge => GoogleFonts.inter(
        color: primaryText,
        fontSize: 16,
        fontWeight: FontWeight.normal,
      );
  TextStyle get bodyMedium => GoogleFonts.inter(
        color: primaryText,
        fontSize: 14,
        fontWeight: FontWeight.normal,
      );
  TextStyle get bodySmall => GoogleFonts.inter(
        color: secondaryText,
        fontSize: 12,
        fontWeight: FontWeight.normal,
      );
  TextStyle get labelLarge => GoogleFonts.inter(
        color: secondaryText,
        fontSize: 16,
        fontWeight: FontWeight.normal,
      );
  TextStyle get labelMedium => GoogleFonts.inter(
        color: secondaryText,
        fontSize: 14,
        fontWeight: FontWeight.normal,
      );
  TextStyle get labelSmall => GoogleFonts.inter(
        color: secondaryText,
        fontSize: 12,
        fontWeight: FontWeight.normal,
      );
}

extension TextStyleHelper on TextStyle {
  TextStyle override({
    dynamic font,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    Color? color,
    double? fontSize,
    double? letterSpacing,
    bool? useGoogleFonts,
    TextDecoration? decoration,
    double? lineHeight,
  }) {
    return copyWith(
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      color: color,
      fontSize: fontSize,
      letterSpacing: letterSpacing,
      decoration: decoration,
      height: lineHeight,
    );
  }
}
