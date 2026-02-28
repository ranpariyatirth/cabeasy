/// CabEasy - BidCard
/// Purpose: Widget to display a supplier bid in a card format
/// Author: CabEasy Dev

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/bid_model.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/status_badge.dart';
import '../../constants/app_colors.dart';

class BidCard extends StatelessWidget {
  final BidModel bid;
  final bool isOwnBid;

  const BidCard({Key? key, required this.bid, this.isOwnBid = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusBadge(status: bid.status),
              if (isOwnBid)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryYellow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'YOUR BID',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryYellow,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.currency_rupee, size: 20, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text(
                NumberFormat('#,##0').format(bid.amount),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.directions_car, size: 20, color: AppColors.textHint),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_formatVehicleType(bid.vehicleType)} - ${bid.vehicleNumber}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person, size: 20, color: AppColors.textHint),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bid.driverName ?? 'No driver assigned',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (bid.note.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.subtleBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                bid.note,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd MMM yyyy, hh:mm a').format(bid.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
              ),
              Text(
                bid.supplierName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatVehicleType(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'sedan':
        return 'Sedan';
      case 'suv':
        return 'SUV';
      case 'innova':
        return 'Innova Crysta';
      case 'tempo':
        return 'Tempo Traveller';
      case 'mini_bus':
        return 'Mini Bus';
      case 'luxury':
        return 'Luxury';
      default:
        return vehicleType;
    }
  }
}