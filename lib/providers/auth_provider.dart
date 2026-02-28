/// CabEasy - AuthProvider
/// Purpose: Provider for authentication state and user data
/// Author: CabEasy Dev

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class AuthProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  String get userRole => _currentUser?.role ?? 'agent';
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;

  AuthProvider() {
    // Listen to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        await _loadUserData(user.uid);
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserData(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _firestoreService.getCurrentUser();
    } catch (e) {
      debugPrint('Error loading user data: $e');
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _loadUserData(user.uid);
    }
  }

  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }
}