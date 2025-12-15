import 'package:equatable/equatable.dart';

class ServiceModel extends Equatable {
  final String id;
  final String laundryId;
  final String name;
  final String description;
  final double pricePerKg;
  final int estimatedHours;
  final bool isPopular;

  const ServiceModel({
    required this.id,
    required this.laundryId,
    required this.name,
    required this.description,
    required this.pricePerKg,
    required this.estimatedHours,
    this.isPopular = false,
  });

  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      id: map['id'] as String,
      laundryId: map['laundryId'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      pricePerKg: (map['pricePerKg'] as num).toDouble(),
      estimatedHours: map['estimatedHours'] as int,
      isPopular: map['isPopular'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'laundryId': laundryId,
      'name': name,
      'description': description,
      'pricePerKg': pricePerKg,
      'estimatedHours': estimatedHours,
      'isPopular': isPopular,
    };
  }

  @override
  List<Object?> get props => [
        id,
        laundryId,
        name,
        description,
        pricePerKg,
        estimatedHours,
        isPopular,
      ];
}

