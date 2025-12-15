import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:laundry_app/features/common/domain/models/laundry_model.dart';
import 'package:laundry_app/features/common/domain/models/service_model.dart';
import 'package:laundry_app/features/common/domain/models/fragrance_model.dart';

/// Firestore Seeder - Add sample data to Firestore
///
/// Usage:
/// 1. Run: dart run lib/utils/firestore_seeder.dart
/// 2. Or call seedFirestore() from your app
class FirestoreSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Seed all collections with sample data
  Future<void> seedAll() async {
    print('🌱 Starting Firestore seeding...\n');

    try {
      await seedFragrances();
      await seedLaundries();
      await seedServices();
      await seedServiceCategories();

      print('\n✅ Firestore seeding completed successfully!');
    } catch (e) {
      print('\n❌ Error seeding Firestore: $e');
      rethrow;
    }
  }

  /// Seed Fragrances collection
  Future<void> seedFragrances() async {
    print('📦 Seeding Fragrances...');

    final fragrances = [
      {'id': 'fragrance1', 'name': 'Mild', 'iconUrl': null},
      {'id': 'fragrance2', 'name': 'Floral', 'iconUrl': null},
      {'id': 'fragrance3', 'name': 'Fruity', 'iconUrl': null},
      {'id': 'fragrance4', 'name': 'Citrus', 'iconUrl': null},
      {'id': 'fragrance5', 'name': 'Fresh', 'iconUrl': null},
      {'id': 'fragrance6', 'name': 'Lavender', 'iconUrl': null},
    ];

    final batch = _firestore.batch();
    for (var fragrance in fragrances) {
      final docRef = _firestore.collection('fragrances').doc(fragrance['id'] as String);
      batch.set(docRef, fragrance);
    }
    await batch.commit();

    print('   ✅ Created ${fragrances.length} fragrances');
  }

  /// Seed Laundries collection
  Future<void> seedLaundries() async {
    print('📦 Seeding Laundries...');

    final laundries = [
      {
        'id': 'laundry1',
        'name': 'Magic Touch The Best Laundry',
        'description': 'Premium laundry services with quick turnaround and excellent quality',
        'logoUrl': null,
        'rating': 4.5,
        'isPreferred': true,
        'address': 'Cyberjaya, Selangor',
        'minOrderAmount': 10.0,
        'discountPercentage': 5,
        'bannerImageUrl': null,
      },
      {
        'id': 'laundry2',
        'name': 'Kenvin Laundry The Best Laundry',
        'description': 'Quality service at affordable prices with fast delivery',
        'logoUrl': null,
        'rating': 4.5,
        'isPreferred': true,
        'address': 'Cyberjaya, Selangor',
        'minOrderAmount': 8.0,
        'discountPercentage': 5,
        'bannerImageUrl': null,
      },
      {
        'id': 'laundry3',
        'name': 'The Best Laundry',
        'description': 'Fast and reliable laundry services with premium care',
        'logoUrl': null,
        'rating': 4.5,
        'isPreferred': true,
        'address': 'Cyberjaya, Selangor',
        'minOrderAmount': 12.0,
        'discountPercentage': 20,
        'bannerImageUrl': null,
      },
      {
        'id': 'laundry4',
        'name': 'Express Laundry Services',
        'description': 'Same-day service available for urgent needs',
        'logoUrl': null,
        'rating': 4.3,
        'isPreferred': false,
        'address': 'Kuala Lumpur, Malaysia',
        'minOrderAmount': 15.0,
        'discountPercentage': 10,
        'bannerImageUrl': null,
      },
    ];

    final batch = _firestore.batch();
    for (var laundry in laundries) {
      final docRef = _firestore.collection('laundries').doc(laundry['id'] as String);
      batch.set(docRef, laundry);
    }
    await batch.commit();

    print('   ✅ Created ${laundries.length} laundries');
  }

  /// Seed Services collection
  Future<void> seedServices() async {
    print('📦 Seeding Services...');

    final services = [
      // Services for laundry1
      {
        'id': 'service1',
        'laundryId': 'laundry1',
        'name': 'Quick Wash',
        'description': 'Fast washing service, ready in 4 hours',
        'pricePerKg': 5.0,
        'estimatedHours': 4,
        'isPopular': true,
      },
      {
        'id': 'service2',
        'laundryId': 'laundry1',
        'name': 'Standard Wash',
        'description': 'Standard wash and fold service',
        'pricePerKg': 4.0,
        'estimatedHours': 24,
        'isPopular': true,
      },
      {
        'id': 'service3',
        'laundryId': 'laundry1',
        'name': 'Premium Service',
        'description': 'Premium service with ironing included',
        'pricePerKg': 7.5,
        'estimatedHours': 48,
        'isPopular': false,
      },
      // Services for laundry2
      {
        'id': 'service4',
        'laundryId': 'laundry2',
        'name': 'Express Wash',
        'description': 'Ultra-fast service, ready in 2 hours',
        'pricePerKg': 6.0,
        'estimatedHours': 2,
        'isPopular': true,
      },
      {
        'id': 'service5',
        'laundryId': 'laundry2',
        'name': 'Regular Wash',
        'description': 'Regular wash and dry service',
        'pricePerKg': 3.5,
        'estimatedHours': 24,
        'isPopular': true,
      },
      // Services for laundry3
      {
        'id': 'service6',
        'laundryId': 'laundry3',
        'name': 'Deluxe Service',
        'description': 'Deluxe service with premium care',
        'pricePerKg': 9.0,
        'estimatedHours': 72,
        'isPopular': true,
      },
      {
        'id': 'service7',
        'laundryId': 'laundry3',
        'name': 'Standard Service',
        'description': 'Standard wash, dry, and fold',
        'pricePerKg': 4.5,
        'estimatedHours': 48,
        'isPopular': true,
      },
      // Services for laundry4
      {
        'id': 'service8',
        'laundryId': 'laundry4',
        'name': 'Same Day Service',
        'description': 'Same day pickup and delivery',
        'pricePerKg': 10.0,
        'estimatedHours': 8,
        'isPopular': true,
      },
    ];

    final batch = _firestore.batch();
    for (var service in services) {
      final docRef = _firestore.collection('services').doc(service['id'] as String);
      batch.set(docRef, service);
    }
    await batch.commit();

    print('   ✅ Created ${services.length} services');
  }

  /// Seed Service Categories collection
  Future<void> seedServiceCategories() async {
    print('📦 Seeding Service Categories...');

    final categories = [
      {
        'id': 'wash',
        'name': 'Wash',
        'icon': 'assets/icons/wash.png',
        'duration': '24 hours',
      },
      {
        'id': 'iron',
        'name': 'Iron',
        'icon': 'assets/icons/iron.png',
        'duration': '12 hours',
      },
      {
        'id': 'dry_clean',
        'name': 'Dry Clean',
        'icon': 'assets/icons/dryclean.png',
        'duration': '3 days',
      },
      {
        'id': 'fold',
        'name': 'Fold',
        'icon': 'assets/icons/fold.png',
        'duration': '6 hours',
      },
    ];

    final batch = _firestore.batch();
    for (var category in categories) {
      final docRef = _firestore.collection('serviceCategories').doc(category['id'] as String);
      batch.set(docRef, category);

      // Add sample items to each category
      await _seedCategoryItems(category['id'] as String);
    }
    await batch.commit();

    print('   ✅ Created ${categories.length} service categories');
  }

  /// Seed items for a service category
  Future<void> _seedCategoryItems(String categoryId) async {
    final items = [
      {
        'name': 'Shirt',
        'price': 5.0,
        'min': 0,
        'max': 50,
      },
      {
        'name': 'Pants',
        'price': 7.0,
        'min': 0,
        'max': 30,
      },
      {
        'name': 'Kurta',
        'price': 25.0,
        'min': 0,
        'max': 50,
      },
      {
        'name': 'Dress',
        'price': 12.0,
        'min': 0,
        'max': 20,
      },
    ];

    final batch = _firestore.batch();
    for (var item in items) {
      final docRef = _firestore
          .collection('serviceCategories')
          .doc(categoryId)
          .collection('items')
          .doc(); // Auto-generate ID
      batch.set(docRef, item);
    }
    await batch.commit();
  }

  /// Clear all seeded data (use with caution!)
  Future<void> clearAll() async {
    print('🗑️  Clearing all seeded data...\n');

    try {
      // Delete fragrances
      final fragrancesSnapshot = await _firestore.collection('fragrances').get();
      final batch1 = _firestore.batch();
      for (var doc in fragrancesSnapshot.docs) {
        batch1.delete(doc.reference);
      }
      await batch1.commit();
      print('   ✅ Cleared fragrances');

      // Delete laundries
      final laundriesSnapshot = await _firestore.collection('laundries').get();
      final batch2 = _firestore.batch();
      for (var doc in laundriesSnapshot.docs) {
        batch2.delete(doc.reference);
      }
      await batch2.commit();
      print('   ✅ Cleared laundries');

      // Delete services
      final servicesSnapshot = await _firestore.collection('services').get();
      final batch3 = _firestore.batch();
      for (var doc in servicesSnapshot.docs) {
        batch3.delete(doc.reference);
      }
      await batch3.commit();
      print('   ✅ Cleared services');

      // Delete service categories and their items
      final categoriesSnapshot = await _firestore.collection('serviceCategories').get();
      final batch4 = _firestore.batch();
      for (var doc in categoriesSnapshot.docs) {
        // Delete items subcollection
        final itemsSnapshot = await doc.reference.collection('items').get();
        for (var itemDoc in itemsSnapshot.docs) {
          batch4.delete(itemDoc.reference);
        }
        // Delete category
        batch4.delete(doc.reference);
      }
      await batch4.commit();
      print('   ✅ Cleared service categories');

      print('\n✅ All seeded data cleared!');
    } catch (e) {
      print('\n❌ Error clearing data: $e');
      rethrow;
    }
  }
}

/// Main function to run seeder (for command line usage)
/// Run with: dart run lib/utils/firestore_seeder.dart
Future<void> main() async {
  // Initialize Firebase
  // Note: Make sure Firebase is initialized before running this
  // If using flutterfire configure, uncomment the import and use:
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  try {
    // Check if Firebase is already initialized
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }

    final seeder = FirestoreSeeder();
    
    // Seed all collections
    await seeder.seedAll();
    
    // Uncomment to clear data instead:
    // await seeder.clearAll();
  } catch (e) {
    print('Error: $e');
    print('\nMake sure Firebase is properly configured!');
  }
}

