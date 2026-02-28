/// CabEasy - AppColors
/// Purpose: Centralized color constants for the CabEasy app
/// Author: CabEasy Dev

import 'package:flutter/material.dart';

class AppColors {
  // PRIMARY BRAND COLORS
  static const Color primaryYellow = Color(0xFFFFD700);
  static const Color primaryYellowDark = Color(0xFFFFC400);

  // BACKGROUNDS
  static const Color scaffoldBg = Color(0xFFFAFAFA);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color subtleBg = Color(0xFFFFF9E6); // yellow-tinted highlight

  // TEXT
  static const Color textPrimary = Color(0xFF1A1A1A); // Colors.black87
  static const Color textSecondary = Color(0xFF757575); // Colors.grey[600]
  static const Color textHint = Color(0xFFBDBDBD); // Colors.grey[400]

  // BORDERS
  static const Color borderDefault = Color(0xFFE0E0E0); // Colors.grey[300]
  static const Color borderFocused = Color(0xFFFFD700);
  static const Color borderFilled = Color(0xFFFFE066);

  // STATUS COLORS
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color errorRed = Color(0xFFE53935);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color infoBlue = Color(0xFF2196F3);

  // SHADOW COLORS
  static const Color shadowYellow = Color(0x66FFD700); // 40% opacity
  static const Color shadowGrey = Color(0x1A000000); // 10% opacity

  // === Responsive spacing constants ===

  /// Returns responsive padding based on screen width
  static EdgeInsets responsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) {
      return const EdgeInsets.all(16);
    } else if (width < 400) {
      return const EdgeInsets.all(20);
    }
    return const EdgeInsets.all(24);
  }

  /// Returns responsive horizontal padding
  static EdgeInsets responsiveHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) {
      return const EdgeInsets.symmetric(horizontal: 16);
    } else if (width < 400) {
      return const EdgeInsets.symmetric(horizontal: 20);
    }
    return const EdgeInsets.symmetric(horizontal: 24);
  }

  /// Standard card padding
  static const EdgeInsets cardPadding = EdgeInsets.all(20);

  /// Standard spacing
  static const double spacingXS = 4;
  static const double spacingS = 8;
  static const double spacingM = 16;
  static const double spacingL = 24;
  static const double spacingXL = 32;
  static const double spacingXXL = 48;

  /// Standard border radius
  static const double radiusS = 8;
  static const double radiusM = 12;
  static const double radiusL = 16;
  static const double radiusXL = 20;
  static const double radiusXXL = 24;

  /// Standard button height
  static const double buttonHeight = 56;
  static const double buttonHeightSmall = 48;
}

/// Dark theme colors — mirrors AppColors for dark mode
class AppColorsDark {
  // PRIMARY BRAND COLORS (kept vibrant)
  static const Color primaryYellow = Color(0xFFFFD700);
  static const Color primaryYellowDark = Color(0xFFFFC400);

  // BACKGROUNDS
  static const Color scaffoldBg = Color(0xFF121212);
  static const Color cardBg = Color(0xFF1E1E1E);
  static const Color subtleBg = Color(0xFF2A2510); // dark yellow-tinted highlight

  // TEXT
  static const Color textPrimary = Color(0xFFE0E0E0);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textHint = Color(0xFF616161);

  // BORDERS
  static const Color borderDefault = Color(0xFF2C2C2C);
  static const Color borderFocused = Color(0xFFFFD700);
  static const Color borderFilled = Color(0xFFFFE066);

  // STATUS COLORS (same for both themes)
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color errorRed = Color(0xFFE53935);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color infoBlue = Color(0xFF2196F3);

  // SHADOW COLORS
  static const Color shadowYellow = Color(0x66FFD700);
  static const Color shadowGrey = Color(0x33000000);
}
