/// CabEasy - RequestModel
/// Purpose: Data model for transport requests
/// Author: CabEasy Dev

import 'package:cloud_firestore/cloud_firestore.dart';

class RequestModel {
  final String id;
  final String agentId;
  final String agentName;
  final String pickupLocation;
  final String dropLocation;
  final DateTime travelDate;
  final int passengerCount;
  final String vehicleType; // 'sedan' | 'suv' | 'tempo' | 'bus'
  final String? notes;
  final String status; // 'open' | 'bidding' | 'booked' | 'cancelled'
  final String leadLevel; // 'hot' | 'warm' | 'cold' - set by n8n
  final DateTime createdAt;
  final int bidCount;

  RequestModel({
    required this.id,
    required this.agentId,
    required this.agentName,
    required this.pickupLocation,
    required this.dropLocation,
    required this.travelDate,
    required this.passengerCount,
    required this.vehicleType,
    this.notes,
    required this.status,
    required this.leadLevel,
    required this.createdAt,
    required this.bidCount,
  });

  // Create a RequestModel from a Firestore document
  factory RequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
    return RequestModel(
      id: doc.id,
      agentId: (data['agentId'] ?? '').toString(),
      agentName: (data['agentName'] ?? '').toString(),
      pickupLocation: (data['pickupLocation'] ?? '').toString(),
      dropLocation: (data['dropLocation'] ?? '').toString(),
      travelDate: _asDateTime(data['travelDate']),
      passengerCount: _asInt(data['passengerCount'], fallback: 1),
      vehicleType: (data['vehicleType'] ?? 'sedan').toString(),
      notes: data['notes']?.toString(),
      status: (data['status'] ?? 'open').toString(),
      leadLevel: (data['leadLevel'] ?? 'unclassified').toString(),
      createdAt: _asDateTime(data['createdAt']),
      bidCount: _asInt(data['bidCount']),
    );
  }

  // Convert RequestModel to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'agentId': agentId,
      'agentName': agentName,
      'pickupLocation': pickupLocation,
      'dropLocation': dropLocation,
      'travelDate': Timestamp.fromDate(travelDate),
      'passengerCount': passengerCount,
      'vehicleType': vehicleType,
      'notes': notes,
      'status': status,
      'leadLevel': leadLevel,
      'createdAt': Timestamp.fromDate(createdAt),
      'bidCount': bidCount,
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

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
