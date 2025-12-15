import 'package:flutter/foundation.dart';
import 'package:laundry_app/features/common/data/database/app_database.dart';
import 'package:laundry_app/features/common/domain/models/sqlite_address_model.dart';
import 'dart:async';

class SqliteAddressRepository {
  final AppDatabase _database = AppDatabase();
  final StreamController<List<SqliteAddressModel>> _addressesController =
      StreamController<List<SqliteAddressModel>>.broadcast();

  /// Get all addresses (Stream)
  Stream<List<SqliteAddressModel>> getAllAddressesStream() {
    _loadAndEmitAddresses();
    return _addressesController.stream;
  }

  /// Get all addresses (once)
  Future<List<SqliteAddressModel>> getAllAddresses() async {
    try {
      final maps = await _database.getAllAddresses();
      return maps.map((map) => SqliteAddressModel.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error loading addresses: $e');
      return [];
    }
  }

  /// Get selected address
  Future<SqliteAddressModel?> getSelectedAddress() async {
    try {
      final map = await _database.getSelectedAddress();
      if (map == null) return null;
      return SqliteAddressModel.fromMap(map);
    } catch (e) {
      debugPrint('Error getting selected address: $e');
      return null;
    }
  }

  /// Add address
  Future<void> addAddress(SqliteAddressModel address) async {
    try {
      await _database.insertAddress(
        id: address.id,
        title: address.title,
        fullAddress: address.fullAddress,
        lat: address.lat,
        lng: address.lng,
        createdAt: address.createdAt,
      );
      _loadAndEmitAddresses();
    } catch (e) {
      debugPrint('Error adding address: $e');
      rethrow;
    }
  }

  /// Update address
  Future<void> updateAddress(SqliteAddressModel address) async {
    try {
      await _database.updateAddress(
        id: address.id,
        title: address.title,
        fullAddress: address.fullAddress,
        lat: address.lat,
        lng: address.lng,
      );
      _loadAndEmitAddresses();
    } catch (e) {
      debugPrint('Error updating address: $e');
      rethrow;
    }
  }

  /// Delete address
  Future<void> deleteAddress(String id) async {
    try {
      await _database.deleteAddress(id);
      _loadAndEmitAddresses();
    } catch (e) {
      debugPrint('Error deleting address: $e');
      rethrow;
    }
  }

  /// Set selected address
  Future<void> setSelectedAddress(String addressId) async {
    try {
      await _database.setSelectedAddress(addressId);
      _loadAndEmitAddresses();
    } catch (e) {
      debugPrint('Error setting selected address: $e');
      rethrow;
    }
  }

  /// Load and emit addresses to stream
  Future<void> _loadAndEmitAddresses() async {
    try {
      final addresses = await getAllAddresses();
      if (!_addressesController.isClosed) {
        _addressesController.add(addresses);
      }
    } catch (e) {
      debugPrint('Error loading addresses for stream: $e');
      if (!_addressesController.isClosed) {
        _addressesController.add([]);
      }
    }
  }

  /// Dispose
  void dispose() {
    _addressesController.close();
  }
}

