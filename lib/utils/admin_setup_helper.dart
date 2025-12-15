import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laundry_app/features/common/domain/models/user_model.dart';

/// Helper class to create and manage admin users
class AdminSetupHelper {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new admin user with email and password
  Future<String> createAdminUser({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    String? defaultAddress,
  }) async {
    try {
      // 1. Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user!;

      // 2. Create UserModel with admin role
      final userModel = UserModel(
        id: user.uid,
        fullName: fullName,
        phoneNumber: phoneNumber,
        email: email,
        createdAt: DateTime.now(),
        defaultAddress: defaultAddress,
        role: 'admin', // Set as admin
      );

      // 3. Save to Firestore
      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());

      return user.uid;
    } catch (e) {
      throw Exception('Failed to create admin user: $e');
    }
  }

  /// Update existing user to admin role
  Future<void> makeUserAdmin(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': 'admin',
      });
    } catch (e) {
      throw Exception('Failed to set user as admin: $e');
    }
  }

  /// Make current logged-in user admin
  Future<void> makeCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    await makeUserAdmin(user.uid);
  }

  /// Find user by email and make admin
  Future<void> makeUserAdminByEmail(String email) async {
    try {
      final usersSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (usersSnapshot.docs.isEmpty) {
        throw Exception('User not found with email: $email');
      }

      await usersSnapshot.docs.first.reference.update({'role': 'admin'});
    } catch (e) {
      throw Exception('Failed to set user as admin: $e');
    }
  }

  /// Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return false;
      
      final userData = userDoc.data();
      return userData?['role'] == 'admin';
    } catch (e) {
      return false;
    }
  }
}

