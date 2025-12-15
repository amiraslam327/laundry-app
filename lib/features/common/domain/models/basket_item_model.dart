import 'package:equatable/equatable.dart';

class BasketItemModel extends Equatable {
  final String id;
  final String serviceId;
  final String serviceName;
  final String laundryId;
  final String laundryName;
  final double quantity; // in kg
  final double pricePerKg;
  final String? fragranceId;
  final String? notes;
  final int discountPercentage; // Discount from laundry

  const BasketItemModel({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.laundryId,
    required this.laundryName,
    required this.quantity,
    required this.pricePerKg,
    this.fragranceId,
    this.notes,
    this.discountPercentage = 0,
  });

  double get subtotalPrice => quantity * pricePerKg;
  
  double get discountAmount => subtotalPrice * (discountPercentage / 100);
  
  double get totalPrice => subtotalPrice - discountAmount;

  BasketItemModel copyWith({
    String? id,
    String? serviceId,
    String? serviceName,
    String? laundryId,
    String? laundryName,
    double? quantity,
    double? pricePerKg,
    String? fragranceId,
    String? notes,
    int? discountPercentage,
  }) {
    return BasketItemModel(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      laundryId: laundryId ?? this.laundryId,
      laundryName: laundryName ?? this.laundryName,
      quantity: quantity ?? this.quantity,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      fragranceId: fragranceId ?? this.fragranceId,
      notes: notes ?? this.notes,
      discountPercentage: discountPercentage ?? this.discountPercentage,
    );
  }

  @override
  List<Object?> get props => [
        id,
        serviceId,
        serviceName,
        laundryId,
        laundryName,
        quantity,
        pricePerKg,
        fragranceId,
        notes,
        discountPercentage,
      ];
}

