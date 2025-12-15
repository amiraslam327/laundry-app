import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:laundry_app/features/common/domain/models/address_model.dart';

class AddressDatabase {
  static final AddressDatabase _instance = AddressDatabase._internal();
  static Database? _database;

  factory AddressDatabase() {
    return _instance;
  }

  AddressDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'addresses.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE addresses (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        label TEXT NOT NULL,
        name TEXT NOT NULL,
        phoneNumber TEXT NOT NULL,
        address TEXT NOT NULL,
        lat REAL,
        lng REAL,
        isDefault INTEGER NOT NULL DEFAULT 0,
        createdAt INTEGER NOT NULL
      )
    ''');
    
    // Create index on userId for faster queries
    await db.execute('''
      CREATE INDEX idx_userId ON addresses(userId)
    ''');
  }

  // Convert AddressModel to Map for database
  Map<String, dynamic> _addressToMap(AddressModel address) {
    return {
      'id': address.id,
      'userId': address.userId,
      'label': address.label,
      'name': address.name,
      'phoneNumber': address.phoneNumber,
      'address': address.address,
      'lat': address.lat,
      'lng': address.lng,
      'isDefault': address.isDefault ? 1 : 0,
      'createdAt': address.createdAt.millisecondsSinceEpoch,
    };
  }

  // Convert Map from database to AddressModel
  AddressModel _mapToAddress(Map<String, dynamic> map) {
    return AddressModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      label: map['label'] as String,
      name: map['name'] as String,
      phoneNumber: map['phoneNumber'] as String,
      address: map['address'] as String,
      lat: map['lat'] as double?,
      lng: map['lng'] as double?,
      isDefault: (map['isDefault'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  // Get all addresses for a user
  Future<List<AddressModel>> getAddresses(String userId) async {
    try {
      final db = await database;
      final maps = await db.query(
        'addresses',
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'createdAt DESC',
      );
      return maps.map((map) => _mapToAddress(map)).toList();
    } catch (e) {
      debugPrint('Database error in getAddresses: $e');
      rethrow;
    }
  }

  // Insert address
  Future<void> insertAddress(AddressModel address) async {
    final db = await database;
    await db.insert(
      'addresses',
      _addressToMap(address),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Update address
  Future<void> updateAddress(AddressModel address) async {
    final db = await database;
    await db.update(
      'addresses',
      _addressToMap(address),
      where: 'id = ?',
      whereArgs: [address.id],
    );
  }

  // Delete address
  Future<void> deleteAddress(String addressId) async {
    final db = await database;
    await db.delete(
      'addresses',
      where: 'id = ?',
      whereArgs: [addressId],
    );
  }

  // Get default address for a user
  Future<AddressModel?> getDefaultAddress(String userId) async {
    final db = await database;
    final maps = await db.query(
      'addresses',
      where: 'userId = ? AND isDefault = ?',
      whereArgs: [userId, 1],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return _mapToAddress(maps.first);
  }

  // Get address by ID
  Future<AddressModel?> getAddressById(String addressId) async {
    final db = await database;
    final maps = await db.query(
      'addresses',
      where: 'id = ?',
      whereArgs: [addressId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return _mapToAddress(maps.first);
  }

  // Unset all default addresses for a user
  Future<void> unsetDefaults(String userId, {String? excludeId}) async {
    final db = await database;
    if (excludeId != null) {
      await db.update(
        'addresses',
        {'isDefault': 0},
        where: 'userId = ? AND id != ? AND isDefault = ?',
        whereArgs: [userId, excludeId, 1],
      );
    } else {
      await db.update(
        'addresses',
        {'isDefault': 0},
        where: 'userId = ? AND isDefault = ?',
        whereArgs: [userId, 1],
      );
    }
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

