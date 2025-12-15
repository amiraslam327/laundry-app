import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String email;
  final DateTime createdAt;
  final String? defaultAddress;
  final String role; // 'customer', 'admin', 'driver'

  const UserModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.createdAt,
    this.defaultAddress,
    this.role = 'customer',
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      fullName: map['fullName'] as String,
      phoneNumber: map['phoneNumber'] as String,
      email: map['email'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      defaultAddress: map['defaultAddress'] as String?,
      role: map['role'] as String? ?? 'customer',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
      'defaultAddress': defaultAddress,
      'role': role,
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? phoneNumber,
    String? email,
    DateTime? createdAt,
    String? defaultAddress,
    String? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      defaultAddress: defaultAddress ?? this.defaultAddress,
      role: role ?? this.role,
    );
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        phoneNumber,
        email,
        createdAt,
        defaultAddress,
        role,
      ];
}

