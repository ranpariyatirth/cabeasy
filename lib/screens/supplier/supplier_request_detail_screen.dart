/// CabEasy - SupplierRequestDetailScreen
/// Purpose: Detail view for a specific request with ability to submit bid
/// Author: CabEasy Dev

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/request_model.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/common/gradient_button.dart';
import '../../providers/bid_provider.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_colors.dart';
import 'supplier_bid_screen.dart';

class SupplierRequestDetailScreen extends StatefulWidget {
  final RequestModel request;

  const SupplierRequestDetailScreen({Key? key, required this.request}) : super(key: key);

  @override
  _SupplierRequestDetailScreenState createState() => _SupplierRequestDetailScreenState();
}

class _SupplierRequestDetailScreenState extends State<SupplierRequestDetailScreen> {
  bool _hasUserBid = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkIfUserHasBid();
  }

  Future<void> _checkIfUserHasBid() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final bidProvider = Provider.of<BidProvider>(context, listen: false);

      if (authProvider.currentUser != null) {
        final hasBid = await bidProvider.hasUserBidOnRequest(
          widget.request.id,
          authProvider.currentUser!.uid,
        );

        setState(() {
          _hasUserBid = hasBid;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking if user has bid: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Request Details',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRouteSection(),
                  const SizedBox(height: 24),
                  _buildTripDetailsCard(),
                  const SizedBox(height: 24),
                  _buildAgentInfoCard(),
                  const SizedBox(height: 24),
                  if (widget.request.notes != null && widget.request.notes!.isNotEmpty)
                    _buildNotesSection(),
                  const SizedBox(height: 24),
                  _buildBidsCount(),
                  const SizedBox(height: 24),
                  if (!_hasUserBid)
                    _buildSubmitBidButton()
                  else
                    _buildAlreadyBidMessage(),
                ],
              ),
            ),
    );
  }

  Widget _buildRouteSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusBadge(status: widget.request.leadLevel),
              Text(
                DateFormat('dd MMM yyyy').format(widget.request.travelDate),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppColors.primaryYellow,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.request.pickupLocation,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.more_vert, size: 24, color: AppColors.textHint),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.textHint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.request.dropLocation,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTripDetailsCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TRIP DETAILS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: AppColors.textHint, size: 20),
              const SizedBox(width: 12),
              Text(
                DateFormat('dd MMM yyyy, hh:mm a').format(widget.request.travelDate),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.group, color: AppColors.textHint, size: 20),
              const SizedBox(width: 12),
              Text(
                '${widget.request.passengerCount} passenger${widget.request.passengerCount > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _getVehicleIcon(widget.request.vehicleType),
              const SizedBox(width: 12),
              Text(
                _formatVehicleType(widget.request.vehicleType),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAgentInfoCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AGENT INFO',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: AppColors.primaryYellow),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.request.agentName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Agent',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NOTES',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.request.notes!,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBidsCount() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.subtleBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryYellow.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.gavel, color: AppColors.primaryYellow, size: 20),
          const SizedBox(width: 12),
          Text(
            '${widget.request.bidCount} bid${widget.request.bidCount > 1 ? 's' : ''} submitted',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitBidButton() {
    return GradientButton(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SupplierBidScreen(request: widget.request),
          ),
        );
      },
      text: 'Submit Bid',
      icon: Icons.gavel,
    );
  }

  Widget _buildAlreadyBidMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.successGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.successGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.successGreen, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'You have already submitted a bid for this request',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.successGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Icon _getVehicleIcon(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'sedan':
        return const Icon(Icons.directions_car, color: AppColors.textHint, size: 20);
      case 'suv':
        return const Icon(Icons.directions_car, color: AppColors.textHint, size: 20);
      case 'tempo':
        return const Icon(Icons.directions_bus, color: AppColors.textHint, size: 20);
      case 'bus':
        return const Icon(Icons.directions_bus, color: AppColors.textHint, size: 20);
      default:
        return const Icon(Icons.local_shipping, color: AppColors.textHint, size: 20);
    }
  }

  String _formatVehicleType(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'sedan':
        return 'Sedan';
      case 'suv':
        return 'SUV';
      case 'tempo':
        return 'Tempo Traveller';
      case 'bus':
        return 'Bus';
      default:
        return vehicleType;
    }
  }
}