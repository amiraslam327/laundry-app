import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class OrderItem {
  final String serviceId;
  final String serviceName;
  final String? itemName; // Item name (e.g., "Kurta", "Shirt")
  final double quantity; // in kg
  final double price;

  const OrderItem({
    required this.serviceId,
    required this.serviceName,
    this.itemName,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      serviceId: map['serviceId'] as String,
      serviceName: map['serviceName'] as String,
      itemName: map['itemName'] as String?,
      quantity: (map['quantity'] as num).toDouble(),
      price: (map['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'serviceId': serviceId,
      'serviceName': serviceName,
      'itemName': itemName,
      'quantity': quantity,
      'price': price,
    };
  }
}

enum OrderStatus {
  pending,
  accepted,
  processing,
  readyForPickup,
  outForDelivery,
  delivered,
  cancelled,
}

extension OrderStatusExtension on OrderStatus {
  String get value {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.accepted:
        return 'accepted';
      case OrderStatus.processing:
        return 'processing';
      case OrderStatus.readyForPickup:
        return 'ready_for_pickup';
      case OrderStatus.outForDelivery:
        return 'out_for_delivery';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  static OrderStatus fromString(String value) {
    final normalized = value.toLowerCase().trim();
    switch (value) {
      case 'pending':
        return OrderStatus.pending;
      case 'accepted':
        return OrderStatus.accepted;
      case 'processing':
        return OrderStatus.processing;
      case 'ready_for_pickup':
      case 'ready for pickup':
      case 'readyforpickup':
        return OrderStatus.readyForPickup;
      case 'out_for_delivery':
      case 'out for delivery':
      case 'outfordelivery':
        return OrderStatus.outForDelivery;
      case 'delivered':
      case 'complete': // normalize legacy/alternative status to delivered
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        // Also handle when value case/spaces differ
        switch (normalized) {
          case 'pending':
            return OrderStatus.pending;
          case 'accepted':
            return OrderStatus.accepted;
          case 'processing':
            return OrderStatus.processing;
          case 'ready for pickup':
          case 'ready_for_pickup':
          case 'readyforpickup':
            return OrderStatus.readyForPickup;
          case 'out for delivery':
          case 'out_for_delivery':
          case 'outfordelivery':
            return OrderStatus.outForDelivery;
          case 'delivered':
          case 'complete':
            return OrderStatus.delivered;
          case 'cancelled':
            return OrderStatus.cancelled;
          default:
            return OrderStatus.pending;
        }
    }
  }

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.readyForPickup:
        return 'Ready for Pickup';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class OrderModel extends Equatable {
  final String id;
  final String userId;
  final String laundryId;
  final OrderStatus status;
  final List<OrderItem> items;
  final String? fragranceId; // Keep for backward compatibility
  final String? fragranceName; // Fragrance name instead of ID
  final String? userName; // User's full name
  final String? userPhoneNumber; // User's phone number
  final double? discountPercentage; // Applied discount percent
  final double? discountAmount; // Absolute discount applied
  final DateTime pickupTime;
  final DateTime deliveryTime;
  final double totalPrice;
  final DateTime createdAt;
  final String? notes;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.laundryId,
    required this.status,
    required this.items,
    this.fragranceId,
    this.fragranceName,
    this.userName,
    this.userPhoneNumber,
    this.discountPercentage,
    this.discountAmount,
    required this.pickupTime,
    required this.deliveryTime,
    required this.totalPrice,
    required this.createdAt,
    this.notes,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      laundryId: map['laundryId'] as String,
      status: OrderStatusExtension.fromString(map['status'] as String),
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      fragranceId: map['fragranceId'] as String?,
      fragranceName: map['fragranceName'] as String?,
      userName: map['userName'] as String?,
      userPhoneNumber: map['userPhoneNumber'] as String?,
      discountPercentage: (map['discountPercentage'] as num?)?.toDouble(),
      discountAmount: (map['discountAmount'] as num?)?.toDouble(),
      pickupTime: (map['pickupTime'] as Timestamp).toDate(),
      deliveryTime: (map['deliveryTime'] as Timestamp).toDate(),
      totalPrice: (map['totalPrice'] as num).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'id': id,
      'userId': userId,
      'laundryId': laundryId,
      'status': status.value,
      'items': items.map((item) => item.toMap()).toList(),
      'fragranceId': fragranceId,
      'fragranceName': fragranceName,
      'userName': userName,
      'userPhoneNumber': userPhoneNumber,
      'discountPercentage': discountPercentage,
      'discountAmount': discountAmount,
      'pickupTime': Timestamp.fromDate(pickupTime),
      'deliveryTime': Timestamp.fromDate(deliveryTime),
      'totalPrice': totalPrice,
      'createdAt': Timestamp.fromDate(createdAt),
      'notes': notes,
    };
    // Add payment fields if they exist (optional fields)
    return map;
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        laundryId,
        status,
        items,
        fragranceId,
        fragranceName,
        userName,
        userPhoneNumber,
      discountPercentage,
      discountAmount,
        pickupTime,
        deliveryTime,
        totalPrice,
        createdAt,
        notes,
      ];
}

