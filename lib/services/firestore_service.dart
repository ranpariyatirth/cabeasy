/// CabEasy - FirestoreService
/// Purpose: Handle all Firestore CRUD operations
/// Author: CabEasy Dev

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/request_model.dart';
import '../models/bid_model.dart';
import '../models/booking_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // User operations
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      return UserModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toMap());
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update(user.toMap());
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    }
  }

  // Request operations
  Stream<List<RequestModel>> getOpenRequestsStream() {
    try {
      return _firestore
          .collection('requests')
          .where('status', isEqualTo: 'open')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => RequestModel.fromFirestore(doc)).toList());
    } catch (e) {
      debugPrint('Error getting open requests stream: $e');
      return Stream.value([]);
    }
  }

  Stream<List<RequestModel>> getFilteredRequestsStream(String leadLevel) {
    try {
      return _firestore
          .collection('requests')
          .where('status', isEqualTo: 'open')
          .where('leadLevel', isEqualTo: leadLevel)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => RequestModel.fromFirestore(doc)).toList());
    } catch (e) {
      debugPrint('Error getting filtered requests stream: $e');
      return Stream.value([]);
    }
  }

  Future<void> createRequest(RequestModel request) async {
    try {
      await _firestore.collection('requests').doc(request.id).set(request.toMap());
    } catch (e) {
      debugPrint('Error creating request: $e');
      rethrow;
    }
  }

  Future<void> updateRequest(RequestModel request) async {
    try {
      await _firestore.collection('requests').doc(request.id).update(request.toMap());
    } catch (e) {
      debugPrint('Error updating request: $e');
      rethrow;
    }
  }

  Future<RequestModel?> getRequestById(String requestId) async {
    try {
      final doc = await _firestore.collection('requests').doc(requestId).get();
      if (!doc.exists) return null;
      return RequestModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting request by id: $e');
      return null;
    }
  }

  // Bid operations
  Stream<List<BidModel>> getBidsForRequestStream(String requestId) {
    try {
      return _firestore
          .collection('requests')
          .doc(requestId)
          .collection('bids')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => BidModel.fromFirestore(doc)).toList());
    } catch (e) {
      debugPrint('Error getting bids for request stream: $e');
      return Stream.value([]);
    }
  }

  Future<void> createBid(BidModel bid) async {
    try {
      final batch = _firestore.batch();

      // Create the bid
      final bidDoc = _firestore
          .collection('requests')
          .doc(bid.requestId)
          .collection('bids')
          .doc(bid.id);
      batch.set(bidDoc, bid.toMap());

      // Update bid count on request
      final requestDoc = _firestore.collection('requests').doc(bid.requestId);
      batch.update(requestDoc, {
        'bidCount': FieldValue.increment(1),
      });

      await batch.commit();
    } catch (e) {
      debugPrint('Error creating bid: $e');
      rethrow;
    }
  }

  Future<BidModel?> getBidById(String requestId, String bidId) async {
    try {
      final doc = await _firestore
          .collection('requests')
          .doc(requestId)
          .collection('bids')
          .doc(bidId)
          .get();
      if (!doc.exists) return null;
      return BidModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting bid by id: $e');
      return null;
    }
  }

  Future<bool> hasUserBidOnRequest(String requestId, String supplierId) async {
    try {
      final snapshot = await _firestore
          .collection('requests')
          .doc(requestId)
          .collection('bids')
          .where('supplierId', isEqualTo: supplierId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking if user has bid on request: $e');
      return false;
    }
  }

  // Booking operations
  Future<void> createBooking(BookingModel booking) async {
    try {
      await _firestore.collection('bookings').doc(booking.id).set(booking.toMap());

      // Update request status to booked
      await _firestore.collection('requests').doc(booking.requestId).update({
        'status': 'booked',
      });
    } catch (e) {
      debugPrint('Error creating booking: $e');
      rethrow;
    }
  }

  Stream<List<BookingModel>> getUserBookingsStream(String userId) {
    try {
      return _firestore
          .collection('bookings')
          .where('agentId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList());
    } catch (e) {
      debugPrint('Error getting user bookings stream: $e');
      return Stream.value([]);
    }
  }
}