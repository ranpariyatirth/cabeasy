/// CabEasy - AuthWrapper
/// Purpose: Entry point after Firebase auth — routes to correct screen based on
///          user state (unauthenticated → login, no profile → profile setup,
///          profile complete → role-specific home screen).

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../constants/app_colors.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'kyc_verification_screen.dart';
import 'agent/agent_home_screen.dart';
import 'supplier/supplier_home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.scaffoldBg,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryYellow),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          // User is authenticated — delegate to AuthProvider for user model
          return _AuthedRouter(uid: snapshot.data!.uid);
        } else {
          // Not authenticated
          return LoginScreen();
        }
      },
    );
  }
}

/// Handles routing once we know the user is authenticated.
/// Uses AuthProvider to load the UserModel from the `users` collection.
class _AuthedRouter extends StatefulWidget {
  final String uid;
  const _AuthedRouter({Key? key, required this.uid}) : super(key: key);

  @override
  State<_AuthedRouter> createState() => _AuthedRouterState();
}

class _AuthedRouterState extends State<_AuthedRouter> {
  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider =
          Provider.of<app_auth.AuthProvider>(context, listen: false);
      await authProvider.refreshUserData();
      if (mounted) setState(() => _initialLoadDone = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialLoadDone) {
      return const Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryYellow),
        ),
      );
    }

    final authProvider = Provider.of<app_auth.AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      // Profile not created yet — send to profile setup
      return ProfileScreen(userId: widget.uid);
    }

    // Route by KYC status
    if (!user.isKycVerified) {
      return KycVerificationScreen();
    }

    // Route by role
    if (user.role == 'supplier') {
      return SupplierHomeScreen();
    }
    // Default: agent
    return AgentHomeScreen();
  }
}
