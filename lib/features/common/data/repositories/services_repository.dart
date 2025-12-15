import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laundry_app/features/common/domain/models/service_model.dart';

class ServicesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'services';

  Stream<List<ServiceModel>> getServicesByLaundry(String laundryId) {
    return _firestore
        .collection(_collection)
        .where('laundryId', isEqualTo: laundryId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              data['id'] = doc.id; // Include document ID
              return ServiceModel.fromMap(data);
            })
            .toList());
  }

  Future<List<ServiceModel>> getServicesByLaundryOnce(String laundryId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('laundryId', isEqualTo: laundryId)
        .get();
    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          data['id'] = doc.id; // Include document ID
          return ServiceModel.fromMap(data);
        })
        .toList();
  }

  Future<ServiceModel?> getService(String serviceId) async {
    final doc = await _firestore.collection(_collection).doc(serviceId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    data['id'] = doc.id; // Include document ID
    return ServiceModel.fromMap(data);
  }

  Stream<List<ServiceModel>> getAllServices() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              data['id'] = doc.id; // Include document ID
              return ServiceModel.fromMap(data);
            })
            .toList());
  }
}

