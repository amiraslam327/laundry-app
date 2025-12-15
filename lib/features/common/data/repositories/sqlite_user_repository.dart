import 'package:flutter/foundation.dart';
import 'package:laundry_app/features/common/data/database/app_database.dart';

class SqliteUserRepository {
  final AppDatabase _database = AppDatabase();

  /// Save or update user data
  Future<void> saveUserData({
    required String uid,
    String? name,
    String? email,
    String? phone,
    String? mainAddress,
  }) async {
    try {
      await _database.saveUserData(
        uid: uid,
        name: name,
        email: email,
        phone: phone,
        mainAddress: mainAddress,
      );
      
      // If mainAddress is provided, save it as an address
      if (mainAddress != null && mainAddress.isNotEmpty) {
        // Check if address already exists
        final existingAddresses = await _database.getAllAddresses();
        final existingAddress = existingAddresses.firstWhere(
          (addr) => addr['fullAddress'] == mainAddress,
          orElse: () => {},
        );
        
        if (existingAddress.isEmpty) {
          // Create a new address entry
          await _database.insertAddress(
            id: 'main_$uid',
            title: 'Main Address',
            fullAddress: mainAddress,
            lat: null,
            lng: null,
            createdAt: DateTime.now(),
          );
        }
      }
    } catch (e) {
      debugPrint('Error saving user data: $e');
      rethrow;
    }
  }

  /// Get user data
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      return await _database.getUserData(uid);
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  /// Update user data
  Future<void> updateUserData(String uid, Map<String, dynamic> updates) async {
    try {
      await _database.updateUserData(uid, updates);
    } catch (e) {
      debugPrint('Error updating user data: $e');
      rethrow;
    }
  }
}

