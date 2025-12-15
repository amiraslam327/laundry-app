import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:laundry_app/app/theme/app_theme.dart';
import 'package:laundry_app/features/common/presentation/providers/app_providers.dart';
import 'package:laundry_app/features/common/presentation/providers/providers.dart';
import 'package:laundry_app/features/common/presentation/widgets/loading_widget.dart';
import 'package:laundry_app/features/common/domain/models/basket_item_model.dart';
import 'package:laundry_app/features/common/domain/models/order_model.dart';
import 'package:laundry_app/features/common/domain/models/address_model.dart';
import 'package:laundry_app/features/common/domain/models/sqlite_address_model.dart';
import 'package:laundry_app/features/common/data/repositories/sqlite_address_repository.dart';
import 'package:laundry_app/features/common/domain/models/laundry_model.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  DateTime? _pickupDate;
  TimeOfDay? _pickupTime;
  DateTime? _deliveryDate;
  TimeOfDay? _deliveryTime;
  bool _isPlacingOrder = false;
  String _deliveryOption = 'home_delivery'; // 'home_delivery' or 'pickup'
  SqliteAddressModel? _selectedAddress; // Selected address for delivery
  final SqliteAddressRepository _sqliteAddressRepo = SqliteAddressRepository();
  bool _hasReceivedData = false; // Track if we've received data from stream
  bool _isInitialLoad = true; // Track initial load state

  @override
  void initState() {
    super.initState();
    _hasReceivedData = false; // Reset flag when page initializes
    _isInitialLoad = true;
    _loadSelectedAddress();
    
    // Set a timer to mark initial load as complete after a short delay
    // This prevents showing empty state immediately when stream emits
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isInitialLoad = false;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh address when page becomes visible again (e.g., returning from add address page)
    _loadSelectedAddress();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadSelectedAddress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      final selectedAddress = await _sqliteAddressRepo.getSelectedAddress();
      if (mounted) {
        setState(() {
          _selectedAddress = selectedAddress;
        });
      }
    } catch (e) {
      debugPrint('Error loading selected address: $e');
    }
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

  Future<void> _showDeliveryOptions(BuildContext context) async {
    // Navigate to address list page
    final result = await context.push<SqliteAddressModel>('/addresses/list');
    if (result != null && mounted) {
      setState(() {
        _selectedAddress = result;
      });
      await _sqliteAddressRepo.setSelectedAddress(result.id);
    } else if (mounted) {
      // If no address was selected but user might have added one, refresh
      await _loadSelectedAddress();
    }
  }

  Future<void> _showLaundrySelectionDialog(BuildContext context, WidgetRef ref) async {
    final laundriesAsync = ref.read(laundriesProvider);
    final selectedLaundry = ref.read(selectedLaundryProvider);
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Laundry'),
        content: SizedBox(
          width: double.maxFinite,
          child: laundriesAsync.when(
            data: (laundries) {
              if (laundries.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No laundries available'),
                  ),
                );
              }
              
              return ListView.builder(
                shrinkWrap: true,
                itemCount: laundries.length,
                itemBuilder: (context, index) {
                  final laundry = laundries[index];
                  final isSelected = selectedLaundry?.id == laundry.id;
                  
                  return ListTile(
                    leading: Icon(
                      Icons.local_laundry_service,
                      color: isSelected ? AppTheme.primaryBlue : Colors.grey,
                    ),
                    title: Text(laundry.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(laundry.address),
                        if (laundry.discountPercentage > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${laundry.discountPercentage}% OFF',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: AppTheme.primaryBlue)
                        : null,
                    onTap: () {
                      ref.read(selectedLaundryProvider.notifier).state = laundry;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${laundry.name} selected'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(height: 8),
                  Text('Error: $error'),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _validateAndShowOrderSummary(BuildContext context, List<BasketItemModel> items, WidgetRef ref) async {
    // Validate pickup date and time
    if (_pickupDate == null || _pickupTime == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select pickup date and time first'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Validate delivery date and time
    if (_deliveryDate == null || _deliveryTime == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select delivery date and time first'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // All validations passed, show order summary
    await _showOrderSummary(context, items, ref);
  }

  Future<void> _showOrderSummary(BuildContext context, List<BasketItemModel> items, WidgetRef ref) async {
    final dateFormat = DateFormat('MMM d, y');
    
    // Use selected laundry discount for all items
    final selectedLaundry = ref.read(selectedLaundryProvider);
    final appliedDiscount = selectedLaundry?.discountPercentage ?? 0;
    
    // Calculate prices with selected laundry discount
    double calculateItemPrice(BasketItemModel item) {
      final subtotal = item.subtotalPrice;
      final discount = subtotal * (appliedDiscount / 100);
      return subtotal - discount;
    }
    
    final subtotalPrice = items.fold(0.0, (sum, item) => sum + item.subtotalPrice);
    final totalPrice = items.fold(0.0, (sum, item) => sum + calculateItemPrice(item));
    final totalDiscount = subtotalPrice - totalPrice;

    // Group items by laundry
    final ordersByLaundry = <String, List<BasketItemModel>>{};
    for (final item in items) {
      ordersByLaundry.putIfAbsent(item.laundryId, () => []).add(item);
    }

    String selectedPaymentMethod = 'cod'; // Default to COD

    final confirmed = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          // Get user name and phone from provider
          final userAsync = ref.watch(userProvider);
          final userName = userAsync.when(
            data: (user) => user.fullName,
            loading: () => 'Loading...',
            error: (_, __) => 'Unknown User',
          );
          final userPhone = userAsync.when(
            data: (user) => user.phoneNumber,
            loading: () => '',
            error: (_, __) => '',
          );
          
          // Get fragrances for name lookup inside builder
          final fragrancesAsync = ref.watch(fragrancesProvider);
          final fragranceMap = fragrancesAsync.when(
            data: (fragrances) => {for (var f in fragrances) f.id: f.name},
            loading: () => <String, String>{},
            error: (_, __) => <String, String>{},
          );
          
          // Get selected laundry discount
          final selectedLaundry = ref.watch(selectedLaundryProvider);
          final appliedDiscount = selectedLaundry?.discountPercentage ?? 0;
          
          // Calculate item price with selected laundry discount
          double calculateItemPrice(BasketItemModel item) {
            final subtotal = item.subtotalPrice;
            final discount = subtotal * (appliedDiscount / 100);
            return subtotal - discount;
          }

          return StatefulBuilder(
            builder: (context, setState) => Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Order Summary',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context, null),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Name and Phone
                    Card(
                      color: Colors.blue[50],
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person, size: 20, color: AppTheme.primaryBlue),
                                const SizedBox(width: 8),
                                Text(
                                  'Customer: $userName',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryBlue,
                                      ),
                                ),
                              ],
                            ),
                            if (userPhone.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.phone, size: 18, color: AppTheme.primaryBlue),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Phone: $userPhone',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppTheme.primaryBlue,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Order Items
                    Text(
                      'Order Items',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    ...ordersByLaundry.entries.expand((entry) {
                      final laundryItems = entry.value;
                      return [
                        // Laundry header
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Laundry: ${laundryItems.first.laundryName ?? "Unknown"}',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryBlue,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Laundry ID: ${laundryItems.first.laundryId}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ],
                          ),
                        ),
                        // Items for this laundry
                        ...laundryItems.map((item) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.serviceName,
                                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                        Builder(
                                          builder: (context) {
                                            // Use selected laundry discount for this item
                                            final appliedDiscount = selectedLaundry?.discountPercentage ?? 0;
                                            final itemSubtotal = item.subtotalPrice;
                                            final itemDiscount = itemSubtotal * (appliedDiscount / 100);
                                            final itemTotal = itemSubtotal - itemDiscount;
                                            
                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                if (appliedDiscount > 0) ...[
                                                  Text(
                                                    'SAR ${itemSubtotal.toStringAsFixed(2)}',
                                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                          decoration: TextDecoration.lineThrough,
                                                          color: Colors.grey,
                                                        ),
                                                  ),
                                                  Text(
                                                    'SAR ${itemTotal.toStringAsFixed(2)}',
                                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                          color: Colors.green,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                  ),
                                                  Text(
                                                    '${appliedDiscount}% OFF',
                                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                          color: Colors.green,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                  ),
                                                ] else ...[
                                                  Text(
                                                    'SAR ${itemTotal.toStringAsFixed(2)}',
                                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                          color: AppTheme.primaryBlue,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                  ),
                                                ],
                                              ],
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    // Service Category and Item Name
                                    if (item.notes != null && item.notes!.isNotEmpty) ...[
                                      Text(
                                        'Item Name: ${item.notes}',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                    ],
                                    Text(
                                      'Service Category: ${item.serviceName}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.grey[700],
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Quantity: ${item.quantity.toInt()} pieces',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 4),
                                    // Fragrance (always show if available)
                                    if (item.fragranceId != null && item.fragranceId!.isNotEmpty) ...[
                                      Text(
                                        'Fragrance: ${fragranceMap[item.fragranceId] ?? item.fragranceId}',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ] else ...[
                                      Text(
                                        'Fragrance: Not selected',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Colors.grey[400],
                                              fontStyle: FontStyle.italic,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            )),
                        const SizedBox(height: 12),
                      ];
                    }),
                    const Divider(),
                    const SizedBox(height: 16),
                    // Delivery Address
                    Text(
                      'Delivery Address',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    if (_selectedAddress != null)
                      Card(
                        color: Colors.grey[50],
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.location_on, size: 20, color: AppTheme.primaryBlue),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedAddress!.title,
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.only(left: 28),
                                child: Text(
                                  _selectedAddress!.fullAddress,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Pickup & Delivery Times
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pickup Time',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              if (_pickupDate != null && _pickupTime != null)
                                Text(
                                  '${dateFormat.format(_pickupDate!)} at ${_pickupTime!.format(context)}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                )
                              else
                                Text(
                                  'Not selected',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey,
                                      ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Delivery Time',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              if (_deliveryDate != null && _deliveryTime != null)
                                Text(
                                  '${dateFormat.format(_deliveryDate!)} at ${_deliveryTime!.format(context)}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                )
                              else
                                Text(
                                  'Not selected',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey,
                                      ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    // Payment Method
                    Text(
                      'Payment Method',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    // COD Option
                    Card(
                      color: selectedPaymentMethod == 'cod' 
                          ? AppTheme.primaryBlue.withOpacity(0.1)
                          : Colors.white,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            selectedPaymentMethod = 'cod';
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Radio<String>(
                                value: 'cod',
                                groupValue: selectedPaymentMethod,
                                onChanged: (value) {
                                  setState(() {
                                    selectedPaymentMethod = value!;
                                  });
                                },
                                activeColor: AppTheme.primaryBlue,
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.money,
                                color: selectedPaymentMethod == 'cod' 
                                    ? AppTheme.primaryBlue 
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Cash on Delivery',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(
                                      'Pay when you receive your order',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              if (selectedPaymentMethod == 'cod')
                                Icon(
                                  Icons.check_circle,
                                  color: AppTheme.primaryBlue,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Online Payment Option
                    Card(
                      color: selectedPaymentMethod == 'online' 
                          ? AppTheme.primaryBlue.withOpacity(0.1)
                          : Colors.white,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            selectedPaymentMethod = 'online';
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Radio<String>(
                                value: 'online',
                                groupValue: selectedPaymentMethod,
                                onChanged: (value) {
                                  setState(() {
                                    selectedPaymentMethod = value!;
                                  });
                                },
                                activeColor: AppTheme.primaryBlue,
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.payment,
                                color: selectedPaymentMethod == 'online' 
                                    ? AppTheme.primaryBlue 
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Online Payment',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(
                                      'Pay securely with card or wallet',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              if (selectedPaymentMethod == 'online')
                                Icon(
                                  Icons.check_circle,
                                  color: AppTheme.primaryBlue,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    // Price Summary
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subtotal',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(
                          'SAR ${subtotalPrice.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                    if (totalDiscount > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Discount',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.green,
                                ),
                          ),
                          Text(
                            '-SAR ${totalDiscount.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'SAR ${totalPrice.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Footer buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, null),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppTheme.primaryBlue),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, {
                        'confirmed': true,
                        'paymentMethod': selectedPaymentMethod,
                      }),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.primaryBlue,
                      ),
                      child: const Text(
                        'Confirm Order',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
        },
      ),
    );

    if (confirmed != null && confirmed['confirmed'] == true) {
      await _placeOrder(paymentMethod: confirmed['paymentMethod'] ?? 'cod');
    }
  }

  Future<void> _placeOrder({String paymentMethod = 'cod'}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) context.push('/login');
      return;
    }

    // Validate selected laundry
    final selectedLaundry = ref.read(selectedLaundryProvider);
    if (selectedLaundry == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a laundry first'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (_pickupDate == null || _pickupTime == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select pickup date and time')),
        );
      }
      return;
    }

    if (_deliveryDate == null || _deliveryTime == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select delivery date and time')),
        );
      }
      return;
    }

    // Validate delivery address
    if (_selectedAddress == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a delivery address')),
        );
      }
      return;
    }

    setState(() => _isPlacingOrder = true);

    // Show loading dialog using rootNavigator to show above all dialogs
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Placing your order...'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    try {
      final cartRepo = ref.read(cartRepositoryProvider);
      final cartItems = await cartRepo.getCartItems(user.uid).first.timeout(
            const Duration(seconds: 10),
            onTimeout: () => <BasketItemModel>[],
          );

      if (cartItems.isEmpty) {
        throw Exception('Cart is empty');
      }

      // Group items by laundry
      final ordersByLaundry = <String, List<BasketItemModel>>{};
      for (final item in cartItems) {
        ordersByLaundry.putIfAbsent(item.laundryId, () => []).add(item);
      }

      // Use selected laundry discount for all items (already validated above)
      final selectedLaundry = ref.read(selectedLaundryProvider)!;
      final appliedDiscount = selectedLaundry.discountPercentage;
      
      // Calculate item price with selected laundry discount
      double calculateItemPrice(BasketItemModel item) {
        final subtotal = item.subtotalPrice;
        final discount = subtotal * (appliedDiscount / 100);
        return subtotal - discount;
      }

      final ordersRepo = ref.read(ordersRepositoryProvider);
      String? firstOrderId;

      // Get fragrances to map ID to name
      final fragrancesAsync = ref.read(fragrancesProvider);
      final fragranceMap = fragrancesAsync.when(
        data: (fragrances) => {for (var f in fragrances) f.id: f.name},
        loading: () => <String, String>{},
        error: (_, __) => <String, String>{},
      );

      for (final entry in ordersByLaundry.entries) {
        final items = entry.value;
        final subtotalPrice = items.fold(0.0, (sum, item) => sum + item.subtotalPrice);
        final totalPrice = items.fold(0.0, (sum, item) => sum + calculateItemPrice(item));
        final totalDiscount = subtotalPrice - totalPrice;
        final fragranceId = items.firstWhere((item) => item.fragranceId != null,
            orElse: () => items.first).fragranceId;
        
        // Get fragrance name from ID
        final fragranceName = fragranceId != null ? fragranceMap[fragranceId] : null;

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

        // Get user details for order
        final userAsync = ref.read(userProvider);
        final userModel = userAsync.valueOrNull;
        final orderUserName = userModel?.fullName;
        final orderUserPhone = userModel?.phoneNumber;

        final order = OrderModel(
          id: const Uuid().v4(),
          userId: user.uid,
          laundryId: selectedLaundry.id, // Use selected laundry ID
          status: OrderStatus.pending,
          items: items.map((item) => OrderItem(
            serviceId: item.serviceId,
            serviceName: item.serviceName,
            itemName: item.notes, // Save item name from notes field
            quantity: item.quantity,
            price: calculateItemPrice(item), // Use calculated price with discount
          )).toList(),
          fragranceId: fragranceId, // Keep for backward compatibility
          fragranceName: fragranceName, // Save fragrance name instead of ID
          userName: orderUserName, // Save user name
          userPhoneNumber: orderUserPhone, // Save user phone number
          discountPercentage: appliedDiscount.toDouble(),
          discountAmount: totalDiscount,
          pickupTime: pickupDateTime,
          deliveryTime: deliveryDateTime,
          totalPrice: totalPrice,
          createdAt: DateTime.now(),
          notes: 'Delivery Information:\n'
              'Title: ${_selectedAddress!.title}\n'
              'Address: ${_selectedAddress!.fullAddress}\n\n'
              'Laundry Information:\n'
              'Name: ${selectedLaundry.name}\n'
              'Address: ${selectedLaundry.address}\n'
              'Discount: ${selectedLaundry.discountPercentage}%',
        );

        final orderId = await ordersRepo.placeOrder(
          order: order,
          userId: user.uid,
          paymentMethod: paymentMethod,
          paymentStatus: paymentMethod == 'cod' ? 'pending' : 'pending',
          clearCartAfterOrder: false, // Don't clear cart yet, we'll clear after all orders are placed
        );

        if (firstOrderId == null) {
          firstOrderId = orderId;
        }
      }

      // Clear cart after all orders are successfully placed
      if (firstOrderId != null) {
        await cartRepo.clearCart(user.uid);
      }

      if (mounted && firstOrderId != null) {
        // Close loading dialog
        Navigator.of(context, rootNavigator: true).pop();
        context.go('/order/success/$firstOrderId');
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog
        Navigator.of(context, rootNavigator: true).pop();
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cart')),
        body: const Center(
          child: Text('Please login to view cart'),
        ),
      );
    }

    final cartAsync = ref.watch(cartProvider(user.uid));
    final fragrancesAsync = ref.watch(fragrancesProvider);
    final fragranceMap = fragrancesAsync.when(
      data: (fragrances) => {for (var f in fragrances) f.id: f.name},
      loading: () => <String, String>{},
      error: (_, __) => <String, String>{},
    );
    final dateFormat = DateFormat('MMM d, y');
    final selectedLaundry = ref.watch(selectedLaundryProvider);
    
    // Apply selected laundry discount to all items when laundry changes
    ref.listen<LaundryModel?>(selectedLaundryProvider, (previous, next) {
      if (next != null && previous?.id != next.id) {
        // Selected laundry changed, update all cart items with new discount
        final cartRepo = ref.read(cartRepositoryProvider);
        cartRepo.updateDiscountForAllItems(user.uid, next.discountPercentage).catchError((e) {
          debugPrint('Error updating discounts: $e');
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
      ),
      body: cartAsync.when(
        data: (items) {
          // Mark that we've received data
          if (!_hasReceivedData) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _hasReceivedData = true;
                });
              }
            });
          }

          // Show loading during initial load or if we haven't received data yet
          if (_isInitialLoad || (!_hasReceivedData && items.isEmpty)) {
            return const LoadingWidget();
          }

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 100,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add items to get started',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Browse Services'),
                  ),
                ],
              ),
            );
          }

          // Use selected laundry discount for all items
          final appliedDiscount = selectedLaundry?.discountPercentage ?? 0;
          
          // Calculate prices with selected laundry discount
          double calculateItemPrice(BasketItemModel item) {
            final subtotal = item.subtotalPrice;
            final discount = subtotal * (appliedDiscount / 100);
            return subtotal - discount;
          }
          
          final subtotalPrice = items.fold(0.0, (sum, item) => sum + item.subtotalPrice);
          final totalPrice = items.fold(0.0, (sum, item) => sum + calculateItemPrice(item));
          final totalDiscount = subtotalPrice - totalPrice;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selected Laundry Section
                Card(
                  color: selectedLaundry != null 
                      ? AppTheme.primaryBlue.withOpacity(0.1) 
                      : Colors.orange.withOpacity(0.1),
                  child: InkWell(
                    onTap: () => _showLaundrySelectionDialog(context, ref),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_laundry_service, 
                            color: selectedLaundry != null 
                                ? AppTheme.primaryBlue 
                                : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedLaundry != null 
                                      ? 'Selected Laundry' 
                                      : 'Select Laundry (Required)',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: selectedLaundry != null 
                                            ? AppTheme.primaryBlue 
                                            : Colors.orange,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  selectedLaundry != null 
                                      ? selectedLaundry.name 
                                      : 'Tap to select a laundry',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: selectedLaundry != null 
                                            ? null 
                                            : Colors.orange[700],
                                      ),
                                ),
                              ],
                            ),
                          ),
                          if (selectedLaundry != null && selectedLaundry.discountPercentage > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${selectedLaundry.discountPercentage}% OFF',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Cart Items
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Top row: Item name and price
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Item name (from notes field)
                                      Text(
                                        item.notes ?? 'Item',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      // Service category name
                                      Text(
                                        item.serviceName,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Builder(
                                  builder: (context) {
                                    // Use selected laundry discount for this item
                                    final appliedDiscount = selectedLaundry?.discountPercentage ?? 0;
                                    final itemSubtotal = item.subtotalPrice;
                                    final itemDiscount = itemSubtotal * (appliedDiscount / 100);
                                    final itemTotal = itemSubtotal - itemDiscount;
                                    
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        if (appliedDiscount > 0) ...[
                                          Text(
                                            'SAR ${itemSubtotal.toStringAsFixed(2)}',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  decoration: TextDecoration.lineThrough,
                                                  color: Colors.grey,
                                                ),
                                          ),
                                          Text(
                                            'SAR ${itemTotal.toStringAsFixed(2)}',
                                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ] else ...[
                                          Text(
                                            'SAR ${itemTotal.toStringAsFixed(2)}',
                                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                  color: AppTheme.primaryBlue,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Laundry name and discount row (use selected laundry)
                            Builder(
                              builder: (context) {
                                final appliedDiscount = selectedLaundry?.discountPercentage ?? 0;
                                final displayLaundryName = selectedLaundry?.name ?? item.laundryName;
                                
                                if (displayLaundryName.isEmpty && appliedDiscount == 0) {
                                  return const SizedBox.shrink();
                                }
                                
                                return Row(
                                  children: [
                                    if (displayLaundryName.isNotEmpty) ...[
                                      Icon(Icons.local_laundry_service, size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        displayLaundryName,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Colors.grey[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ],
                                    if (appliedDiscount > 0 && displayLaundryName.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '•',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Colors.grey,
                                            ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    if (appliedDiscount > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.green,
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          '${appliedDiscount}% OFF',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Colors.green[700],
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            // Middle row: Quantity and fragrance
                            Row(
                              children: [
                                Text(
                                  '${item.quantity.toInt()} pieces',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                if (item.fragranceId != null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '• Fragrance: ${fragranceMap[item.fragranceId] ?? item.fragranceId}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.grey,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Bottom row: Action buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: item.quantity > 0
                                        ? () async {
                                            final newQuantity = (item.quantity - 1).toInt();
                                            if (newQuantity > 0) {
                                              final cartRepo = ref.read(cartRepositoryProvider);
                                              await cartRepo.updateQuantity(
                                                user.uid,
                                                item.id,
                                                newQuantity.toDouble(),
                                              );
                                            } else {
                                              // If quantity becomes 0, remove item
                                              final cartRepo = ref.read(cartRepositoryProvider);
                                              await cartRepo.removeItem(user.uid, item.id);
                                            }
                                          }
                                        : null,
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: item.quantity > 0
                                            ? AppTheme.primaryBlue.withOpacity(0.1)
                                            : Colors.grey.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.remove,
                                        size: 18,
                                        color: item.quantity > 0
                                            ? AppTheme.primaryBlue
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  item.quantity.toInt().toString(),
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(width: 8),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () async {
                                      final cartRepo = ref.read(cartRepositoryProvider);
                                      await cartRepo.updateQuantity(
                                        user.uid,
                                        item.id,
                                        item.quantity + 1,
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryBlue.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.add,
                                        size: 18,
                                        color: AppTheme.primaryBlue,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () async {
                                      final cartRepo = ref.read(cartRepositoryProvider);
                                      await cartRepo.removeItem(user.uid, item.id);
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Pickup Time
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Pickup Date & Time'),
                    subtitle: Text(
                      _pickupDate != null && _pickupTime != null
                          ? '${dateFormat.format(_pickupDate!)} at ${_pickupTime!.format(context)}'
                          : 'Select pickup date and time',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _selectPickupDateTime,
                  ),
                ),
                const SizedBox(height: 12),
                // Delivery Time
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Delivery Date & Time'),
                    subtitle: Text(
                      _deliveryDate != null && _deliveryTime != null
                          ? '${dateFormat.format(_deliveryDate!)} at ${_deliveryTime!.format(context)}'
                          : 'Select delivery date and time',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _selectDeliveryDateTime,
                  ),
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
                            Text('SAR ${subtotalPrice.toStringAsFixed(2)}'),
                          ],
                        ),
                        if (totalDiscount > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Discount',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.green,
                                    ),
                              ),
                              Text(
                                '-SAR ${totalDiscount.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              'SAR ${totalPrice.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppTheme.primaryBlue,
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
                // Delivery Address Section
                Text(
                  'Delivery Address',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                // Add Address Button (if no address selected)
                if (_selectedAddress == null)
                  Card(
                    child: InkWell(
                      onTap: () async {
                        // Navigate to address list page (which has add button)
                        await context.push<SqliteAddressModel>('/addresses/list');
                        if (mounted) {
                          // Refresh selected address after returning using setState
                          await _loadSelectedAddress();
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.add_location_alt, color: AppTheme.primaryBlue),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Add Delivery Address',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Select or add an address for delivery',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Selected Address Display
                if (_selectedAddress != null)
                  Card(
                    color: AppTheme.primaryBlue.withOpacity(0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on, color: AppTheme.primaryBlue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedAddress!.title,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () async {
                                  await _showDeliveryOptions(context);
                                  // Refresh address after selection using setState
                                  if (mounted) {
                                    await _loadSelectedAddress();
                                  }
                                },
                                tooltip: 'Change Address',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 32),
                            child: Text(
                              _selectedAddress!.fullAddress,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                // Place Order Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_isPlacingOrder || _selectedAddress == null || selectedLaundry == null)
                        ? null
                        : () => _validateAndShowOrderSummary(context, items, ref),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.primaryBlue,
                    ),
                    child: _isPlacingOrder
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Place Order',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const LoadingWidget(),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(cartProvider(user.uid));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
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
            // Already on cart
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Orders'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_basket), label: 'Cart'),
      ],
    );
  }
}

