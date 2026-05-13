import 'package:flutter/material.dart';

class M85Colors {
  static const background = Color(0xFFF8FAFC);
  static const backgroundHover = Color(0xFFF1F5F9);
  static const backgroundStrong = Color(0xFFFFFFFF);
  static const color = Color(0xFF0F172A);
  static const colorMuted = Color(0xFF64748B);
  static const borderColor = Color(0xFFE2E8F0);
  static const borderColorHover = Color(0xFFCBD5E1);

  static const primary = Color(0xFFEA580C);
  static const primaryHover = Color(0xFFC2410C);
  static const primarySoft = Color(0xFFFFF7ED);

  static const success = Color(0xFF10B981);
  static const successSoft = Color(0xFFECFDF5);
  static const warning = Color(0xFFF59E0B);
  static const warningSoft = Color(0xFFFFFBEB);
  static const danger = Color(0xFFEF4444);
  static const dangerSoft = Color(0xFFFEF2F2);
}

class M85Space {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
}

class M85Sizes {
  static const double workerColW = 240;
  static const double costCodeColW = 130;
  static const double hoursColW = 80;
  static const double otColW = 70;
  static const double perDiemColW = 110;

  static const double headerH = 64;
  static const double rowH = 44;
  static const double footerH = 44;
  static const double quantityRowH = 38;
  static const double toolbarH = 56;
  static const double cellPadH = 8;
  static const double cellPadV = 6;
}

class M85Text {
  static const TextStyle h1 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: M85Colors.color,
    height: 1.2,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: M85Colors.color,
    height: 1.3,
  );
  static const TextStyle bodyMuted = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: M85Colors.colorMuted,
    height: 1.3,
  );
  static const TextStyle label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: M85Colors.colorMuted,
    letterSpacing: 1,
    height: 1.2,
  );
  static const TextStyle code = TextStyle(
    fontFamily: 'Menlo',
    fontFamilyFallback: ['Courier', 'monospace'],
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: M85Colors.color,
    height: 1.2,
  );
  static const TextStyle num = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: M85Colors.color,
    fontFeatures: [FontFeature.tabularFigures()],
    height: 1.3,
  );
  static const TextStyle numBold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: M85Colors.color,
    fontFeatures: [FontFeature.tabularFigures()],
    height: 1.3,
  );
}

ThemeData buildMark85Theme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: M85Colors.background,
    canvasColor: M85Colors.backgroundStrong,
    colorScheme: ColorScheme.fromSeed(
      seedColor: M85Colors.primary,
      brightness: Brightness.light,
      primary: M85Colors.primary,
      surface: M85Colors.backgroundStrong,
      onSurface: M85Colors.color,
    ),
    fontFamily: 'SF Pro Text',
    textTheme: const TextTheme(
      bodyMedium: M85Text.body,
      bodySmall: M85Text.bodyMuted,
      labelSmall: M85Text.label,
      titleLarge: M85Text.h1,
    ),
    dividerColor: M85Colors.borderColor,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}
