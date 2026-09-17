import 'package:flutter/widgets.dart';

/// Auto-generated from Figma Design Tokens.
/// Source: Radius/Mode 1.tokens.json
///
/// DO NOT EDIT MANUALLY.

abstract final class AppRadius {
  const AppRadius._();

  // ---------------------------------------------------------------------------
  // Radius Values
  // ---------------------------------------------------------------------------

  static const double none = 0.0;
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 6.0;
  static const double md = 8.0;
  static const double lg = 10.0;
  static const double xl = 12.0;
  static const double xxl = 16.0;
  static const double xxxl = 20.0;
  static const double xxxxl = 24.0;

  /// Fully rounded (pill/circle).
  static const double full = 9999.0;

  // ---------------------------------------------------------------------------
  // BorderRadius Helpers
  // ---------------------------------------------------------------------------

  static const BorderRadius noneRadius =
      BorderRadius.all(Radius.circular(none));

  static const BorderRadius xxsRadius =
      BorderRadius.all(Radius.circular(xxs));

  static const BorderRadius xsRadius =
      BorderRadius.all(Radius.circular(xs));

  static const BorderRadius smRadius =
      BorderRadius.all(Radius.circular(sm));

  static const BorderRadius mdRadius =
      BorderRadius.all(Radius.circular(md));

  static const BorderRadius lgRadius =
      BorderRadius.all(Radius.circular(lg));

  static const BorderRadius xlRadius =
      BorderRadius.all(Radius.circular(xl));

  static const BorderRadius xxlRadius =
      BorderRadius.all(Radius.circular(xxl));

  static const BorderRadius xxxlRadius =
      BorderRadius.all(Radius.circular(xxxl));

  static const BorderRadius xxxxlRadius =
      BorderRadius.all(Radius.circular(xxxxl));

  static const BorderRadius fullRadius =
      BorderRadius.all(Radius.circular(full));
}