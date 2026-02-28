/// CabEasy - UserModel
/// Purpose: Data model for user information
/// Author: CabEasy Dev

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String role; // 'agent' | 'supplier'
  final String? companyName;
  final String? profileImageUrl;
  final bool isKycVerified;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.role,
    this.companyName,
    this.profileImageUrl,
    required this.isKycVerified,
    required this.createdAt,
  });

  // Create a UserModel from a Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
    return UserModel(
      uid: (data['uid'] ?? doc.id).toString(),
      name: (data['name'] ?? '').toString(),
      phone: (data['phone'] ?? data['phoneNumber'] ?? '').toString(),
      role: (data['role'] ?? 'agent').toString(),
      companyName: data['companyName'],
      profileImageUrl: data['profileImageUrl'],
      isKycVerified: data['isKycVerified'] == true,
      createdAt: _asDateTime(data['createdAt']),
    );
  }

  // Convert UserModel to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'role': role,
      'companyName': companyName,
      'profileImageUrl': profileImageUrl,
      'isKycVerified': isKycVerified,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create a copy of UserModel with updated values
  UserModel copyWith({
    String? uid,
    String? name,
    String? phone,
    String? role,
    String? companyName,
    String? profileImageUrl,
    bool? isKycVerified,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      companyName: companyName ?? this.companyName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isKycVerified: isKycVerified ?? this.isKycVerified,
      createdAt: createdAt ?? this.createdAt,
    );
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
