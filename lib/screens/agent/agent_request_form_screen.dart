/// CabEasy - AgentRequestFormScreen
/// Purpose: Form for agents to create new transport requests
/// Author: CabEasy Dev

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../models/request_model.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/gradient_button.dart';
import '../../providers/request_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/n8n_service.dart';
import '../../services/firestore_service.dart';
import '../../constants/app_colors.dart';

class AgentRequestFormScreen extends StatefulWidget {
  @override
  _AgentRequestFormScreenState createState() => _AgentRequestFormScreenState();
}

class _AgentRequestFormScreenState extends State<AgentRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pickupController = TextEditingController();
  final _dropController = TextEditingController();
  final _passengerCountController = TextEditingController(text: '1');
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedVehicleType = 'sedan';
  bool _isLoading = false;
  String _errorMessage = '';

  final List<Map<String, String>> _vehicleTypes = [
    {'name': 'Sedan', 'value': 'sedan'},
    {'name': 'SUV', 'value': 'suv'},
    {'name': 'Tempo Traveller', 'value': 'tempo'},
    {'name': 'Bus', 'value': 'bus'},
  ];

  @override
  void dispose() {
    _pickupController.dispose();
    _dropController.dispose();
    _passengerCountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryYellow,
              onPrimary: Colors.black87,
              surface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryYellow,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryYellow,
              onPrimary: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final requestProvider = Provider.of<RequestProvider>(
        context,
        listen: false,
      );
      final firestoreService = FirestoreService();

      if (authProvider.currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Combine date and time
      final travelDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final request = RequestModel(
        id: const Uuid().v4(),
        agentId: authProvider.currentUser!.uid,
        agentName: authProvider.currentUser!.name,
        pickupLocation: _pickupController.text,
        dropLocation: _dropController.text,
        travelDate: travelDateTime,
        passengerCount: int.tryParse(_passengerCountController.text) ?? 1,
        vehicleType: _selectedVehicleType,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        status: 'open',
        leadLevel: 'unclassified',
        createdAt: DateTime.now(),
        bidCount: 0,
      );

      // Save to Firestore
      await requestProvider.createRequest(request);

      // Call n8n webhook AFTER saving to Firestore
      // Do NOT await or block UI - fire and forget
      N8nService.triggerLeadClassification(
        requestId: request.id,
        pickupLocation: request.pickupLocation,
        dropLocation: request.dropLocation,
        travelDate: request.travelDate,
        passengerCount: request.passengerCount,
        vehicleType: request.vehicleType,
        agentId: request.agentId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryYellow,
            content: const Text(
              'Request submitted successfully!',
              style: TextStyle(color: Colors.black87),
            ),
            duration: const Duration(seconds: 2),
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error submitting request: $e');

      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to submit request. Please try again.';
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
          'New Request',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
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
                    border: Border.all(
                      color: AppColors.errorRed.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.errorRed,
                        size: 20,
                      ),
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
              _buildPickupField(),
              const SizedBox(height: 24),
              _buildDropField(),
              const SizedBox(height: 24),
              _buildDateTimeFields(),
              const SizedBox(height: 24),
              _buildPassengerCountField(),
              const SizedBox(height: 24),
              _buildVehicleTypeField(),
              const SizedBox(height: 24),
              _buildNotesField(),
              const SizedBox(height: 32),
              GradientButton(
                onTap: _isLoading ? null : _submitRequest,
                text: 'Submit Request',
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickupField() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PICKUP LOCATION',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _pickupController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter pickup location';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: 'Enter pickup location',
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
              prefixIcon: const Icon(
                Icons.location_on,
                color: AppColors.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropField() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DROP LOCATION',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _dropController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter drop location';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: 'Enter drop location',
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
              prefixIcon: const Icon(
                Icons.location_on,
                color: AppColors.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeFields() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TRAVEL DATE & TIME',
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
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderDefault),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('dd MMM yyyy').format(_selectedDate),
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _selectTime(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderDefault),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _selectedTime.format(context),
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerCountField() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NUMBER OF PASSENGERS',
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
              IconButton(
                onPressed: () {
                  final current =
                      int.tryParse(_passengerCountController.text) ?? 1;
                  if (current > 1) {
                    setState(() {
                      _passengerCountController.text = (current - 1).toString();
                    });
                  }
                },
                icon: const Icon(Icons.remove_circle_outline),
                color: AppColors.primaryYellow,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _passengerCountController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter passenger count';
                    }
                    final count = int.tryParse(value);
                    if (count == null || count <= 0) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
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
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () {
                  final current =
                      int.tryParse(_passengerCountController.text) ?? 1;
                  setState(() {
                    _passengerCountController.text = (current + 1).toString();
                  });
                },
                icon: const Icon(Icons.add_circle),
                color: AppColors.primaryYellow,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleTypeField() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'VEHICLE TYPE PREFERENCE',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _vehicleTypes.map((vehicle) {
              final isSelected = _selectedVehicleType == vehicle['value'];
              return ChoiceChip(
                label: Text(
                  vehicle['name']!,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.black87
                        : AppColors.textSecondary,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primaryYellow.withOpacity(0.2),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primaryYellow
                        : AppColors.borderDefault,
                  ),
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedVehicleType = vehicle['value']!;
                    });
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesField() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NOTES (OPTIONAL)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add any special requirements or notes',
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
