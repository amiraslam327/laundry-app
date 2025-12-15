import 'package:equatable/equatable.dart';

class LaundryModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final String? logoUrl;
  final double rating;
  final bool isPreferred;
  final String address;
  final double minOrderAmount;
  final int discountPercentage;
  final String? bannerImageUrl;

  const LaundryModel({
    required this.id,
    required this.name,
    required this.description,
    this.logoUrl,
    this.rating = 0.0,
    this.isPreferred = false,
    required this.address,
    this.minOrderAmount = 0.0,
    this.discountPercentage = 0,
    this.bannerImageUrl,
  });

  factory LaundryModel.fromMap(Map<String, dynamic> map) {
    return LaundryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      logoUrl: map['logoUrl'] as String?,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      isPreferred: map['isPreferred'] as bool? ?? false,
      address: map['address'] as String,
      minOrderAmount: (map['minOrderAmount'] as num?)?.toDouble() ?? 0.0,
      discountPercentage: (map['discountPercentage'] as int?) ?? 0,
      bannerImageUrl: map['bannerImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'logoUrl': logoUrl,
      'rating': rating,
      'isPreferred': isPreferred,
      'address': address,
      'minOrderAmount': minOrderAmount,
      'discountPercentage': discountPercentage,
      'bannerImageUrl': bannerImageUrl,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        logoUrl,
        rating,
        isPreferred,
        address,
        minOrderAmount,
        discountPercentage,
        bannerImageUrl,
      ];
}

