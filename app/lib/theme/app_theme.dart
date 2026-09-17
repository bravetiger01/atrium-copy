import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  SwipeHire — App Theme  (Slate + Blue)
//  Palette:
//    Primary    #1E293B  slate-800  (nav, headers)
//    Accent     #3B82F6  blue-500   (CTAs, active states)
//    Background #F8FAFC  slate-50   (page canvas)
//    Surface    #FFFFFF  white      (cards, sheets)
//    Border     #E2E8F0  slate-200
//    Muted text #64748B  slate-500
//    Hint text  #94A3B8  slate-400
//    Error      #DC2626  red-600
//    Success    #16A34A  green-600
// ─────────────────────────────────────────────

abstract final class AppColors {
  // ── Brand ────────────────────────────────────
  static const Color primary = Color(0xFF1E293B);
  static const Color accent = Color(0xFF3B82F6);
  static const Color accentLight = Color(0xFFDBEAFE);
  static const Color accentDark = Color(0xFF1D4ED8);

  // ── Backgrounds ──────────────────────────────
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  // ── Slate scale ──────────────────────────────
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);

  // ── Text ─────────────────────────────────────
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color textOnAccent = Color(0xFFFFFFFF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Semantic ─────────────────────────────────
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);

  // ── Swipe specific ───────────────────────────
  static const Color swipeRight = Color(0xFF16A34A);
  static const Color swipeRightBg = Color(0xFFDCFCE7);
  static const Color swipeLeft = Color(0xFFDC2626);
  static const Color swipeLeftBg = Color(0xFFFEE2E2);

  // ── Divider / border ─────────────────────────
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);
}

// ─────────────────────────────────────────────
//  Text styles
// ─────────────────────────────────────────────

abstract final class AppTextStyles {
  static const String _fontFamily = 'Inter';

  // Display
  static const TextStyle displayLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  // Headings
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  // Titles
  static const TextStyle titleLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.55,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  // Labels
  static const TextStyle labelLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.0,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.0,
    letterSpacing: 0.3,
    color: AppColors.textSecondary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.0,
    letterSpacing: 0.4,
    color: AppColors.textHint,
  );

  // App-specific
  static const TextStyle jobTitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle jobCompany = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: AppColors.textSecondary,
  );

  static const TextStyle salaryLabel = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.accent,
  );

  static const TextStyle chipLabel = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.0,
    letterSpacing: 0.2,
  );

  static const TextStyle buttonLabel = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.0,
    letterSpacing: 0.1,
  );

  static const TextStyle navLabel = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.0,
    letterSpacing: 0.2,
  );

  static const TextStyle matchBanner = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -0.5,
    color: AppColors.textOnAccent,
  );
}

// ─────────────────────────────────────────────
//  Spacing & radius constants
// ─────────────────────────────────────────────

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  static const EdgeInsets pagePadding =
      EdgeInsets.symmetric(horizontal: 20, vertical: 16);

  static const EdgeInsets cardPadding = EdgeInsets.all(16);

  static const EdgeInsets listItemPadding =
      EdgeInsets.symmetric(horizontal: 20, vertical: 14);
}

abstract final class AppRadius {
  static const double sm = 6;
  static const double md = 10;
  static const double lg = 14;
  static const double xl = 20;
  static const double xxl = 28;
  static const double full = 999;

  static const BorderRadius smRadius = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgRadius = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlRadius = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius xxlRadius = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius fullRadius = BorderRadius.all(Radius.circular(full));

  // Job swipe card
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(24));
}

// ─────────────────────────────────────────────
//  Decorations
// ─────────────────────────────────────────────

abstract final class AppDecorations {
  // Standard surface card
  static BoxDecoration get card => BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.border, width: 0.5),
      );

  // Elevated card (e.g. bottom sheet, job detail)
  static BoxDecoration get cardElevated => BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.xlRadius,
        boxShadow: AppShadows.cardShadow,
      );

  // Swipe job card
  static BoxDecoration get jobCard => BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppShadows.jobCardShadow,
      );

  // Accent-filled (e.g. match banner bg)
  static BoxDecoration get accentFill => BoxDecoration(
        color: AppColors.accent,
        borderRadius: AppRadius.lgRadius,
      );

  // Input field
  static BoxDecoration get inputField => BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: AppColors.border, width: 1),
      );

  static BoxDecoration get inputFieldFocused => BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: AppColors.accent, width: 1.5),
      );

  // Chip / tag
  static BoxDecoration get chip => BoxDecoration(
        color: AppColors.slate100,
        borderRadius: AppRadius.fullRadius,
      );

  static BoxDecoration get accentChip => BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: AppRadius.fullRadius,
      );

  // Swipe overlay indicators
  static BoxDecoration get swipeYesOverlay => BoxDecoration(
        color: AppColors.successLight.withValues(alpha: 0.9),
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.swipeRight, width: 2),
      );

  static BoxDecoration get swipeNoOverlay => BoxDecoration(
        color: AppColors.swipeLeftBg.withValues(alpha: 0.9),
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.swipeLeft, width: 2),
      );
}

abstract final class AppShadows {
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: AppColors.slate900.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: AppColors.slate900.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get jobCardShadow => [
        BoxShadow(
          color: AppColors.slate900.withValues(alpha: 0.10),
          blurRadius: 32,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: AppColors.slate900.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: AppColors.accent.withValues(alpha: 0.28),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}

// ─────────────────────────────────────────────
//  Main ThemeData
// ─────────────────────────────────────────────

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: 'Inter',

        // ── Color scheme ───────────────────────
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.accent,
          onPrimary: AppColors.textOnAccent,
          primaryContainer: AppColors.accentLight,
          onPrimaryContainer: AppColors.accentDark,
          secondary: AppColors.slate700,
          onSecondary: AppColors.textOnPrimary,
          secondaryContainer: AppColors.slate100,
          onSecondaryContainer: AppColors.slate800,
          tertiary: AppColors.success,
          onTertiary: AppColors.textOnAccent,
          tertiaryContainer: AppColors.successLight,
          onTertiaryContainer: AppColors.success,
          error: AppColors.error,
          onError: AppColors.textOnAccent,
          errorContainer: AppColors.errorLight,
          onErrorContainer: AppColors.error,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          surfaceContainerHighest: AppColors.slate100,
          onSurfaceVariant: AppColors.textSecondary,
          outline: AppColors.border,
          outlineVariant: AppColors.slate200,
          shadow: AppColors.slate900,
          scrim: AppColors.slate900,
          inverseSurface: AppColors.slate800,
          onInverseSurface: AppColors.textOnPrimary,
          inversePrimary: AppColors.accentLight,
        ),

        scaffoldBackgroundColor: AppColors.background,

        // ── Typography ─────────────────────────
        textTheme: const TextTheme(
          displayLarge: AppTextStyles.displayLarge,
          displayMedium: AppTextStyles.displayMedium,
          headlineLarge: AppTextStyles.headlineLarge,
          headlineMedium: AppTextStyles.headlineMedium,
          headlineSmall: AppTextStyles.headlineSmall,
          titleLarge: AppTextStyles.titleLarge,
          titleMedium: AppTextStyles.titleMedium,
          titleSmall: AppTextStyles.titleSmall,
          bodyLarge: AppTextStyles.bodyLarge,
          bodyMedium: AppTextStyles.bodyMedium,
          bodySmall: AppTextStyles.bodySmall,
          labelLarge: AppTextStyles.labelLarge,
          labelMedium: AppTextStyles.labelMedium,
          labelSmall: AppTextStyles.labelSmall,
        ),

        // ── AppBar ─────────────────────────────
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          shadowColor: AppColors.border,
          centerTitle: false,
          titleTextStyle: AppTextStyles.headlineSmall,
          iconTheme: IconThemeData(
            color: AppColors.textPrimary,
            size: 22,
          ),
          actionsIconTheme: IconThemeData(
            color: AppColors.textSecondary,
            size: 22,
          ),
        ),

        // ── Bottom Navigation ──────────────────
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: AppColors.slate400,
          selectedLabelStyle: AppTextStyles.navLabel,
          unselectedLabelStyle: AppTextStyles.navLabel,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),

        // ── NavigationBar (M3) ─────────────────
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          shadowColor: AppColors.border,
          elevation: 0,
          indicatorColor: AppColors.accentLight,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.accent, size: 22);
            }
            return const IconThemeData(color: AppColors.slate400, size: 22);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppTextStyles.navLabel.copyWith(color: AppColors.accent);
            }
            return AppTextStyles.navLabel.copyWith(color: AppColors.slate400);
          }),
        ),

        // ── Elevated Button ────────────────────
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.textOnAccent,
            disabledBackgroundColor: AppColors.slate200,
            disabledForegroundColor: AppColors.slate400,
            elevation: 0,
            shadowColor: Colors.transparent,
            minimumSize: const Size(double.infinity, 52),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.mdRadius,
            ),
            textStyle: AppTextStyles.buttonLabel,
          ),
        ),

        // ── Outlined Button ────────────────────
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accent,
            disabledForegroundColor: AppColors.slate400,
            minimumSize: const Size(double.infinity, 52),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            side: const BorderSide(color: AppColors.accent, width: 1.5),
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.mdRadius,
            ),
            textStyle: AppTextStyles.buttonLabel,
          ),
        ),

        // ── Text Button ────────────────────────
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.accent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.mdRadius,
            ),
            textStyle: AppTextStyles.buttonLabel,
          ),
        ),

        // ── FilledButton ───────────────────────
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            minimumSize: const Size(double.infinity, 52),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.mdRadius,
            ),
            textStyle: AppTextStyles.buttonLabel,
          ),
        ),

        // ── Input / TextField ──────────────────
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textHint,
          ),
          labelStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          floatingLabelStyle: AppTextStyles.labelMedium.copyWith(
            color: AppColors.accent,
          ),
          errorStyle: AppTextStyles.labelMedium.copyWith(
            color: AppColors.error,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: AppRadius.mdRadius,
            borderSide: const BorderSide(color: AppColors.border, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.mdRadius,
            borderSide: const BorderSide(color: AppColors.border, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.mdRadius,
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: AppRadius.mdRadius,
            borderSide: const BorderSide(color: AppColors.error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: AppRadius.mdRadius,
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
        ),

        // ── Card ───────────────────────────────
        cardTheme: CardThemeData(
          color: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.lgRadius,
            side: const BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),

        // ── Chip ───────────────────────────────
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.slate100,
          selectedColor: AppColors.accentLight,
          disabledColor: AppColors.slate100,
          labelStyle: AppTextStyles.chipLabel.copyWith(
            color: AppColors.textSecondary,
          ),
          secondaryLabelStyle: AppTextStyles.chipLabel.copyWith(
            color: AppColors.accent,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: const StadiumBorder(),
          side: BorderSide.none,
          elevation: 0,
          pressElevation: 0,
        ),

        // ── List Tile ──────────────────────────
        listTileTheme: const ListTileThemeData(
          contentPadding:
              EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          minLeadingWidth: 0,
          iconColor: AppColors.textSecondary,
          titleTextStyle: AppTextStyles.titleMedium,
          subtitleTextStyle: AppTextStyles.bodySmall,
        ),

        // ── Divider ────────────────────────────
        dividerTheme: const DividerThemeData(
          color: AppColors.border,
          thickness: 0.5,
          space: 0,
        ),

        // ── Dialog ─────────────────────────────
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.xlRadius,
          ),
          titleTextStyle: AppTextStyles.headlineSmall,
          contentTextStyle: AppTextStyles.bodyMedium,
        ),

        // ── Bottom Sheet ───────────────────────
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
          ),
          showDragHandle: true,
          dragHandleColor: AppColors.slate300,
          dragHandleSize: Size(36, 4),
        ),

        // ── Snackbar ───────────────────────────
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.primary,
          contentTextStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textOnPrimary,
          ),
          actionTextColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.mdRadius,
          ),
        ),

        // ── Switch ─────────────────────────────
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.textOnAccent;
            }
            return AppColors.slate400;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.accent;
            }
            return AppColors.slate200;
          }),
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        ),

        // ── Checkbox ───────────────────────────
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.accent;
            }
            return Colors.transparent;
          }),
          checkColor: WidgetStateProperty.all(AppColors.textOnAccent),
          side: const BorderSide(color: AppColors.borderStrong, width: 1.5),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ),

        // ── Radio ──────────────────────────────
        radioTheme: RadioThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.accent;
            return AppColors.slate400;
          }),
        ),

        // ── Progress Indicator ─────────────────
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.accent,
          circularTrackColor: AppColors.slate200,
          linearTrackColor: AppColors.slate200,
          linearMinHeight: 3,
        ),

        // ── Tab Bar ────────────────────────────
        tabBarTheme: TabBarThemeData(
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: AppTextStyles.labelLarge,
          unselectedLabelStyle: AppTextStyles.labelLarge,
          indicatorColor: AppColors.accent,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: AppColors.border,
          dividerHeight: 0.5,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
        ),

        // ── Floating Action Button ─────────────
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.textOnAccent,
          elevation: 0,
          focusElevation: 0,
          hoverElevation: 0,
          highlightElevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.lgRadius,
          ),
        ),

        // ── Icon ───────────────────────────────
        iconTheme: const IconThemeData(
          color: AppColors.textSecondary,
          size: 22,
        ),

        // ── Popup Menu ─────────────────────────
        popupMenuTheme: PopupMenuThemeData(
          color: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.lgRadius,
          ),
          textStyle: AppTextStyles.bodyMedium,
          labelTextStyle: WidgetStateProperty.all(AppTextStyles.bodyMedium),
        ),
      );
}