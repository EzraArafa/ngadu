import 'package:flutter/material.dart';

import '../models/complaint.dart';

/// Palet warna aplikasi NGADU (Slate + Royal Blue & Cyan).
class AppColors {
  AppColors._();

  // Brand Utama
  static const Color primary = Color(0xFF2563EB); // Blue 600
  static const Color primaryDark = Color(0xFF1D4ED8); // Blue 700
  static const Color secondary = Color(0xFF0284C7); // Sky 600
  static const Color primaryTint = Color(0xFFEFF6FF); // Blue 50
  static const Color primaryBorder = Color(0xFFBFDBFE); // Blue 200

  // Permukaan & Latar
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color surfaceSubtle = Color(0xFFF1F5F9); // Slate 100

  // Garis & Pembatas
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color borderStrong = Color(0xFFCBD5E1); // Slate 300

  // Teks
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400

  // Status: Menunggu (Amber)
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color warningText = Color(0xFFB45309);
  static const Color warningBorder = Color(0xFFFDE68A);
  static const Color warningDot = Color(0xFFF59E0B);

  // Status: Sedang Diproses (Blue)
  static const Color infoBg = Color(0xFFEFF6FF);
  static const Color infoText = Color(0xFF1D4ED8);
  static const Color infoBorder = Color(0xFFBFDBFE);
  static const Color infoDot = Color(0xFF2563EB);

  // Status: Selesai (Emerald)
  static const Color successBg = Color(0xFFECFDF5);
  static const Color successText = Color(0xFF047857);
  static const Color successBorder = Color(0xFFA7F3D0);
  static const Color successDot = Color(0xFF10B981);

  // Status: Ditolak / Destructive (Rose)
  static const Color dangerBg = Color(0xFFFFF1F2);
  static const Color dangerText = Color(0xFFBE123C);
  static const Color dangerBorder = Color(0xFFFECDD3);
  static const Color dangerDot = Color(0xFFF43F5E);
}

/// Standar jarak (padding & margin) konsisten.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double cardGap = 14;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
}

/// Standar kelengkungan sudut (border radius).
class AppRadius {
  AppRadius._();

  static const double badge = 8;
  static const double input = 12;
  static const double compactCard = 14;
  static const double card = 18;
  static const double pill = 999;
}

/// Konfigurasi ThemeData global untuk MaterialApp.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.dangerText,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        hintStyle: const TextStyle(
          fontSize: 12,
          color: AppColors.textMuted,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.dangerDot),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
      ),
    );
  }
}

class ComplaintStatusStyle {
  const ComplaintStatusStyle({
    required this.background,
    required this.foreground,
    required this.border,
    required this.dot,
    required this.icon,
  });

  final Color background;
  final Color foreground;
  final Color border;
  final Color dot;
  final IconData icon;
}

extension ComplaintStatusTheme on ComplaintStatus {
  ComplaintStatusStyle get style => switch (this) {
        ComplaintStatus.menunggu => const ComplaintStatusStyle(
            background: AppColors.warningBg,
            foreground: AppColors.warningText,
            border: AppColors.warningBorder,
            dot: AppColors.warningDot,
            icon: Icons.schedule_rounded,
          ),
        ComplaintStatus.diproses => const ComplaintStatusStyle(
            background: AppColors.infoBg,
            foreground: AppColors.infoText,
            border: AppColors.infoBorder,
            dot: AppColors.infoDot,
            icon: Icons.build_rounded,
          ),
        ComplaintStatus.selesai => const ComplaintStatusStyle(
            background: AppColors.successBg,
            foreground: AppColors.successText,
            border: AppColors.successBorder,
            dot: AppColors.successDot,
            icon: Icons.check_circle_outline_rounded,
          ),
        ComplaintStatus.ditolak => const ComplaintStatusStyle(
            background: AppColors.dangerBg,
            foreground: AppColors.dangerText,
            border: AppColors.dangerBorder,
            dot: AppColors.dangerDot,
            icon: Icons.cancel_outlined,
          ),
      };
}

extension ComplaintCategoryTheme on ComplaintCategory {
  IconData get icon => switch (this) {
        ComplaintCategory.listrikAc => Icons.bolt_rounded,
        ComplaintCategory.bangunan => Icons.apartment_rounded,
        ComplaintCategory.jalanLuar => Icons.park_outlined,
        ComplaintCategory.kebersihan => Icons.cleaning_services_outlined,
        ComplaintCategory.lainnya => Icons.category_outlined,
      };
}