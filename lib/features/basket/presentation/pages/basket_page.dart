import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundry_app/app/localization/app_localizations.dart';
import 'package:laundry_app/features/common/presentation/widgets/empty_state_widget.dart';
import 'package:laundry_app/features/common/presentation/widgets/app_button.dart';
import 'package:laundry_app/features/common/presentation/providers/providers.dart';
import 'package:laundry_app/features/common/domain/models/basket_item_model.dart';
import 'package:laundry_app/features/common/domain/models/order_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class BasketPage extends ConsumerStatefulWidget {
  const BasketPage({super.key});

  @override
  ConsumerState<BasketPage> createState() => _BasketPageState();
}

class _BasketPageState extends ConsumerState<BasketPage> {
  DateTime? _pickupDate;
  TimeOfDay? _pickupTime;
  DateTime? _deliveryDate;
  TimeOfDay? _deliveryTime;
  final _addressController = TextEditingController();
  bool _isPlacingOrder = false;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _selectPickupDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _pickupDate = date;
          _pickupTime = time;
        });
      }
    }
  }

  Future<void> _selectDeliveryDateTime() async {
    final minDate = _pickupDate ?? DateTime.now().add(const Duration(days: 1));
    
    final date = await showDatePicker(
      context: context,
      initialDate: minDate.add(const Duration(days: 1)),
      firstDate: minDate,
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _deliveryDate = date;
          _deliveryTime = time;
        });
      }
    }
  }

  Future<void> _placeOrder() async {
    final basket = ref.read(basketProvider);
    if (basket.isEmpty) return;

    if (_pickupDate == null || _pickupTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select pickup date and time')),
      );
      return;
    }

    if (_deliveryDate == null || _deliveryTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select delivery date and time')),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        context.go('/login');
        return;
      }

      final ordersRepository = ref.read(ordersRepositoryProvider);
      final basketNotifier = ref.read(basketProvider.notifier);

      // Group items by laundry
      final ordersByLaundry = <String, List<BasketItemModel>>{};
      for (final item in basket) {
        ordersByLaundry.putIfAbsent(item.laundryId, () => []).add(item);
      }

      // Create orders for each laundry
      String? firstOrderId;
      for (final entry in ordersByLaundry.entries) {
        final items = entry.value;
        final totalPrice = items.fold(0.0, (sum, item) => sum + item.totalPrice);

        final pickupDateTime = DateTime(
          _pickupDate!.year,
          _pickupDate!.month,
          _pickupDate!.day,
          _pickupTime!.hour,
          _pickupTime!.minute,
        );

        final deliveryDateTime = DateTime(
          _deliveryDate!.year,
          _deliveryDate!.month,
          _deliveryDate!.day,
          _deliveryTime!.hour,
          _deliveryTime!.minute,
        );

        final order = OrderModel(
          id: const Uuid().v4(),
          userId: user.uid,
          laundryId: entry.key,
          status: OrderStatus.pending,
          items: items.map((item) => OrderItem(
            serviceId: item.serviceId,
            serviceName: item.serviceName,
            quantity: item.quantity,
            price: item.totalPrice,
          )).toList(),
          fragranceId: items.first.fragranceId,
          pickupTime: pickupDateTime,
          deliveryTime: deliveryDateTime,
          totalPrice: totalPrice,
          createdAt: DateTime.now(),
          notes: _addressController.text.isEmpty ? null : _addressController.text,
        );

        final orderId = await ordersRepository.createOrder(order);
        if (firstOrderId == null) {
          firstOrderId = orderId;
        }
      }

      // Clear basket
      basketNotifier.clearBasket();

      if (mounted && firstOrderId != null) {
        context.go('/order-success/$firstOrderId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error placing order: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final basket = ref.watch(basketProvider);
    final basketNotifier = ref.read(basketProvider.notifier);
    final totalPrice = basket.fold(0.0, (sum, item) => sum + item.totalPrice);

    if (basket.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.myBasket),
        ),
        body: EmptyStateWidget(
          title: l10n.emptyBasket,
          message: 'Check out our best offers and laundry services',
          buttonText: l10n.startAdding,
          onButtonPressed: () => context.go('/home'),
          icon: Icon(
            Icons.shopping_basket_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
        ),
        bottomNavigationBar: _buildBottomNav(context, 2),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myBasket),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basket items
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: basket.length,
              itemBuilder: (context, index) {
                final item = basket[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(item.serviceName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${item.quantity.toStringAsFixed(1)} kg'),
                        Text('SAR ${item.totalPrice.toStringAsFixed(2)}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            // TODO: Edit item
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            basketNotifier.removeItem(item.id);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // Pickup time
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Pickup Date & Time'),
                subtitle: Text(
                  _pickupDate != null && _pickupTime != null
                      ? '${_pickupDate!.day}/${_pickupDate!.month}/${_pickupDate!.year} ${_pickupTime!.format(context)}'
                      : 'Select pickup date and time',
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _selectPickupDateTime,
              ),
            ),
            const SizedBox(height: 12),
            // Delivery time
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Delivery Date & Time'),
                subtitle: Text(
                  _deliveryDate != null && _deliveryTime != null
                      ? '${_deliveryDate!.day}/${_deliveryDate!.month}/${_deliveryDate!.year} ${_deliveryTime!.format(context)}'
                      : 'Select delivery date and time',
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _selectDeliveryDateTime,
              ),
            ),
            const SizedBox(height: 12),
            // Address
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Delivery Address',
                hintText: 'Enter delivery address',
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            // Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Subtotal', style: Theme.of(context).textTheme.bodyLarge),
                        Text('SAR ${totalPrice.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total', style: Theme.of(context).textTheme.titleMedium),
                        Text(
                          'SAR ${totalPrice.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Place order button
            AppButton(
              text: l10n.placeOrder,
              onPressed: _isPlacingOrder ? null : _placeOrder,
              isLoading: _isPlacingOrder,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, 2),
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/home');
            break;
          case 1:
            context.go('/orders');
            break;
          case 2:
            // Already on basket
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Orders'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_basket), label: 'Basket'),
      ],
    );
  }
}

