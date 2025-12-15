import 'package:equatable/equatable.dart';

class SqliteAddressModel extends Equatable {
  final String id;
  final String title;
  final String fullAddress;
  final double? lat;
  final double? lng;
  final DateTime createdAt;

  const SqliteAddressModel({
    required this.id,
    required this.title,
    required this.fullAddress,
    this.lat,
    this.lng,
    required this.createdAt,
  });

  factory SqliteAddressModel.fromMap(Map<String, dynamic> map) {
    return SqliteAddressModel(
      id: map['id'] as String,
      title: map['title'] as String,
      fullAddress: map['fullAddress'] as String,
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'fullAddress': fullAddress,
      'lat': lat,
      'lng': lng,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  SqliteAddressModel copyWith({
    String? id,
    String? title,
    String? fullAddress,
    double? lat,
    double? lng,
    DateTime? createdAt,
  }) {
    return SqliteAddressModel(
      id: id ?? this.id,
      title: title ?? this.title,
      fullAddress: fullAddress ?? this.fullAddress,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, title, fullAddress, lat, lng, createdAt];
}

