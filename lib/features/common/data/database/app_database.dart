import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  static Database? _database;

  factory AppDatabase() {
    return _instance;
  }

  AppDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app_database.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create user_data table
    await db.execute('''
      CREATE TABLE user_data (
        uid TEXT PRIMARY KEY,
        name TEXT,
        email TEXT,
        phone TEXT,
        mainAddress TEXT
      )
    ''');

    // Create addresses table
    await db.execute('''
      CREATE TABLE addresses (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        fullAddress TEXT NOT NULL,
        lat REAL,
        lng REAL,
        createdAt INTEGER NOT NULL
      )
    ''');

    // Create selected_address table (stores the currently selected address ID)
    await db.execute('''
      CREATE TABLE selected_address (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        addressId TEXT NOT NULL,
        FOREIGN KEY (addressId) REFERENCES addresses(id)
      )
    ''');

    // Create index on addresses for faster queries
    await db.execute('''
      CREATE INDEX idx_addresses_createdAt ON addresses(createdAt)
    ''');
  }

  // ==================== USER_DATA METHODS ====================

  /// Save or update user data
  Future<void> saveUserData({
    required String uid,
    String? name,
    String? email,
    String? phone,
    String? mainAddress,
  }) async {
    final db = await database;
    await db.insert(
      'user_data',
      {
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'mainAddress': mainAddress,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get user data
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final db = await database;
    final maps = await db.query(
      'user_data',
      where: 'uid = ?',
      whereArgs: [uid],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return maps.first;
  }

  /// Update user data
  Future<void> updateUserData(String uid, Map<String, dynamic> updates) async {
    final db = await database;
    await db.update(
      'user_data',
      updates,
      where: 'uid = ?',
      whereArgs: [uid],
    );
  }

  // ==================== ADDRESSES METHODS ====================

  /// Insert address
  Future<void> insertAddress({
    required String id,
    required String title,
    required String fullAddress,
    double? lat,
    double? lng,
    required DateTime createdAt,
  }) async {
    final db = await database;
    await db.insert(
      'addresses',
      {
        'id': id,
        'title': title,
        'fullAddress': fullAddress,
        'lat': lat,
        'lng': lng,
        'createdAt': createdAt.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all addresses
  Future<List<Map<String, dynamic>>> getAllAddresses() async {
    final db = await database;
    final maps = await db.query(
      'addresses',
      orderBy: 'createdAt DESC',
    );
    return maps;
  }

  /// Get address by ID
  Future<Map<String, dynamic>?> getAddressById(String id) async {
    final db = await database;
    final maps = await db.query(
      'addresses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return maps.first;
  }

  /// Update address
  Future<void> updateAddress({
    required String id,
    String? title,
    String? fullAddress,
    double? lat,
    double? lng,
  }) async {
    final db = await database;
    final Map<String, dynamic> updates = {};
    if (title != null) updates['title'] = title;
    if (fullAddress != null) updates['fullAddress'] = fullAddress;
    if (lat != null) updates['lat'] = lat;
    if (lng != null) updates['lng'] = lng;

    if (updates.isNotEmpty) {
      await db.update(
        'addresses',
        updates,
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  /// Delete address
  Future<void> deleteAddress(String id) async {
    final db = await database;
    await db.delete(
      'addresses',
      where: 'id = ?',
      whereArgs: [id],
    );
    // Also remove from selected_address if it was selected
    await db.delete(
      'selected_address',
      where: 'addressId = ?',
      whereArgs: [id],
    );
  }

  // ==================== SELECTED ADDRESS METHODS ====================

  /// Set selected address
  Future<void> setSelectedAddress(String addressId) async {
    final db = await database;
    // Clear existing selection
    await db.delete('selected_address');
    // Set new selection
    await db.insert(
      'selected_address',
      {'addressId': addressId},
    );
  }

  /// Get selected address
  Future<Map<String, dynamic>?> getSelectedAddress() async {
    final db = await database;
    final maps = await db.query(
      'selected_address',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final addressId = maps.first['addressId'] as String;
    return await getAddressById(addressId);
  }

  /// Clear selected address
  Future<void> clearSelectedAddress() async {
    final db = await database;
    await db.delete('selected_address');
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

