/// CabEasy - SupplierHomeScreen
/// Purpose: Main home screen for suppliers to view available requests
/// Author: CabEasy Dev

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/request/request_card.dart';
import '../../providers/request_provider.dart';
import '../../constants/app_colors.dart';

class SupplierHomeScreen extends StatefulWidget {
  @override
  _SupplierHomeScreenState createState() => _SupplierHomeScreenState();
}

class _SupplierHomeScreenState extends State<SupplierHomeScreen> {
  final List<Map<String, dynamic>> _filters = [
    {'label': 'All', 'value': 'all'},
    {'label': 'Hot 🔥', 'value': 'hot'},
    {'label': 'Warm', 'value': 'warm'},
    {'label': 'Cold', 'value': 'cold'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: _buildAppBar(),
      body: Consumer<RequestProvider>(
        builder: (context, requestProvider, child) {
          return RefreshIndicator(
            color: AppColors.primaryYellow,
            onRefresh: () async {
              requestProvider.loadRequests();
            },
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                const SizedBox(height: 16),
                _buildFilterChips(context),
                const SizedBox(height: 16),
                if (requestProvider.isLoading)
                  _buildLoadingState()
                else if (requestProvider.requests.isEmpty)
                  _buildEmptyState()
                else
                  _buildRequestsList(requestProvider.requests),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Available Requests',
        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final requestProvider = Provider.of<RequestProvider>(
      context,
      listen: false,
    );

    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = requestProvider.filter == filter['value'];

          return ChoiceChip(
            label: Text(
              filter['label'],
              style: TextStyle(
                color: isSelected ? Colors.black87 : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            selectedColor: AppColors.primaryYellow.withOpacity(0.2),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected
                    ? AppColors.primaryYellow
                    : AppColors.borderDefault,
              ),
            ),
            onSelected: (selected) {
              if (selected) {
                requestProvider.setFilter(filter['value']);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: AppCard(
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'No requests available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new requests',
              style: TextStyle(fontSize: 15, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList(List requests) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: requests.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: RequestCard(request: requests[index]),
        );
      },
    );
  }
}
