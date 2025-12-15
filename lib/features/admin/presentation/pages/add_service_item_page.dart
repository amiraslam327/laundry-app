import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:laundry_app/app/theme/app_theme.dart';
import 'package:laundry_app/features/common/presentation/widgets/app_button.dart';
import 'package:laundry_app/features/common/presentation/widgets/app_text_field.dart';
import 'package:laundry_app/features/common/domain/models/service_model.dart';

class AddServiceItemPage extends ConsumerStatefulWidget {
  const AddServiceItemPage({super.key});

  @override
  ConsumerState<AddServiceItemPage> createState() => _AddServiceItemPageState();
}

class _AddServiceItemPageState extends ConsumerState<AddServiceItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _minController = TextEditingController();
  final _maxController = TextEditingController();

  String? _selectedServiceId;
  bool _isLoading = false;

  @override
  void dispose() {
    _itemNameController.dispose();
    _priceController.dispose();
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  Future<void> _saveServiceItem() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedServiceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final itemId = const Uuid().v4();
      final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final min = int.tryParse(_minController.text.trim()) ?? 0;
      final max = int.tryParse(_maxController.text.trim()) ?? 0;

      if (max < min) {
        throw Exception('Max quantity must be greater than or equal to min');
      }

      await firestore
          .collection('services')
          .doc(_selectedServiceId)
          .collection('items')
          .doc(itemId)
          .set({
        'id': itemId,
        'name': _itemNameController.text.trim(),
        'price': price,
        'min': min,
        'max': max,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service item added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Clear form
        _itemNameController.clear();
        _priceController.clear();
        _minController.clear();
        _maxController.clear();
        _formKey.currentState?.reset();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving item: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get all services from all laundries
    final servicesAsync = ref.watch(
      StreamProvider((ref) {
        return FirebaseFirestore.instance
            .collection('services')
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => ServiceModel.fromMap(doc.data()))
                .toList());
      }),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Service Item'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Service Selection
              servicesAsync.when(
                data: (services) {
                  if (services.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Icon(Icons.info_outline, size: 48),
                            const SizedBox(height: 8),
                            const Text('No services available'),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => context.push('/admin/add-service'),
                              child: const Text('Add Service First'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return DropdownButtonFormField<String>(
                    value: _selectedServiceId,
                    decoration: const InputDecoration(
                      labelText: 'Select Service *',
                      prefixIcon: Icon(Icons.cleaning_services),
                      border: OutlineInputBorder(),
                    ),
                    items: services.map((service) {
                      return DropdownMenuItem<String>(
                        value: service.id,
                        child: Text('${service.name} (${service.laundryId})'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedServiceId = value);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a service';
                      }
                      return null;
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Text('Error loading services: $error'),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Item Name *',
                controller: _itemNameController,
                hint: 'e.g., Shirt, Pants, Kurta, Dress',
                prefixIcon: const Icon(Icons.inventory_2),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Price (SAR) *',
                controller: _priceController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.attach_money),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Min Quantity *',
                      controller: _minController,
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.remove),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      label: 'Max Quantity *',
                      controller: _maxController,
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.add),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Invalid';
                        }
                        final max = int.tryParse(value) ?? 0;
                        final min = int.tryParse(_minController.text) ?? 0;
                        if (max < min) {
                          return 'Must be >= min';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AppButton(
                text: 'Save Service Item',
                onPressed: _saveServiceItem,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

