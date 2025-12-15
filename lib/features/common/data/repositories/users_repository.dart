import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laundry_app/features/common/domain/models/user_model.dart';

class UsersRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  Future<void> createUser(UserModel user) async {
    await _firestore.collection(_collection).doc(user.id).set(user.toMap());
  }

  Future<UserModel?> getUser(String userId) async {
    final doc = await _firestore.collection(_collection).doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  Stream<UserModel> getUserStream(String userId) {
    return _firestore
        .collection(_collection)
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            throw Exception('User not found');
          }
          return UserModel.fromMap(doc.data()!);
        });
  }

  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    await _firestore.collection(_collection).doc(userId).update(updates);
  }

  Future<void> updateUserModel(UserModel user) async {
    await _firestore.collection(_collection).doc(user.id).update(user.toMap());
  }

  Future<void> deleteUser(String userId) async {
    await _firestore.collection(_collection).doc(userId).delete();
  }
}

