/// CabEasy - AppTextStyles
/// Purpose: Centralized text style constants for the CabEasy app
/// Author: CabEasy Dev

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Headings
  static const TextStyle heading = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  // Subheadings
  static const TextStyle subheading = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  // Body labels
  static const TextStyle bodyLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  // Secondary text
  static const TextStyle secondary = TextStyle(
    fontSize: 15,
    color: AppColors.textSecondary,
  );

  // Captions
  static const TextStyle caption = TextStyle(
    fontSize: 13,
    color: AppColors.textSecondary,
  );

  // Copyright/fine print
  static const TextStyle finePrint = TextStyle(
    fontSize: 12,
    color: Color(0xFF9E9E9E), // Colors.grey[500]
  );

  // Body Small
  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  // Body Medium
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  // Title Medium
  static const TextStyle titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Title Large
  static const TextStyle titleLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  // === Responsive text styles ===

  /// Returns responsive font size based on screen width
  static double responsiveFontSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    // Scale font between 0.8x and 1.2x based on screen width
    // Base size is designed for 375px width (iPhone standard)
    return baseSize * (width / 375).clamp(0.8, 1.2);
  }

  /// Responsive heading that scales with screen size
  static TextStyle responsiveHeading(BuildContext context) {
    return TextStyle(
      fontSize: responsiveFontSize(context, 28),
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    );
  }

  /// Responsive body text that scales with screen size
  static TextStyle responsiveBody(BuildContext context) {
    return TextStyle(
      fontSize: responsiveFontSize(context, 16),
      color: AppColors.textPrimary,
    );
  }

  /// Responsive caption that scales with screen size
  static TextStyle responsiveCaption(BuildContext context) {
    return TextStyle(
      fontSize: responsiveFontSize(context, 13),
      color: AppColors.textSecondary,
    );
  }
}
