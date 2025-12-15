import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laundry_app/features/common/domain/models/basket_item_model.dart';

class CartRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'carts';
  final String _itemsSubcollection = 'items';

  /// Stream of cart items for a user
  Stream<List<BasketItemModel>> getCartItems(String userId) {
    return _firestore
        .collection(_collection)
        .doc(userId)
        .collection(_itemsSubcollection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return BasketItemModel(
                id: data['id'] as String,
                serviceId: data['serviceId'] as String,
                serviceName: data['serviceName'] as String,
                laundryId: data['laundryId'] as String,
                laundryName: data['laundryName'] as String,
                quantity: (data['quantity'] as num).toDouble(),
                pricePerKg: (data['pricePerKg'] as num).toDouble(),
                fragranceId: data['fragranceId'] as String?,
                notes: data['notes'] as String?,
                discountPercentage: (data['discountPercentage'] as int?) ?? 0,
              );
            })
            .toList());
  }

  /// Find existing cart item by serviceId and item name (notes)
  Future<BasketItemModel?> findExistingItem(
    String userId,
    String serviceId,
    String? itemName,
  ) async {
    try {
      final itemsSnapshot = await _firestore
          .collection(_collection)
          .doc(userId)
          .collection(_itemsSubcollection)
          .where('serviceId', isEqualTo: serviceId)
          .where('notes', isEqualTo: itemName)
          .get();

      if (itemsSnapshot.docs.isEmpty) {
        return null;
      }

      final doc = itemsSnapshot.docs.first;
      final data = doc.data();
      data['id'] = doc.id;
      return BasketItemModel(
        id: data['id'] as String,
        serviceId: data['serviceId'] as String,
        serviceName: data['serviceName'] as String,
        laundryId: data['laundryId'] as String,
        laundryName: data['laundryName'] as String,
        quantity: (data['quantity'] as num).toDouble(),
        pricePerKg: (data['pricePerKg'] as num).toDouble(),
        fragranceId: data['fragranceId'] as String?,
        notes: data['notes'] as String?,
        discountPercentage: (data['discountPercentage'] as int?) ?? 0,
      );
    } catch (e) {
      return null;
    }
  }

  /// Add item to cart or update quantity if item already exists
  Future<void> addItemToCart(String userId, BasketItemModel item) async {
    // Check if item already exists (same serviceId and item name)
    final existingItem = await findExistingItem(
      userId,
      item.serviceId,
      item.notes,
    );

    if (existingItem != null) {
      // Item exists, update quantity
      final newQuantity = existingItem.quantity + item.quantity;
      await updateQuantity(userId, existingItem.id, newQuantity);
    } else {
      // New item, add to cart
      await _firestore
          .collection(_collection)
          .doc(userId)
          .collection(_itemsSubcollection)
          .doc(item.id)
          .set({
        'serviceId': item.serviceId,
        'serviceName': item.serviceName,
        'laundryId': item.laundryId,
        'laundryName': item.laundryName,
        'quantity': item.quantity,
        'pricePerKg': item.pricePerKg,
        'fragranceId': item.fragranceId,
        'notes': item.notes,
        'discountPercentage': item.discountPercentage,
      });
    }
  }

  /// Update quantity of an item
  Future<void> updateQuantity(String userId, String itemId, double quantity) async {
    await _firestore
        .collection(_collection)
        .doc(userId)
        .collection(_itemsSubcollection)
        .doc(itemId)
        .update({'quantity': quantity});
  }

  /// Update fragrance of an item
  Future<void> updateFragrance(String userId, String itemId, String fragranceId) async {
    await _firestore
        .collection(_collection)
        .doc(userId)
        .collection(_itemsSubcollection)
        .doc(itemId)
        .update({'fragranceId': fragranceId});
  }

  /// Update discount of an item
  Future<void> updateDiscount(String userId, String itemId, int discountPercentage) async {
    await _firestore
        .collection(_collection)
        .doc(userId)
        .collection(_itemsSubcollection)
        .doc(itemId)
        .update({'discountPercentage': discountPercentage});
  }

  /// Update discount for all items in cart
  Future<void> updateDiscountForAllItems(String userId, int discountPercentage) async {
    final itemsSnapshot = await _firestore
        .collection(_collection)
        .doc(userId)
        .collection(_itemsSubcollection)
        .get();

    final batch = _firestore.batch();
    for (final doc in itemsSnapshot.docs) {
      batch.update(doc.reference, {'discountPercentage': discountPercentage});
    }
    await batch.commit();
  }

  /// Remove item from cart
  Future<void> removeItem(String userId, String itemId) async {
    await _firestore
        .collection(_collection)
        .doc(userId)
        .collection(_itemsSubcollection)
        .doc(itemId)
        .delete();
  }

  /// Clear entire cart
  Future<void> clearCart(String userId) async {
    final itemsSnapshot = await _firestore
        .collection(_collection)
        .doc(userId)
        .collection(_itemsSubcollection)
        .get();

    final batch = _firestore.batch();
    for (final doc in itemsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

