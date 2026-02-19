import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import '../services/auth_service.dart';

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          // User is authenticated, check if profile is complete
          return _buildUserProfileCheck(snapshot.data!.uid);
        } else {
          // User is not authenticated
          return LoginScreen();
        }
      },
    );
  }

  Widget _buildUserProfileCheck(String userId) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _authService.getUserData(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          bool isProfileComplete = snapshot.data!['isProfileComplete'] ?? false;

          if (isProfileComplete) {
            // Profile is complete, go to home
            return HomeScreen();
          } else {
            // Profile not complete, go to profile screen
            return ProfileScreen(userId: userId);
          }
        } else {
          // Error or no data, assume new user
          return ProfileScreen(userId: userId);
        }
      },
    );
  }
}
