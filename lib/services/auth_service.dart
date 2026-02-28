import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if user exists in Firestore and get user data
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  // Check if user is new (first time login)
  Future<bool> isNewUser(String uid) async {
    try {
      final userData = await getUserData(uid);
      return userData == null; // If no data, user is new
    } catch (e) {
      debugPrint('Error checking if user is new: $e');
      return true; // Assume new user if error
    }
  }

  // Phone Authentication - Send SMS
  Future<void> sendVerificationCode(
    String phoneNumber,
    Function(String verificationId) onCodeSent,
    Function(FirebaseAuthException) onVerificationFailed,
  ) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          final userCredential = await _auth.signInWithCredential(credential);
          final user = userCredential.user;
          if (user != null) {
            await _createUserDocument(user);
          }
        },
        verificationFailed: onVerificationFailed,
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      debugPrint('Error sending verification code: $e');
      onVerificationFailed(
        FirebaseAuthException(
          code: 'send-verification-failed',
          message: 'Failed to send verification code. Please try again.',
        ),
      );
    }
  }

  // Verify SMS Code and Sign In
  Future<User?> verifyAndSignIn(String verificationId, String smsCode) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      if (userCredential.user != null) {
        await _createUserDocument(userCredential.user!);
      }

      return userCredential.user;
    } catch (e) {
      debugPrint('Error verifying code: $e');
      return null;
    }
  }

  // Create user document in Firestore (only for new users)
  Future<void> _createUserDocument(User user) async {
    try {
      final userExists = await getUserData(user.uid);
      if (userExists == null) {
        // Only create if user doesn't exist
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': '',
          'phone': user.phoneNumber,
          'phoneNumber': user.phoneNumber,
          'role': 'agent',
          'isKycVerified': false,
          'isProfileComplete': false, // New field to track profile completion
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
      } else {
        // Update last login time for existing users
        await _firestore.collection('users').doc(user.uid).set({
          'phone': user.phoneNumber,
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error creating/updating user document: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
