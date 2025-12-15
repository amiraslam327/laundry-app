import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:laundry_app/app/theme/app_theme.dart';
import 'package:laundry_app/features/common/presentation/widgets/app_button.dart';
import 'package:laundry_app/features/common/presentation/widgets/app_text_field.dart';
import 'package:laundry_app/features/common/presentation/providers/app_providers.dart';

class AddServicePage extends ConsumerStatefulWidget {
  const AddServicePage({super.key});

  @override
  ConsumerState<AddServicePage> createState() => _AddServicePageState();
}

class _AddServicePageState extends ConsumerState<AddServicePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _iconController = TextEditingController();

  String? _selectedLaundryId;
  String _priceType = 'per_kg';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLaundryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a laundry')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final serviceId = const Uuid().v4();
      final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final duration = int.tryParse(_durationController.text.trim()) ?? 0;

      await firestore.collection('services').doc(serviceId).set({
        'id': serviceId,
        'laundryId': _selectedLaundryId,
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'priceType': _priceType,
        'pricePerKg': _priceType == 'per_kg' ? price : 0.0,
        'pricePerPiece': _priceType == 'per_piece' ? price : 0.0,
        'estimatedHours': duration,
        'icon': _iconController.text.trim().isEmpty 
            ? null 
            : _iconController.text.trim(),
        'isPopular': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving service: $e')),
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
    final laundriesAsync = ref.watch(laundriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Service'),
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
              // Laundry Selection
              laundriesAsync.when(
                data: (laundries) {
                  return DropdownButtonFormField<String>(
                    value: _selectedLaundryId,
                    decoration: const InputDecoration(
                      labelText: 'Select Laundry *',
                      prefixIcon: Icon(Icons.local_laundry_service),
                      border: OutlineInputBorder(),
                    ),
                    items: laundries.map((laundry) {
                      return DropdownMenuItem<String>(
                        value: laundry.id,
                        child: Text(laundry.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedLaundryId = value);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a laundry';
                      }
                      return null;
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Text('Error loading laundries: $error'),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Service Name *',
                controller: _nameController,
                hint: 'e.g., Shop, Dry Clean, Wash, Iron, Fold',
                prefixIcon: const Icon(Icons.cleaning_services),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter service name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Description *',
                controller: _descriptionController,
                maxLines: 3,
                prefixIcon: const Icon(Icons.description),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Price Type Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Price Type *',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Per Kg'),
                              value: 'per_kg',
                              groupValue: _priceType,
                              onChanged: (value) {
                                setState(() => _priceType = value!);
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Per Piece'),
                              value: 'per_piece',
                              groupValue: _priceType,
                              onChanged: (value) {
                                setState(() => _priceType = value!);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
              AppTextField(
                label: 'Duration (hours) *',
                controller: _durationController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.access_time),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter duration';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Icon (optional)',
                controller: _iconController,
                hint: 'e.g., assets/icons/wash.png',
                prefixIcon: const Icon(Icons.image),
              ),
              const SizedBox(height: 24),
              AppButton(
                text: 'Save Service',
                onPressed: _saveService,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

