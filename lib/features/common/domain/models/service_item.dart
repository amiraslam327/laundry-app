import 'package:equatable/equatable.dart';

class ServiceItem extends Equatable {
  final String id;
  final String name;
  final double price; // SAR per piece
  final int min;
  final int max;

  const ServiceItem({
    required this.id,
    required this.name,
    required this.price,
    required this.min,
    required this.max,
  });

  factory ServiceItem.fromMap(Map<String, dynamic> map) {
    return ServiceItem(
      id: (map['id'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      price: ((map['price'] ?? 0) as num).toDouble(),
      min: (map['min'] ?? 0) as int,
      max: (map['max'] ?? 50) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'min': min,
      'max': max,
    };
  }

  @override
  List<Object?> get props => [id, name, price, min, max];
}

