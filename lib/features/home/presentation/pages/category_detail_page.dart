import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:laundry_app/app/theme/app_theme.dart';
import 'package:laundry_app/features/common/presentation/providers/service_providers.dart';
import 'package:laundry_app/features/common/presentation/providers/providers.dart';
import 'package:laundry_app/features/common/presentation/providers/app_providers.dart';
import 'package:laundry_app/features/common/presentation/widgets/loading_widget.dart';
import 'package:laundry_app/features/common/domain/models/service_item.dart';
import 'package:laundry_app/features/common/domain/models/service_category.dart';
import 'package:laundry_app/features/common/domain/models/basket_item_model.dart';
import 'package:uuid/uuid.dart';

class CategoryDetailPage extends ConsumerStatefulWidget {
  final String categoryId;

  const CategoryDetailPage({
    super.key,
    required this.categoryId,
  });

  @override
  ConsumerState<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends ConsumerState<CategoryDetailPage> {
  @override
  void initState() {
    super.initState();
    // Set current category for total price calculation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentCategoryIdProvider.notifier).state = widget.categoryId;
    });
  }

  Future<void> _addToCart() async {
    // Use FirebaseAuth directly to get current user for more reliable check
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to add items to cart')),
        );
        // Navigate to login page
        context.push('/login');
      }
      return;
    }
    final userId = user.uid;

    final quantities = ref.read(selectedQuantitiesProvider);
    if (quantities.isEmpty || quantities.values.every((qty) => qty == 0)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one item')),
        );
      }
      return;
    }

    // Get category name
    final categoriesAsync = ref.read(categoriesProvider);
    final category = categoriesAsync.value?.firstWhere(
      (cat) => cat.id == widget.categoryId,
      orElse: () => const ServiceCategory(
        id: '',
        name: 'Unknown Category',
        icon: '',
      ),
    );

    // Get items
    final itemsAsync = ref.read(itemsProvider(widget.categoryId));
    final items = itemsAsync.value ?? [];

    if (items.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No items available')),
        );
      }
      return;
    }

    try {
      final cartRepo = ref.read(cartRepositoryProvider);
      final uuid = const Uuid();

      // Add each selected item to cart
      int addedCount = 0;
      int updatedCount = 0;
      for (final item in items) {
        final quantity = quantities[item.id] ?? 0;
        if (quantity > 0) {
          // Check if item already exists in cart
          final existingItem = await cartRepo.findExistingItem(
            userId,
            widget.categoryId,
            item.name,
          );

          if (existingItem != null) {
            // Item exists, update quantity
            final newQuantity = existingItem.quantity + quantity.toDouble();
            await cartRepo.updateQuantity(userId, existingItem.id, newQuantity);
            
            // Update fragrance if a new one is selected from home screen
            final selectedFragranceId = ref.read(selectedFragranceProvider);
            if (selectedFragranceId != null && selectedFragranceId != existingItem.fragranceId) {
              // Update fragrance in cart item
              await cartRepo.updateFragrance(userId, existingItem.id, selectedFragranceId);
            }
            
            updatedCount++;
          } else {
            // New item, add to cart
            // Get selected fragrance from global state
            final selectedFragranceId = ref.read(selectedFragranceProvider);
            
            // Get discount from selected laundry if available
            final selectedLaundry = ref.read(selectedLaundryProvider);
            final discountPercentage = selectedLaundry?.discountPercentage ?? 0;
            
            final basketItem = BasketItemModel(
              id: uuid.v4(),
              serviceId: widget.categoryId,
              serviceName: category?.name ?? 'Service',
              laundryId: '', // Service categories don't have a specific laundry
              laundryName: '', // Will be set later or can be updated
              quantity: quantity.toDouble(),
              pricePerKg: item.price,
              fragranceId: selectedFragranceId, // Use selected fragrance
              notes: item.name, // Store item name in notes field
              discountPercentage: discountPercentage, // Use selected laundry discount
            );

            await cartRepo.addItemToCart(userId, basketItem);
            addedCount++;
          }
        }
      }

      if (mounted) {
        // Clear selected quantities
        ref.read(selectedQuantitiesProvider.notifier).clearAll();

        String message;
        if (addedCount > 0 && updatedCount > 0) {
          message = '$addedCount item(s) added, $updatedCount item(s) updated in cart';
        } else if (addedCount > 0) {
          message = '$addedCount item(s) added to cart';
        } else if (updatedCount > 0) {
          message = '$updatedCount item(s) updated in cart';
        } else {
          message = 'Items processed';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View Cart',
              textColor: Colors.white,
              onPressed: () {
                context.push('/cart');
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding to cart: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(itemsProvider(widget.categoryId));
    final quantities = ref.watch(selectedQuantitiesProvider);
    final totalPrice = ref.watch(totalPriceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Items'),
      ),
      body: itemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('No items available in this category'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final quantity = quantities[item.id] ?? 0;

              return _buildItemCard(context, item, quantity);
            },
          );
        },
        loading: () => const LoadingWidget(),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading items: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(itemsProvider(widget.categoryId));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: totalPrice > 0
          ? FloatingActionButton.extended(
              onPressed: _addToCart,
              backgroundColor: AppTheme.primaryBlue,
              label: Text(
                'Add to Cart (SAR ${totalPrice.toStringAsFixed(2)})',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildItemCard(BuildContext context, ServiceItem item, int quantity) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Item name and price row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'SAR ${item.price.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Quantity controls with plus/minus buttons
            Row(
              children: [
                // Minus button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: quantity > item.min
                        ? () {
                            ref.read(selectedQuantitiesProvider.notifier).setQuantity(
                                  item.id,
                                  quantity - 1,
                                );
                          }
                        : null,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: quantity > item.min 
                            ? AppTheme.primaryBlue.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.remove,
                        color: quantity > item.min 
                            ? AppTheme.primaryBlue
                            : Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Quantity display
                Expanded(
                  child: Center(
                    child: Text(
                      quantity.toString(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Plus button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: quantity < item.max
                        ? () {
                            ref.read(selectedQuantitiesProvider.notifier).setQuantity(
                                  item.id,
                                  quantity + 1,
                                );
                          }
                        : null,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: quantity < item.max 
                            ? AppTheme.primaryBlue.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add,
                        color: quantity < item.max 
                            ? AppTheme.primaryBlue
                            : Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Slider
            Builder(
              builder: (context) {
                // Ensure value is within min and max range
                final sliderValue = quantity < item.min 
                    ? item.min.toDouble() 
                    : (quantity > item.max ? item.max.toDouble() : quantity.toDouble());
                
                return Slider(
                  value: sliderValue,
                  min: item.min.toDouble(),
                  max: item.max.toDouble(),
                  divisions: item.max > item.min ? item.max - item.min : null,
                  activeColor: AppTheme.primaryBlue,
                  label: sliderValue.toInt().toString(),
                  onChanged: (value) {
                    final intValue = value.toInt();
                    ref.read(selectedQuantitiesProvider.notifier).setQuantity(
                          item.id,
                          intValue,
                        );
                  },
                );
              },
            ),
            // Min and max labels
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${item.min}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                  ),
                  Text(
                    '${item.max}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

