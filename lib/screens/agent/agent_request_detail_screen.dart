import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../widgets/common/app_card.dart';

class AgentRequestDetailScreen extends StatelessWidget {
  const AgentRequestDetailScreen({
    super.key,
    required this.requestData,
    required this.requestId,
  });

  final Map<String, dynamic> requestData;
  final String requestId;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final int startDateMs = (requestData['startDate'] is num)
        ? (requestData['startDate'] as num).toInt()
        : 0;
    final String dateText = startDateMs > 0
        ? DateFormat('dd MMM yyyy, hh:mm a')
            .format(DateTime.fromMillisecondsSinceEpoch(startDateMs))
        : '-';

    final String pickUp = (requestData['pickUp'] ?? '-').toString();
    final String destination = (requestData['destination'] ?? '-').toString();
    final String cabType = (requestData['cabType'] ?? '-').toString();
    final String pax = (requestData['pax'] ?? '-').toString();
    final String nights = (requestData['noOfNights'] ?? '-').toString();
    final String minBudget = (requestData['minBudget'] ?? '').toString();
    final String maxBudget = (requestData['maxBudget'] ?? '').toString();
    final String budget = (minBudget.isEmpty && maxBudget.isEmpty)
        ? 'Not specified'
        : (minBudget.isEmpty ? 'Up to Rs $maxBudget' : (maxBudget.isEmpty ? 'From Rs $minBudget' : 'Rs $minBudget - Rs $maxBudget'));
    final String status = (requestData['status'] ?? 'open').toString();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Request Details',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Route Header Card
            AppCard(
              showAccent: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          requestId,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: isDark ? AppColorsDark.textSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      _statusBadge(status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Route visualization
                  _routeRow(context, Icons.trip_origin, AppColors.primaryYellow, pickUp, isDark),
                  Padding(
                    padding: const EdgeInsets.only(left: 11),
                    child: Container(
                      width: 2,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primaryYellow,
                            isDark ? AppColorsDark.textHint : AppColors.textHint,
                          ],
                        ),
                      ),
                    ),
                  ),
                  _routeRow(context, Icons.location_on, isDark ? AppColorsDark.textHint : AppColors.textHint, destination, isDark),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Trip Details Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'TRIP DETAILS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: isDark ? AppColorsDark.textSecondary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _detailTile(context, Icons.calendar_today_outlined, 'Start Date', dateText, isDark),
                  _divider(isDark),
                  _detailTile(context, Icons.directions_car_filled_outlined, 'Cab Type', cabType, isDark),
                  _divider(isDark),
                  _detailTile(context, Icons.people_outlined, 'Passengers', '$pax pax', isDark),
                  _divider(isDark),
                  _detailTile(context, Icons.nightlight_outlined, 'Nights', nights, isDark),
                  _divider(isDark),
                  _detailTile(context, Icons.account_balance_wallet_outlined, 'Budget', budget, isDark),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Status & Tracking Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'STATUS & TRACKING',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: isDark ? AppColorsDark.textSecondary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _detailTile(context, Icons.flag_outlined, 'Status', status, isDark),
                  _divider(isDark),
                  _detailTile(context, Icons.admin_panel_settings_outlined, 'Admin Status', (requestData['adminStatus'] ?? '-').toString(), isDark),
                  _divider(isDark),
                  _detailTile(context, Icons.confirmation_number_outlined, 'Tracking ID', (requestData['trackingId'] ?? '-').toString(), isDark),
                ],
              ),
            ),

            // Other Info (only if present)
            if ((requestData['otherInfo'] ?? '').toString().trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'ADDITIONAL INFO',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: isDark ? AppColorsDark.textSecondary : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColorsDark.subtleBg : AppColors.subtleBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        (requestData['otherInfo'] ?? '-').toString(),
                        style: TextStyle(
                          color: isDark ? AppColorsDark.textPrimary : AppColors.textPrimary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _routeRow(BuildContext context, IconData icon, Color iconColor, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColorsDark.textPrimary : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailTile(BuildContext context, IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.primaryYellow.withValues(alpha: 0.12)
                  : AppColors.primaryYellow.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primaryYellowDark),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColorsDark.textSecondary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColorsDark.textPrimary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      height: 1,
      color: isDark ? AppColorsDark.borderDefault : AppColors.borderDefault,
    );
  }

  Widget _statusBadge(String status) {
    final String normalized = status.trim().toLowerCase();
    Color color = AppColors.infoBlue;
    if (normalized == 'open') color = AppColors.warningOrange;
    if (normalized == 'closed' || normalized == 'booked') color = AppColors.successGreen;
    if (normalized == 'cancelled') color = AppColors.errorRed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
