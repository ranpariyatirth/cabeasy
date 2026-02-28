/// CabEasy - SupplierBidScreen
/// Purpose: Screen for suppliers to submit bids on requests
/// Author: CabEasy Dev

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/request_model.dart';
import '../../models/bid_model.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/gradient_button.dart';
import '../../providers/bid_provider.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_colors.dart';

class SupplierBidScreen extends StatefulWidget {
  final RequestModel request;

  const SupplierBidScreen({Key? key, required this.request}) : super(key: key);

  @override
  _SupplierBidScreenState createState() => _SupplierBidScreenState();
}

class _SupplierBidScreenState extends State<SupplierBidScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _driverNameController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedVehicleType = '';
  bool _isLoading = false;
  String _errorMessage = '';

  final List<Map<String, String>> _vehicleTypes = [
    {'name': 'Sedan', 'value': 'sedan'},
    {'name': 'SUV', 'value': 'suv'},
    {'name': 'Innova Crysta', 'value': 'innova'},
    {'name': 'Tempo Traveller', 'value': 'tempo'},
    {'name': 'Mini Bus', 'value': 'mini_bus'},
    {'name': 'Luxury', 'value': 'luxury'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedVehicleType = widget.request.vehicleType;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _vehicleNumberController.dispose();
    _driverNameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitBid() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final bidProvider = Provider.of<BidProvider>(context, listen: false);

      if (authProvider.currentUser == null) {
        throw Exception('User not authenticated');
      }

      final bid = BidModel(
        id: const Uuid().v4(),
        requestId: widget.request.id,
        supplierId: authProvider.currentUser!.uid,
        supplierName: authProvider.currentUser!.name,
        supplierPhone: authProvider.currentUser!.phone,
        amount: double.tryParse(_amountController.text) ?? 0.0,
        vehicleType: _selectedVehicleType,
        vehicleNumber: _vehicleNumberController.text.toUpperCase(),
        driverName: _driverNameController.text,
        note: _noteController.text,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await bidProvider.createBid(bid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryYellow,
            content: const Text(
              'Bid submitted successfully!',
              style: TextStyle(color: Colors.black87),
            ),
            duration: const Duration(seconds: 2),
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error submitting bid: $e');

      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to submit bid. Please try again.';
          _isLoading = false;
        });
      }
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
          'Submit Bid',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.errorRed.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.errorRed, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.errorRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              _buildAmountField(),
              const SizedBox(height: 24),
              _buildVehicleTypeDropdown(),
              const SizedBox(height: 24),
              _buildVehicleNumberField(),
              const SizedBox(height: 24),
              _buildDriverNameField(),
              const SizedBox(height: 24),
              _buildNoteField(),
              const SizedBox(height: 32),
              GradientButton(
                onTap: _isLoading ? null : _submitBid,
                text: 'Submit Bid',
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BID AMOUNT (₹)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter bid amount';
              }
              if (double.tryParse(value) == null || double.parse(value) <= 0) {
                return 'Please enter a valid amount';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: 'Enter amount in ₹',
              hintStyle: const TextStyle(color: AppColors.textHint),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.borderDefault),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.borderDefault),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.borderFocused,
                  width: 2,
                ),
              ),
              prefixIcon: const Icon(Icons.currency_rupee, color: AppColors.textHint),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '₹2,000 – ₹5,000 est.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleTypeDropdown() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'VEHICLE TYPE',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedVehicleType,
            items: _vehicleTypes.map((vehicle) {
              return DropdownMenuItem(
                value: vehicle['value'],
                child: Text(vehicle['name']!),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedVehicleType = value;
                });
              }
            },
            decoration: InputDecoration(
              hintText: 'Select vehicle type',
              hintStyle: const TextStyle(color: AppColors.textHint),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.borderDefault),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.borderDefault),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.borderFocused,
                  width: 2,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select vehicle type';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleNumberField() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'VEHICLE NUMBER',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _vehicleNumberController,
            textCapitalization: TextCapitalization.characters,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter vehicle number';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: 'Enter vehicle number',
              hintStyle: const TextStyle(color: AppColors.textHint),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.borderDefault),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.borderDefault),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.borderFocused,
                  width: 2,
                ),
              ),
              prefixIcon: const Icon(Icons.confirmation_number, color: AppColors.textHint),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverNameField() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DRIVER NAME',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _driverNameController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter driver name';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: 'Enter driver name',
              hintStyle: const TextStyle(color: AppColors.textHint),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.borderDefault),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.borderDefault),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.borderFocused,
                  width: 2,
                ),
              ),
              prefixIcon: const Icon(Icons.person, color: AppColors.textHint),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteField() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NOTE TO AGENT (OPTIONAL)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _noteController,
            maxLines: 3,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: 'Add any additional notes (max 200 characters)',
              hintStyle: const TextStyle(color: AppColors.textHint),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.borderDefault),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.borderDefault),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.borderFocused,
                  width: 2,
                ),
              ),
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }
}