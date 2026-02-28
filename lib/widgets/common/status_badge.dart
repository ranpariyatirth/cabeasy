/// CabEasy - StatusBadge
/// Purpose: Reusable status badge widget for displaying statuses
/// Author: CabEasy Dev

import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final Color? color;
  final String? text;

  const StatusBadge({
    Key? key,
    required this.status,
    this.color,
    this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    String displayText = text ?? status;

    switch (status.toLowerCase()) {
      case 'hot':
        badgeColor = AppColors.warningOrange;
        displayText = '🔥 HOT';
        break;
      case 'warm':
        badgeColor = Colors.orange;
        displayText = '♨️ WARM';
        break;
      case 'cold':
        badgeColor = AppColors.infoBlue;
        displayText = '🧊 COLD';
        break;
      case 'pending':
        badgeColor = AppColors.warningOrange;
        break;
      case 'accepted':
        badgeColor = AppColors.successGreen;
        break;
      case 'rejected':
        badgeColor = AppColors.errorRed;
        break;
      case 'open':
        badgeColor = AppColors.primaryYellow;
        break;
      case 'booked':
        badgeColor = AppColors.successGreen;
        break;
      case 'cancelled':
        badgeColor = AppColors.errorRed;
        break;
      case 'confirmed':
        badgeColor = AppColors.successGreen;
        break;
      case 'in_progress':
        badgeColor = AppColors.warningOrange;
        break;
      case 'completed':
        badgeColor = AppColors.successGreen;
        displayText = 'COMPLETED';
        break;
      default:
        badgeColor = color ?? AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Text(
        displayText.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: badgeColor,
        ),
      ),
    );
  }
}