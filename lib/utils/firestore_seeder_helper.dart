import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laundry_app/utils/firestore_seeder.dart';

/// Helper class to easily seed Firestore from your app
/// 
/// Usage in your app:
/// ```dart
/// final helper = FirestoreSeederHelper();
/// await helper.seedSampleData();
/// ```
class FirestoreSeederHelper {
  final FirestoreSeeder _seeder = FirestoreSeeder();

  /// Seed all sample data
  Future<void> seedSampleData() async {
    await _seeder.seedAll();
  }

  /// Seed only fragrances
  Future<void> seedFragrances() async {
    await _seeder.seedFragrances();
  }

  /// Seed only laundries
  Future<void> seedLaundries() async {
    await _seeder.seedLaundries();
  }

  /// Seed only services
  Future<void> seedServices() async {
    await _seeder.seedServices();
  }

  /// Seed only service categories
  Future<void> seedServiceCategories() async {
    await _seeder.seedServiceCategories();
  }

  /// Clear all seeded data
  Future<void> clearAllData() async {
    await _seeder.clearAll();
  }

  /// Add a single laundry manually
  Future<void> addLaundry({
    required String id,
    required String name,
    required String description,
    required String address,
    double rating = 0.0,
    bool isPreferred = false,
    double minOrderAmount = 0.0,
    int discountPercentage = 0,
    String? logoUrl,
    String? bannerImageUrl,
  }) async {
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('laundries').doc(id).set({
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'rating': rating,
      'isPreferred': isPreferred,
      'minOrderAmount': minOrderAmount,
      'discountPercentage': discountPercentage,
      'logoUrl': logoUrl,
      'bannerImageUrl': bannerImageUrl,
    });
  }

  /// Add a single service manually
  Future<void> addService({
    required String id,
    required String laundryId,
    required String name,
    required String description,
    required double pricePerKg,
    required int estimatedHours,
    bool isPopular = false,
  }) async {
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('services').doc(id).set({
      'id': id,
      'laundryId': laundryId,
      'name': name,
      'description': description,
      'pricePerKg': pricePerKg,
      'estimatedHours': estimatedHours,
      'isPopular': isPopular,
    });
  }

  /// Add a single fragrance manually
  Future<void> addFragrance({
    required String id,
    required String name,
    String? iconUrl,
  }) async {
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('fragrances').doc(id).set({
      'id': id,
      'name': name,
      'iconUrl': iconUrl,
    });
  }
}

