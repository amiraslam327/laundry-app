import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundry_app/features/common/data/repositories/service_repository.dart';
import 'package:laundry_app/features/common/domain/models/service_category.dart';
import 'package:laundry_app/features/common/domain/models/service_item.dart';

// Repository provider
final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  return ServiceRepository();
});

// Categories stream provider
final categoriesProvider = StreamProvider<List<ServiceCategory>>((ref) {
  final repository = ref.watch(serviceRepositoryProvider);
  return repository.getCategories();
});

// Items stream provider (family for categoryId parameter)
final itemsProvider = StreamProvider.family<List<ServiceItem>, String>((ref, categoryId) {
  final repository = ref.watch(serviceRepositoryProvider);
  return repository.getItems(categoryId);
});

// Selected quantities state (Map<itemId, quantity>)
final selectedQuantitiesProvider = StateNotifierProvider<SelectedQuantitiesNotifier, Map<String, int>>((ref) {
  return SelectedQuantitiesNotifier();
});

class SelectedQuantitiesNotifier extends StateNotifier<Map<String, int>> {
  SelectedQuantitiesNotifier() : super({});

  void setQuantity(String itemId, int quantity) {
    state = {...state, itemId: quantity};
  }

  void clearQuantity(String itemId) {
    final newState = Map<String, int>.from(state);
    newState.remove(itemId);
    state = newState;
  }

  void clearAll() {
    state = {};
  }

  int getQuantity(String itemId) {
    return state[itemId] ?? 0;
  }
}

// Total price provider - calculates sum of (price * quantity) for all selected items
final totalPriceProvider = Provider<double>((ref) {
  final quantities = ref.watch(selectedQuantitiesProvider);
  final categoryId = ref.watch(currentCategoryIdProvider);
  
  if (categoryId == null || quantities.isEmpty) {
    return 0.0;
  }

  final itemsAsync = ref.watch(itemsProvider(categoryId));
  
  return itemsAsync.when(
    data: (items) {
      double total = 0.0;
      for (final item in items) {
        final quantity = quantities[item.id] ?? 0;
        if (quantity > 0) {
          total += item.price * quantity;
        }
      }
      return total;
    },
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

// Current category ID provider (for total price calculation)
final currentCategoryIdProvider = StateProvider<String?>((ref) => null);

