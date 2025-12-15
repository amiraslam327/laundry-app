import 'dart:convert';
import 'package:equatable/equatable.dart';

class AddressModel extends Equatable {
  final String id;
  final String userId;
  final String label; // 'Home', 'Office', 'Rent', etc.
  final String name; // Full name for delivery
  final String phoneNumber; // Phone number for delivery
  final String address;
  final double? lat;
  final double? lng;
  final bool isDefault;
  final DateTime createdAt;

  const AddressModel({
    required this.id,
    required this.userId,
    required this.label,
    required this.name,
    required this.phoneNumber,
    required this.address,
    this.lat,
    this.lng,
    this.isDefault = false,
    required this.createdAt,
  });

  factory AddressModel.fromMap(Map<String, dynamic> map) {
    // Handle both Firestore Timestamp and ISO string dates
    DateTime createdAt;
    if (map['createdAt'] is String) {
      createdAt = DateTime.parse(map['createdAt'] as String);
    } else if (map['createdAt'] != null) {
      // Firestore Timestamp (for backward compatibility)
      try {
        createdAt = (map['createdAt'] as dynamic).toDate();
      } catch (e) {
        createdAt = DateTime.now();
      }
    } else {
      createdAt = DateTime.now();
    }

    return AddressModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      label: map['label'] as String,
      name: map['name'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      address: map['address'] as String,
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      isDefault: map['isDefault'] as bool? ?? false,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'label': label,
      'name': name,
      'phoneNumber': phoneNumber,
      'address': address,
      'lat': lat,
      'lng': lng,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(), // Store as ISO string for local storage
    };
  }
  
  // JSON serialization for local storage
  String toJson() {
    return jsonEncode(toMap());
  }
  
  factory AddressModel.fromJson(String json) {
    return AddressModel.fromMap(jsonDecode(json));
  }

  AddressModel copyWith({
    String? id,
    String? userId,
    String? label,
    String? name,
    String? phoneNumber,
    String? address,
    double? lat,
    double? lng,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return AddressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      label: label ?? this.label,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, label, name, phoneNumber, address, lat, lng, isDefault, createdAt];
}

