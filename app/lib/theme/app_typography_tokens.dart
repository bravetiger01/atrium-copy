import 'package:flutter/material.dart';

/// Auto-generated from Figma Design Tokens.
/// Source: Typography/Value.tokens.json
///
/// DO NOT EDIT MANUALLY.
abstract final class AppTypographyTokens {
  const AppTypographyTokens._();

  // ---------------------------------------------------------------------------
  // Font Families
  // ---------------------------------------------------------------------------

  static const String displayFontFamily =
      'Bricolage Grotesque 24pt Condensed';

  static const String bodyFontFamily =
      'Bricolage Grotesque 24pt SemiCondensed';

  // ---------------------------------------------------------------------------
  // Font Weights
  // ---------------------------------------------------------------------------

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  // ---------------------------------------------------------------------------
  // Font Sizes
  // ---------------------------------------------------------------------------

  static const double textXs = 12;
  static const double textSm = 14;
  static const double textMd = 16;
  static const double textLg = 18;
  static const double textXl = 20;

  static const double displayXs = 24;
  static const double displaySm = 30;
  static const double displayMd = 36;
  static const double displayLg = 48;
  static const double displayXl = 60;
  static const double display2Xl = 72;

  // ---------------------------------------------------------------------------
  // Line Heights
  // Stored as Flutter TextStyle.height values.
  // height = lineHeight / fontSize
  // ---------------------------------------------------------------------------

  static const double textXsHeight = 18 / 12;
  static const double textSmHeight = 20 / 14;
  static const double textMdHeight = 24 / 16;
  static const double textLgHeight = 28 / 18;
  static const double textXlHeight = 30 / 20;

  static const double displayXsHeight = 32 / 24;
  static const double displaySmHeight = 38 / 30;
  static const double displayMdHeight = 44 / 36;
  static const double displayLgHeight = 60 / 48;
  static const double displayXlHeight = 72 / 60;
  static const double display2XlHeight = 90 / 72;
}