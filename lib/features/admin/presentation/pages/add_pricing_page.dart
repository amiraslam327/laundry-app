import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laundry_app/app/theme/app_theme.dart';
import 'package:laundry_app/features/common/presentation/widgets/app_button.dart';
import 'package:laundry_app/features/common/presentation/widgets/app_text_field.dart';
import 'package:laundry_app/features/common/domain/models/service_model.dart';

class AddPricingPage extends ConsumerStatefulWidget {
  const AddPricingPage({super.key});

  @override
  ConsumerState<AddPricingPage> createState() => _AddPricingPageState();
}

class _AddPricingPageState extends ConsumerState<AddPricingPage> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  
  String? _selectedServiceId;
  bool _isLoading = false;

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _updatePricing() async {
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
      final price = double.tryParse(_priceController.text.trim()) ?? 0.0;

      await firestore.collection('services').doc(_selectedServiceId).update({
        'pricePerKg': price,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pricing updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _priceController.clear();
        setState(() => _selectedServiceId = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating pricing: $e')),
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
        title: const Text('Add/Update Pricing'),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(service.name),
                            Text(
                              'Current: SAR ${service.pricePerKg.toStringAsFixed(2)}/kg',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedServiceId = value;
                        if (value != null) {
                          final service = services.firstWhere((s) => s.id == value);
                          _priceController.text = service.pricePerKg.toStringAsFixed(2);
                        }
                      });
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
                label: 'New Price (SAR per kg) *',
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
              const SizedBox(height: 24),
              AppButton(
                text: 'Update Pricing',
                onPressed: _updatePricing,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

