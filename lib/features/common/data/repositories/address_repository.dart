import 'package:flutter/foundation.dart';
import 'package:laundry_app/features/common/domain/models/address_model.dart';
import 'package:laundry_app/features/common/data/database/address_database.dart';
import 'dart:async';

class AddressRepository {
  final AddressDatabase _database = AddressDatabase();
  final StreamController<String> _updateController = StreamController<String>.broadcast();
  final Map<String, StreamController<List<AddressModel>>> _userStreams = {};

  /// Get all addresses for a user (Stream)
  Stream<List<AddressModel>> getUserAddresses(String userId) {
    // Create or get stream controller for this user
    if (!_userStreams.containsKey(userId)) {
      final controller = StreamController<List<AddressModel>>.broadcast();
      _userStreams[userId] = controller;
      
      // Load and emit initial data immediately (don't await, fire and forget)
      _loadAndEmitAddresses(userId).catchError((error) {
        debugPrint('Error in initial load: $error');
        if (_userStreams.containsKey(userId) && !_userStreams[userId]!.isClosed) {
          _userStreams[userId]!.add([]);
        }
      });
      
      // Listen to updates for this user
      _updateController.stream
          .where((updatedUserId) => updatedUserId == userId)
          .listen((_) => _loadAndEmitAddresses(userId));
    }
    
    return _userStreams[userId]!.stream;
  }
  
  /// Load and emit addresses to stream
  Future<void> _loadAndEmitAddresses(String userId) async {
    if (!_userStreams.containsKey(userId) || _userStreams[userId]!.isClosed) {
      return;
    }
    
    try {
      debugPrint('Loading addresses for user: $userId');
      final addresses = await _database.getAddresses(userId);
      debugPrint('Loaded ${addresses.length} addresses for user: $userId');
      
      if (_userStreams.containsKey(userId) && !_userStreams[userId]!.isClosed) {
        _userStreams[userId]!.add(addresses);
        debugPrint('Emitted ${addresses.length} addresses to stream');
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading addresses for stream: $e');
      debugPrint('Stack trace: $stackTrace');
      // Emit empty list on error so UI doesn't stay in loading state
      if (_userStreams.containsKey(userId) && !_userStreams[userId]!.isClosed) {
        _userStreams[userId]!.add([]);
      }
    }
  }

  /// Get all addresses for a user (once)
  Future<List<AddressModel>> getUserAddressesOnce(String userId) async {
    try {
      return await _database.getAddresses(userId);
    } catch (e) {
      debugPrint('Error loading addresses: $e');
      return [];
    }
  }

  /// Add a new address
  Future<void> addAddress(AddressModel address) async {
    try {
      // If this is set as default, unset other defaults for this user
      if (address.isDefault) {
        await _database.unsetDefaults(address.userId);
      }
      
      // Insert new address
      await _database.insertAddress(address);
      
      // Emit updated list
      _notifyUpdate(address.userId);
    } catch (e) {
      debugPrint('Error adding address: $e');
      rethrow;
    }
  }

  /// Update an address
  Future<void> updateAddress(AddressModel address) async {
    try {
      // If this is set as default, unset other defaults for this user
      if (address.isDefault) {
        await _database.unsetDefaults(address.userId, excludeId: address.id);
      }
      
      // Update address
      await _database.updateAddress(address);
      
      // Emit updated list
      _notifyUpdate(address.userId);
    } catch (e) {
      debugPrint('Error updating address: $e');
      rethrow;
    }
  }

  /// Delete an address
  Future<void> deleteAddress(String addressId) async {
    try {
      // Get address to find userId before deleting
      final address = await _database.getAddressById(addressId);
      if (address == null) {
        // Address not found, nothing to delete
        return;
      }
      
      final userId = address.userId;
      
      // Delete address
      await _database.deleteAddress(addressId);
      
      // Notify stream listeners
      _notifyUpdate(userId);
    } catch (e) {
      debugPrint('Error deleting address: $e');
      rethrow;
    }
  }

  /// Set an address as default
  Future<void> setDefaultAddress(String userId, String addressId) async {
    try {
      // Unset other defaults for this user
      await _database.unsetDefaults(userId, excludeId: addressId);
      
      // Get the address and update it
      final addresses = await _database.getAddresses(userId);
      final address = addresses.firstWhere((addr) => addr.id == addressId);
      final updatedAddress = address.copyWith(isDefault: true);
      
      await _database.updateAddress(updatedAddress);
      
      _notifyUpdate(userId);
    } catch (e) {
      debugPrint('Error setting default address: $e');
      rethrow;
    }
  }

  /// Get default address
  Future<AddressModel?> getDefaultAddress(String userId) async {
    try {
      return await _database.getDefaultAddress(userId);
    } catch (e) {
      debugPrint('Error getting default address: $e');
      return null;
    }
  }

  /// Emit update notification for a user
  void _notifyUpdate(String userId) {
    if (!_updateController.isClosed) {
      _updateController.add(userId);
    }
    // Also directly update the stream
    _loadAndEmitAddresses(userId);
  }

  /// Dispose stream controllers
  void dispose() {
    _updateController.close();
    for (final controller in _userStreams.values) {
      controller.close();
    }
    _userStreams.clear();
  }
}
