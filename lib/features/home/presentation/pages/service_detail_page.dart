import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laundry_app/app/theme/app_theme.dart';
import 'package:laundry_app/features/common/presentation/providers/app_providers.dart';
import 'package:laundry_app/features/common/presentation/widgets/loading_widget.dart';
import 'package:laundry_app/features/common/domain/models/service_model.dart';
import 'package:laundry_app/features/common/domain/models/basket_item_model.dart';
import 'package:laundry_app/features/common/presentation/providers/providers.dart';
import 'package:uuid/uuid.dart';

class ServiceDetailPage extends ConsumerStatefulWidget {
  final String serviceId;

  const ServiceDetailPage({
    super.key,
    required this.serviceId,
  });

  @override
  ConsumerState<ServiceDetailPage> createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends ConsumerState<ServiceDetailPage> {
  double _quantity = 1.0;
  String? _selectedFragranceId;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load selected fragrance from global state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedFragrance = ref.read(selectedFragranceProvider);
      if (selectedFragrance != null) {
        setState(() {
          _selectedFragranceId = selectedFragrance;
        });
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _addToCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add items to cart')),
      );
      context.push('/login');
      return;
    }

    try {
      final servicesRepo = ref.read(servicesRepositoryProvider);
      final service = await servicesRepo.getService(widget.serviceId);
      if (service == null) {
        throw Exception('Service not found');
      }

      final laundriesRepo = ref.read(laundriesRepositoryProvider);
      final laundry = await laundriesRepo.getLaundry(service.laundryId);
      if (laundry == null) {
        throw Exception('Laundry not found');
      }

      final cartRepo = ref.read(cartRepositoryProvider);
      
      // Use selected fragrance from global state if local selection is null
      final fragranceId = _selectedFragranceId ?? ref.read(selectedFragranceProvider);
      
      // Get discount from selected laundry if this laundry is selected, otherwise use laundry's discount
      final selectedLaundry = ref.read(selectedLaundryProvider);
      final discountPercentage = (selectedLaundry?.id == laundry.id)
          ? selectedLaundry!.discountPercentage
          : laundry.discountPercentage;
      
      final basketItem = BasketItemModel(
        id: const Uuid().v4(),
        serviceId: service.id,
        serviceName: service.name,
        laundryId: laundry.id,
        laundryName: laundry.name,
        quantity: _quantity,
        pricePerKg: service.pricePerKg,
        fragranceId: fragranceId, // Use selected fragrance from home or local selection
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        discountPercentage: discountPercentage, // Use selected laundry discount or laundry's discount
      );

      await cartRepo.addItemToCart(user.uid, basketItem);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added to cart')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use StreamProvider to get service from Firestore directly
    final serviceAsync = ref.watch(
      StreamProvider.autoDispose((ref) {
        return FirebaseFirestore.instance
            .collection('services')
            .doc(widget.serviceId)
            .snapshots()
            .map((doc) {
          if (!doc.exists) {
            throw Exception('Service not found');
          }
          try {
            return ServiceModel.fromMap(doc.data()!);
          } catch (e) {
            debugPrint('Error parsing service: $e');
            throw Exception('Invalid service data');
          }
        });
      }),
    );

    final fragrancesAsync = ref.watch(fragrancesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Details'),
      ),
      body: serviceAsync.when(
        data: (service) {
          if (service == null) {
            return const Center(child: Text('Service not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service Info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          service.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'SAR ${service.pricePerKg.toStringAsFixed(2)} per kg',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 16),
                            const SizedBox(width: 4),
                            Text('Estimated: ${service.estimatedHours} hours'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Quantity Selector
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quantity (kg)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                if (_quantity > 0.5) {
                                  setState(() => _quantity -= 0.5);
                                }
                              },
                            ),
                            Expanded(
                              child: Text(
                                '${_quantity.toStringAsFixed(1)} kg',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                setState(() => _quantity += 0.5);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total: SAR ${(_quantity * service.pricePerKg).toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Fragrance Selection
                fragrancesAsync.when(
                  data: (fragrances) {
                    if (fragrances.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Fragrance',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: fragrances.map((fragrance) {
                                final isSelected = _selectedFragranceId == fragrance.id;
                                return FilterChip(
                                  label: Text(fragrance.name),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedFragranceId = selected ? fragrance.id : null;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),
                // Notes
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Special Instructions (Optional)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Add any special instructions...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Add to Cart Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addToCart,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Add to Cart'),
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
            ],
          ),
        ),
      ),
    );
  }
}

