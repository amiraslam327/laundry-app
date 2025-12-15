import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laundry_app/features/common/domain/models/service_category.dart';
import 'package:laundry_app/features/common/domain/models/service_item.dart';

class ServiceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _categoriesCollection = 'serviceCategories';
  final String _itemsSubcollection = 'items';

  /// Stream of all service categories
  Stream<List<ServiceCategory>> getCategories() {
    return _firestore
        .collection(_categoriesCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return ServiceCategory.fromMap(data);
            })
            .toList());
  }

  /// Stream of items for a specific category
  Stream<List<ServiceItem>> getItems(String categoryId) {
    return _firestore
        .collection(_categoriesCollection)
        .doc(categoryId)
        .collection(_itemsSubcollection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return ServiceItem.fromMap(data);
            })
            .toList());
  }
}

