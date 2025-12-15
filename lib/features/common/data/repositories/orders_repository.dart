import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laundry_app/features/common/domain/models/order_model.dart';
import 'package:laundry_app/features/common/data/repositories/cart_repository.dart';
import 'package:async/async.dart';

class OrdersRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'orders';
  final CartRepository _cartRepository = CartRepository();

  Future<String> createOrder(OrderModel order) async {
    final orderMap = order.toMap();
    orderMap['id'] = order.id; // Ensure ID is set
    // Add payment fields if needed (handled in repository layer)
    final docRef = _firestore.collection(_collection).doc(order.id);
    await docRef.set(orderMap);
    return order.id;
  }

  /// Place order: Create order, copy cart items, optionally clear cart
  Future<String> placeOrder({
    required OrderModel order,
    required String userId,
    String paymentMethod = 'cod',
    String paymentStatus = 'pending',
    bool clearCartAfterOrder = true, // Default to true for backward compatibility
  }) async {
    // Get cart items
    final cartItems = await _cartRepository
        .getCartItems(userId)
        .first
        .timeout(const Duration(seconds: 5));

    // Convert cart items to order items
    final orderItems = cartItems.map((item) {
      return OrderItem(
        serviceId: item.serviceId,
        serviceName: item.serviceName,
        itemName: item.notes, // Save item name from notes field
        quantity: item.quantity,
        price: item.totalPrice,
      );
    }).toList();

    // Create order with cart items
    final orderWithItems = OrderModel(
      id: order.id,
      userId: order.userId,
      laundryId: order.laundryId,
      status: OrderStatus.pending,
      items: orderItems,
      fragranceId: order.fragranceId,
      fragranceName: order.fragranceName, // Include fragrance name
      userName: order.userName, // Include user name
      userPhoneNumber: order.userPhoneNumber, // Include user phone number
      discountPercentage: order.discountPercentage,
      discountAmount: order.discountAmount,
      pickupTime: order.pickupTime,
      deliveryTime: order.deliveryTime,
      totalPrice: order.totalPrice,
      createdAt: DateTime.now(),
      notes: order.notes,
    );

    // Save order with payment info
    final orderMap = orderWithItems.toMap();
    orderMap['id'] = orderWithItems.id;
    orderMap['paymentMethod'] = paymentMethod;
    orderMap['paymentStatus'] = paymentStatus;

    // Save pending orders to orders/pending/{orderId}
    final docRef = _firestore
        .collection(_collection)
        .doc('pending')
        .collection('pending')
        .doc(orderWithItems.id);
    await docRef.set(orderMap);

    // Clear cart only if requested (default is true for backward compatibility)
    if (clearCartAfterOrder) {
      await _cartRepository.clearCart(userId);
    }

    return orderWithItems.id;
  }

  Stream<List<OrderModel>> getUserOrders(String userId) {
    // Query main + subcollections (pending, cancel, complete)
    final mainOrdersStream = _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromMap(doc.data()))
            .toList());

    final pendingOrdersStream = _firestore
        .collection(_collection)
        .doc('pending')
        .collection('pending')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromMap(doc.data()))
            .toList());

    final cancelledOrdersStream = _firestore
        .collection(_collection)
        .doc('cancel')
        .collection('cancel')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromMap(doc.data()))
            .toList());

    final completedOrdersStream = _firestore
        .collection(_collection)
        .doc('complete')
        .collection('complete')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromMap(doc.data()))
            .toList());

    // Combine all streams and sort in memory
    return StreamZip([
      mainOrdersStream,
      pendingOrdersStream,
      cancelledOrdersStream,
      completedOrdersStream,
    ]).map((lists) {
      final allOrders = <OrderModel>[];
      allOrders.addAll(lists[0]);
      allOrders.addAll(lists[1]);
      allOrders.addAll(lists[2]);
      allOrders.addAll(lists[3]);
      allOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return allOrders;
    });
  }

  Future<List<OrderModel>> getUserOrdersOnce(String userId) async {
    // Get orders from main collection
    final mainSnapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    // Get orders from pending subcollection
    // Removed orderBy to avoid index requirement - will sort in memory
    final pendingSnapshot = await _firestore
        .collection(_collection)
        .doc('pending')
        .collection('pending')
        .where('userId', isEqualTo: userId)
        .get();

    // Get orders from cancelled subcollection
    // Removed orderBy to avoid index requirement - will sort in memory
    final cancelledSnapshot = await _firestore
        .collection(_collection)
        .doc('cancel')
        .collection('cancel')
        .where('userId', isEqualTo: userId)
        .get();

    // Get orders from completed subcollection
    final completedSnapshot = await _firestore
        .collection(_collection)
        .doc('complete')
        .collection('complete')
        .where('userId', isEqualTo: userId)
        .get();

    final allOrders = <OrderModel>[];
    allOrders.addAll(mainSnapshot.docs.map((doc) => OrderModel.fromMap(doc.data())));
    allOrders.addAll(pendingSnapshot.docs.map((doc) => OrderModel.fromMap(doc.data())));
    allOrders.addAll(cancelledSnapshot.docs.map((doc) => OrderModel.fromMap(doc.data())));
    allOrders.addAll(completedSnapshot.docs.map((doc) => OrderModel.fromMap(doc.data())));
    
    // Sort by createdAt descending
    allOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return allOrders;
  }

  Stream<List<OrderModel>> getUserOrdersByStatus(
    String userId,
    OrderStatus status,
  ) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: status.value)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromMap(doc.data()))
            .toList());
  }

  Future<OrderModel?> getOrder(String orderId) async {
    // Check pending orders first
    final pendingDoc = await _firestore
        .collection(_collection)
        .doc('pending')
        .collection('pending')
        .doc(orderId)
        .get();
    if (pendingDoc.exists) {
      return OrderModel.fromMap(pendingDoc.data()!);
    }

    // Check cancelled orders
    final cancelledDoc = await _firestore
        .collection(_collection)
        .doc('cancel')
        .collection('cancel')
        .doc(orderId)
        .get();
    if (cancelledDoc.exists) {
      return OrderModel.fromMap(cancelledDoc.data()!);
    }

    // Check completed orders
    final completedDoc = await _firestore
        .collection(_collection)
        .doc('complete')
        .collection('complete')
        .doc(orderId)
        .get();
    if (completedDoc.exists) {
      return OrderModel.fromMap(completedDoc.data()!);
    }

    // Then check main orders collection
    final doc = await _firestore.collection(_collection).doc(orderId).get();
    if (!doc.exists) return null;
    return OrderModel.fromMap(doc.data()!);
  }

  Stream<OrderModel?> getOrderStream(String orderId) {
    // Check pending, cancelled, completed, and main collection
    final pendingStream = _firestore
        .collection(_collection)
        .doc('pending')
        .collection('pending')
        .doc(orderId)
        .snapshots()
        .map((doc) => doc.exists ? OrderModel.fromMap(doc.data()!) : null);

    final cancelledStream = _firestore
        .collection(_collection)
        .doc('cancel')
        .collection('cancel')
        .doc(orderId)
        .snapshots()
        .map((doc) => doc.exists ? OrderModel.fromMap(doc.data()!) : null);

    final completedStream = _firestore
        .collection(_collection)
        .doc('complete')
        .collection('complete')
        .doc(orderId)
        .snapshots()
        .map((doc) => doc.exists ? OrderModel.fromMap(doc.data()!) : null);

    final mainStream = _firestore
        .collection(_collection)
        .doc(orderId)
        .snapshots()
        .map((doc) => doc.exists ? OrderModel.fromMap(doc.data()!) : null);

    // Combine streams - return first non-null value
    return StreamZip([pendingStream, cancelledStream, completedStream, mainStream]).map((values) {
      return values[0] ?? values[1] ?? values[2] ?? values[3];
    });
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    // Check if order is in pending subcollection
    final pendingRef = _firestore
        .collection(_collection)
        .doc('pending')
        .collection('pending')
        .doc(orderId);
    
    final pendingDoc = await pendingRef.get();
    
    if (pendingDoc.exists) {
      // If status is no longer pending, move appropriately
      if (status != OrderStatus.pending.value) {
        final orderData = pendingDoc.data()!;
        orderData['status'] = status;

        if (status == OrderStatus.delivered.value) {
          // Move to completed subcollection
          final completeRef = _firestore
              .collection(_collection)
              .doc('complete')
              .collection('complete')
              .doc(orderId);
          await completeRef.set(orderData);
          await pendingRef.delete();
        } else if (status == OrderStatus.cancelled.value) {
          // Move to cancel subcollection
          final cancelRef = _firestore
              .collection(_collection)
              .doc('cancel')
              .collection('cancel')
              .doc(orderId);
          await cancelRef.set(orderData);
          await pendingRef.delete();
        } else {
          // Save to main collection
          await _firestore.collection(_collection).doc(orderId).set(orderData);
          await pendingRef.delete();
        }
      } else {
        // Just update status in pending
        await pendingRef.update({'status': status});
      }
    } else {
      // Order is in main collection, just update or move
      final mainRef = _firestore.collection(_collection).doc(orderId);
      final mainDoc = await mainRef.get();

      if (mainDoc.exists) {
        if (status == OrderStatus.delivered.value) {
          final orderData = mainDoc.data()!;
          orderData['status'] = status;
          final completeRef = _firestore
              .collection(_collection)
              .doc('complete')
              .collection('complete')
              .doc(orderId);
          await completeRef.set(orderData);
          await mainRef.delete();
        } else if (status == OrderStatus.cancelled.value) {
          final orderData = mainDoc.data()!;
          orderData['status'] = status;
          final cancelRef = _firestore
              .collection(_collection)
              .doc('cancel')
              .collection('cancel')
              .doc(orderId);
          await cancelRef.set(orderData);
          await mainRef.delete();
        } else {
          await mainRef.update({'status': status});
        }
      }
    }
  }

  Future<void> cancelOrder(String orderId) async {
    // Check if order is in pending subcollection
    final pendingRef = _firestore
        .collection(_collection)
        .doc('pending')
        .collection('pending')
        .doc(orderId);
    
    final pendingDoc = await pendingRef.get();
    
    if (pendingDoc.exists) {
      // Get order data and update status
      final orderData = pendingDoc.data()!;
      orderData['status'] = OrderStatus.cancelled.value;
      
      // Save to cancel subcollection
      final cancelRef = _firestore
          .collection(_collection)
          .doc('cancel')
          .collection('cancel')
          .doc(orderId);
      await cancelRef.set(orderData);
      
      // Remove from pending
      await pendingRef.delete();
    } else {
      // Order is in main collection
      final mainRef = _firestore.collection(_collection).doc(orderId);
      final mainDoc = await mainRef.get();
      
      if (mainDoc.exists) {
        // Get order data and update status
        final orderData = mainDoc.data()!;
        orderData['status'] = OrderStatus.cancelled.value;
        
        // Save to cancel subcollection
        final cancelRef = _firestore
            .collection(_collection)
            .doc('cancel')
            .collection('cancel')
            .doc(orderId);
        await cancelRef.set(orderData);
        
        // Remove from main collection
        await mainRef.delete();
      }
    }
  }

  Stream<OrderModel> getOrderDetails(String orderId) {
    // Check pending, cancelled, completed, and main collection
    final pendingRef = _firestore
        .collection(_collection)
        .doc('pending')
        .collection('pending')
        .doc(orderId);
    
    final cancelledRef = _firestore
        .collection(_collection)
        .doc('cancel')
        .collection('cancel')
        .doc(orderId);
    
    final completedRef = _firestore
        .collection(_collection)
        .doc('complete')
        .collection('complete')
        .doc(orderId);
    
    final mainRef = _firestore.collection(_collection).doc(orderId);
    
    // Listen to all four and return the first one that exists
    return StreamZip([
      pendingRef.snapshots(),
      cancelledRef.snapshots(),
      completedRef.snapshots(),
      mainRef.snapshots(),
    ]).map((snapshots) {
      final pendingDoc = snapshots[0];
      final cancelledDoc = snapshots[1];
      final completedDoc = snapshots[2];
      final mainDoc = snapshots[3];
      
      if (pendingDoc.exists) {
        return OrderModel.fromMap(pendingDoc.data()!);
      }
      if (cancelledDoc.exists) {
        return OrderModel.fromMap(cancelledDoc.data()!);
      }
      if (completedDoc.exists) {
        return OrderModel.fromMap(completedDoc.data()!);
      }
      if (mainDoc.exists) {
        return OrderModel.fromMap(mainDoc.data()!);
      }
      throw Exception('Order not found');
    });
  }
}

