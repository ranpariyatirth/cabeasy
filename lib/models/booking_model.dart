/// CabEasy - BookingModel
/// Purpose: Data model for confirmed bookings
/// 
/// Design decision: BookingModel stores only IDs (requestId, acceptedBidId)
/// rather than embedding full sub-models. This avoids the need for a
/// DocumentSnapshotMock and matches how Firestore actually stores sub-references.
/// Callers that need the full RequestModel or BidModel should fetch them
/// separately via FirestoreService.

import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String requestId;
  final String agentId;
  final String supplierId;
  final String acceptedBidId;  // ID reference only — fetch via FirestoreService
  final String status; // 'confirmed' | 'in_progress' | 'completed' | 'cancelled'
  final DateTime createdAt;

  BookingModel({
    required this.id,
    required this.requestId,
    required this.agentId,
    required this.supplierId,
    required this.acceptedBidId,
    required this.status,
    required this.createdAt,
  });

  /// Deserialises a Firestore document into a BookingModel.
  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
    return BookingModel(
      id: doc.id,
      requestId: (data['requestId'] ?? '').toString(),
      agentId: (data['agentId'] ?? '').toString(),
      supplierId: (data['supplierId'] ?? '').toString(),
      acceptedBidId: (data['acceptedBidId'] ?? '').toString(),
      status: (data['status'] ?? 'confirmed').toString(),
      createdAt: _asDateTime(data['createdAt']),
    );
  }

  /// Serialises to a Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'agentId': agentId,
      'supplierId': supplierId,
      'acceptedBidId': acceptedBidId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static DateTime _asDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.now();
  }
}
