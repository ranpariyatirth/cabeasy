/// CabEasy - BidProvider
/// Purpose: Provider for bid data and operations
/// Author: CabEasy Dev

import 'package:flutter/foundation.dart';
import '../models/bid_model.dart';
import '../services/firestore_service.dart';

class BidProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<BidModel> _bids = [];
  bool _isLoading = false;
  String? _requestId;

  List<BidModel> get bids => _bids;
  bool get isLoading => _isLoading;
  String? get requestId => _requestId;

  void loadBidsForRequest(String requestId) {
    if (_requestId == requestId) return;

    _requestId = requestId;
    _isLoading = true;
    _bids = [];
    notifyListeners();

    try {
      _firestoreService.getBidsForRequestStream(requestId).listen((bids) {
        _bids = bids;
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error loading bids: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createBid(BidModel bid) async {
    try {
      await _firestoreService.createBid(bid);
    } catch (e) {
      debugPrint('Error creating bid: $e');
      rethrow;
    }
  }

  Future<bool> hasUserBidOnRequest(String requestId, String supplierId) async {
    try {
      return await _firestoreService.hasUserBidOnRequest(requestId, supplierId);
    } catch (e) {
      debugPrint('Error checking if user has bid on request: $e');
      return false;
    }
  }
}