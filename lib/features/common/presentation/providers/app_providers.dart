import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundry_app/features/common/presentation/providers/providers.dart';
import 'package:laundry_app/features/common/domain/models/user_model.dart';
import 'package:laundry_app/features/common/domain/models/laundry_model.dart';
import 'package:laundry_app/features/common/domain/models/service_model.dart';
import 'package:laundry_app/features/common/domain/models/fragrance_model.dart';
import 'package:laundry_app/features/common/domain/models/basket_item_model.dart';
import 'package:laundry_app/features/common/domain/models/order_model.dart';

// Auth Provider
final authProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Current User ID Provider
final currentUserIdProvider = Provider<String?>((ref) {
  final authAsync = ref.watch(authProvider);
  return authAsync.value?.uid;
});

// User Provider
final userProvider = StreamProvider<UserModel>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    throw Exception('User not authenticated');
  }
  final repository = ref.watch(usersRepositoryProvider);
  return repository.getUserStream(userId);
});

// Cart Repository Provider (imported from providers.dart)

// Laundries Provider
final laundriesProvider = StreamProvider<List<LaundryModel>>((ref) {
  final repository = ref.watch(laundriesRepositoryProvider);
  return repository.getAllLaundries();
});

// Services Provider (family for laundryId)
final servicesProvider = StreamProvider.family<List<ServiceModel>, String>((ref, laundryId) {
  final repository = ref.watch(servicesRepositoryProvider);
  return repository.getServicesByLaundry(laundryId);
});

// Fragrances Provider
final fragrancesProvider = StreamProvider<List<FragranceModel>>((ref) {
  final repository = ref.watch(fragrancesRepositoryProvider);
  return repository.getAllFragrances();
});

// Selected Fragrance Provider (global state for selected fragrance)
final selectedFragranceProvider = StateProvider<String?>((ref) => null);

// Selected Laundry Provider (only last clicked laundry)
final selectedLaundryProvider = StateProvider<LaundryModel?>((ref) => null);

// Helper provider to check if a laundry is selected
final isLaundrySelectedProvider = Provider.family<bool, String>((ref, laundryId) {
  final selectedLaundry = ref.watch(selectedLaundryProvider);
  return selectedLaundry?.id == laundryId;
});

// Cart Provider (family for userId)
final cartProvider = StreamProvider.family<List<BasketItemModel>, String>((ref, userId) {
  final repository = ref.watch(cartRepositoryProvider);
  return repository.getCartItems(userId);
});

// Orders Provider (family for userId)
final orderListProvider = StreamProvider.family<List<OrderModel>, String>((ref, userId) {
  final repository = ref.watch(ordersRepositoryProvider);
  return repository.getUserOrders(userId);
});

// Order Detail Provider (family for orderId)
final orderDetailProvider = StreamProvider.family<OrderModel, String>((ref, orderId) {
  final repository = ref.watch(ordersRepositoryProvider);
  return repository.getOrderDetails(orderId);
});

