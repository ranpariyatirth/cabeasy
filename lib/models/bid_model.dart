/// CabEasy - BidModel
/// Purpose: Data model for supplier bids on requests
/// Author: CabEasy Dev

import 'package:cloud_firestore/cloud_firestore.dart';

class BidModel {
  final String id;
  final String requestId;
  final String supplierId;
  final String supplierName;
  final String? supplierPhone;
  final double amount;
  final String vehicleType;
  final String vehicleNumber;
  final String? driverName;
  final String note;
  final String status; // 'pending' | 'accepted' | 'rejected'
  final DateTime createdAt;

  BidModel({
    required this.id,
    required this.requestId,
    required this.supplierId,
    required this.supplierName,
    this.supplierPhone,
    required this.amount,
    required this.vehicleType,
    required this.vehicleNumber,
    this.driverName,
    required this.note,
    required this.status,
    required this.createdAt,
  });

  // Create a BidModel from a Firestore document
  factory BidModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
    return BidModel(
      id: doc.id,
      requestId: (data['requestId'] ?? '').toString(),
      supplierId: (data['supplierId'] ?? '').toString(),
      supplierName: (data['supplierName'] ?? '').toString(),
      supplierPhone: data['supplierPhone']?.toString(),
      amount: _asDouble(data['amount']),
      vehicleType: (data['vehicleType'] ?? 'sedan').toString(),
      vehicleNumber: (data['vehicleNumber'] ?? '').toString(),
      driverName: data['driverName']?.toString(),
      note: (data['note'] ?? '').toString(),
      status: (data['status'] ?? 'pending').toString(),
      createdAt: _asDateTime(data['createdAt']),
    );
  }

  // Convert BidModel to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'supplierPhone': supplierPhone,
      'amount': amount,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'driverName': driverName,
      'note': note,
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

  static double _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}
