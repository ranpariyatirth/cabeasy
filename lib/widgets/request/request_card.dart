/// CabEasy - RequestCard
/// Purpose: Widget to display a transport request in a card format
/// Author: CabEasy Dev

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/request_model.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/status_badge.dart';
import '../../constants/app_colors.dart';
import '../../screens/supplier/supplier_request_detail_screen.dart';

class RequestCard extends StatelessWidget {
  final RequestModel request;

  const RequestCard({Key? key, required this.request}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with lead level and vehicle type
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusBadge(status: request.leadLevel),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _formatVehicleType(request.vehicleType),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (request.bidCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${request.bidCount} bid${request.bidCount > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Route information
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.primaryYellow, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  request.pickupLocation,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_downward, size: 16, color: AppColors.textHint),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.textHint, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  request.dropLocation,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Divider
          Container(
            height: 1,
            color: AppColors.borderDefault,
          ),
          const SizedBox(height: 16),

          // Agent and passenger info
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person, size: 16, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 170),
                    child: Text(
                      request.agentName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.group, size: 16, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    '${request.passengerCount} pax',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Date and time
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: AppColors.textHint),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(request.travelDate),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Submit bid button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SupplierRequestDetailScreen(request: request),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryYellow,
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              child: const Text(
                'Submit Your Bid →',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatVehicleType(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'sedan':
        return 'SEDAN';
      case 'suv':
        return 'SUV';
      case 'tempo':
        return 'TEMPO';
      case 'bus':
        return 'BUS';
      default:
        return vehicleType.toUpperCase();
    }
  }
}
