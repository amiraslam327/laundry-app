import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundry_app/features/common/data/services/auth_service.dart';
import 'package:laundry_app/features/common/data/repositories/users_repository.dart';
import 'package:laundry_app/features/common/data/repositories/laundries_repository.dart';
import 'package:laundry_app/features/common/data/repositories/services_repository.dart';
import 'package:laundry_app/features/common/data/repositories/fragrances_repository.dart';
import 'package:laundry_app/features/common/data/repositories/orders_repository.dart';
import 'package:laundry_app/features/common/data/repositories/cart_repository.dart';
import 'package:laundry_app/features/common/data/repositories/address_repository.dart';
import 'package:laundry_app/features/common/domain/models/basket_item_model.dart';

// Services
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Repositories
final usersRepositoryProvider =
    Provider<UsersRepository>((ref) => UsersRepository());

final laundriesRepositoryProvider =
    Provider<LaundriesRepository>((ref) => LaundriesRepository());

final servicesRepositoryProvider =
    Provider<ServicesRepository>((ref) => ServicesRepository());

final fragrancesRepositoryProvider =
    Provider<FragrancesRepository>((ref) => FragrancesRepository());

final ordersRepositoryProvider =
    Provider<OrdersRepository>((ref) => OrdersRepository());

final cartRepositoryProvider =
    Provider<CartRepository>((ref) => CartRepository());

final addressRepositoryProvider =
    Provider<AddressRepository>((ref) => AddressRepository());

// Basket State (in-memory for now, can be persisted later)
final basketProvider =
    StateNotifierProvider<BasketNotifier, List<BasketItemModel>>((ref) {
  return BasketNotifier();
});

class BasketNotifier extends StateNotifier<List<BasketItemModel>> {
  BasketNotifier() : super([]);

  void addItem(BasketItemModel item) {
    state = [...state, item];
  }

  void removeItem(String itemId) {
    state = state.where((item) => item.id != itemId).toList();
  }

  void updateItem(BasketItemModel updatedItem) {
    state = state
        .map((item) => item.id == updatedItem.id ? updatedItem : item)
        .toList();
  }

  void clearBasket() {
    state = [];
  }

  double get totalPrice {
    return state.fold(0.0, (sum, item) => sum + item.totalPrice);
  }
}

