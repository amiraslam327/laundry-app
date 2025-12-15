import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laundry_app/features/common/domain/models/fragrance_model.dart';

class FragrancesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'fragrances';

  Stream<List<FragranceModel>> getAllFragrances() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FragranceModel.fromMap(doc.data()))
            .toList());
  }

  Future<List<FragranceModel>> getAllFragrancesOnce() async {
    final snapshot = await _firestore.collection(_collection).get();
    return snapshot.docs
        .map((doc) => FragranceModel.fromMap(doc.data()))
        .toList();
  }

  Future<FragranceModel?> getFragrance(String fragranceId) async {
    final doc =
        await _firestore.collection(_collection).doc(fragranceId).get();
    if (!doc.exists) return null;
    return FragranceModel.fromMap(doc.data()!);
  }
}

