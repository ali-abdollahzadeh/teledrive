import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);

    const textPrimary = AppColors.textPrimaryDark;
    const textSecondary = AppColors.textSecondaryDark;
    const textHint = AppColors.textHintDark;

    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        primary: AppColors.teledriveBlue,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.cardDarkAlt,
        onPrimaryContainer: textPrimary,
        secondary: AppColors.teledriveBlueText,
        onSecondary: AppColors.onPrimary,
        secondaryContainer: AppColors.cardDark,
        onSecondaryContainer: textPrimary,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.defaultBlackText,
        tertiaryContainer: AppColors.tertiaryContainer,
        surface: AppColors.surfaceDark,
        surfaceContainerHighest: AppColors.surfaceVariantDark,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        error: AppColors.error,
        onError: Colors.white,
        outline: AppColors.dividerDark,
        shadow: Colors.black,
      ),
      scaffoldBackgroundColor: const Color.fromARGB(255, 0, 0, 0),
      textTheme: _buildTextTheme(textPrimary, textSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 19,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          letterSpacing: -0.2,
        ),
        iconTheme: const IconThemeData(
          color: textPrimary,
          size: 24,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: AppColors.dividerDark.withValues(alpha: 0.45),
          ),
        ),
      ),
      inputDecorationTheme: _buildInputTheme(
        fillColor: AppColors.cardDarkAlt,
        borderColor: AppColors.dividerDark.withValues(alpha: 0.65),
        textColor: textPrimary,
        hintColor: textHint,
      ),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.teledriveBlue,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      outlinedButtonTheme: _buildOutlinedButtonTheme(
        AppColors.dividerDark.withValues(alpha: 0.7),
        textPrimary,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.teledriveBlue,
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.dividerDark.withValues(alpha: 0.45),
        thickness: 1,
        space: 0,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        iconColor: AppColors.teledriveBlue,
        textColor: textPrimary,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.cardDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.dividerDark,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.cardDarkAlt,
        selectedColor: AppColors.teledriveBlue.withValues(alpha: 0.22),
        labelStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: textSecondary,
        ),
        side: BorderSide(
          color: AppColors.dividerDark.withValues(alpha: 0.5),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        checkmarkColor: AppColors.teledriveBlue,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.cardDarkAlt,
        contentTextStyle: GoogleFonts.poppins(
          color: textPrimary,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.glassTargetMainTabs,
        selectedItemColor: AppColors.glassTabSelectedText,
        unselectedItemColor: AppColors.glassTabUnselected,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.teledriveBlue,
        foregroundColor: AppColors.onPrimary,
        elevation: 2,
        shape: StadiumBorder(),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);

    const textPrimary = AppColors.textPrimaryLight;
    const textSecondary = AppColors.textSecondaryLight;
    const textHint = AppColors.textHintLight;

    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: AppColors.teledriveBlue,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.teledriveBlueText,
        secondary: AppColors.teledriveBlueText,
        onSecondary: AppColors.onPrimary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.teledriveBlueText,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.defaultBlackText,
        tertiaryContainer: AppColors.tertiaryContainer,
        surface: AppColors.surfaceLight,
        surfaceContainerHighest: AppColors.surfaceVariantLight,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        error: AppColors.error,
        onError: Colors.white,
        outline: AppColors.dividerLight,
        shadow: Colors.black,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.glassTargetMainTabs,
        selectedItemColor: AppColors.glassTabSelectedText,
        unselectedItemColor: AppColors.glassTabUnselected,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      scaffoldBackgroundColor: AppColors.surfaceLight,
      textTheme: _buildTextTheme(textPrimary, textSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.actionBarDefault,
        foregroundColor: AppColors.actionBarDefaultTitle,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 19,
          fontWeight: FontWeight.w500,
          color: AppColors.actionBarDefaultTitle,
          letterSpacing: -0.2,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.actionBarDefaultIcon,
          size: 24,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: AppColors.dividerLight.withValues(alpha: 0.8),
          ),
        ),
      ),
      inputDecorationTheme: _buildInputTheme(
        fillColor: AppColors.lightSurface,
        borderColor: AppColors.lightDivider,
        textColor: textPrimary,
        hintColor: textHint,
      ),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.teledriveBlue,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      outlinedButtonTheme: _buildOutlinedButtonTheme(
        AppColors.dividerLight,
        textPrimary,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.teledriveBlueText,
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerLight,
        thickness: 1,
        space: 0,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        iconColor: AppColors.teledriveBlue,
        textColor: textPrimary,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.cardLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.lightDivider,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedColor: AppColors.teledriveBlue.withValues(alpha: 0.18),
        labelStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: textSecondary,
        ),
        side: BorderSide(
          color: AppColors.lightDivider.withValues(alpha: 0.9),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        checkmarkColor: AppColors.teledriveBlue,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF323232),
        contentTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.teledriveBlue,
        foregroundColor: AppColors.onPrimary,
        elevation: 2,
        shape: StadiumBorder(),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: GoogleFonts.poppins(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: primary,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: primary,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: primary,
      ),
      headlineLarge: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w500,
        color: primary,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        color: primary,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: primary,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: primary,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: primary,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: primary,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: primary,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: secondary,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: secondary,
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: primary,
      ),
      labelMedium: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondary,
      ),
      labelSmall: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: secondary,
      ),
    );
  }

  static InputDecorationTheme _buildInputTheme({
    required Color fillColor,
    required Color borderColor,
    required Color textColor,
    required Color hintColor,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: borderColor, width: 1),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(
        color: AppColors.teledriveBlue,
        width: 1.5,
      ),
    );

    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      border: border,
      enabledBorder: border,
      focusedBorder: focusedBorder,
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: 1.2,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: GoogleFonts.poppins(
        color: hintColor,
        fontSize: 15,
      ),
      labelStyle: GoogleFonts.poppins(
        color: hintColor,
        fontSize: 15,
      ),
      floatingLabelStyle: GoogleFonts.poppins(
        color: AppColors.teledriveBlueText,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.teledriveBlue,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme(
    Color borderColor,
    Color textColor,
  ) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textColor,
        side: BorderSide(color: borderColor),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }
}
