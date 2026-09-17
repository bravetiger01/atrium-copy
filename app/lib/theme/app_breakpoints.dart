import 'package:flutter/widgets.dart';

abstract final class AppBreakpoints {
  const AppBreakpoints._();

  static const double xs = 320;
  static const double sm = 375;
  static const double md = 768;
  static const double lg = 1024;
  static const double xl = 1280;
  static const double xxl = 1440;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < md;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= md && width < lg;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= lg;
}