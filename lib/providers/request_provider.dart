/// CabEasy - RequestProvider
/// Purpose: Provider for request data and operations
/// Author: CabEasy Dev

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/request_model.dart';
import '../services/firestore_service.dart';

class RequestProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<RequestModel> _requests = [];
  bool _isLoading = false;
  String _filter = 'all'; // all, hot, warm, cold
  StreamSubscription<List<RequestModel>>? _requestSubscription;

  List<RequestModel> get requests => _requests;
  bool get isLoading => _isLoading;
  String get filter => _filter;

  Future<void> loadRequests() async {
    // Cancel any existing stream subscription to prevent leaks
    await _requestSubscription?.cancel();
    _requestSubscription = null;

    _isLoading = true;
    notifyListeners();

    try {
      final Stream<List<RequestModel>> stream = _filter == 'all'
          ? _firestoreService.getOpenRequestsStream()
          : _firestoreService.getFilteredRequestsStream(_filter);

      _requestSubscription = stream.listen(
        (requests) {
          _requests = requests;
          _isLoading = false;
          notifyListeners();
        },
        onError: (e) {
          debugPrint('Error in requests stream: $e');
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Error loading requests: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(String filter) {
    if (_filter == filter) return; // no-op if filter hasn't changed
    _filter = filter;
    loadRequests();
  }

  Future<void> createRequest(RequestModel request) async {
    try {
      await _firestoreService.createRequest(request);
    } catch (e) {
      debugPrint('Error creating request: $e');
      rethrow;
    }
  }

  Future<RequestModel?> getRequestById(String requestId) async {
    try {
      return await _firestoreService.getRequestById(requestId);
    } catch (e) {
      debugPrint('Error getting request by id: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _requestSubscription?.cancel();
    super.dispose();
  }
}