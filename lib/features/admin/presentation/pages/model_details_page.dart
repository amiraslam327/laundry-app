import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:laundry_app/app/theme/app_theme.dart';
import 'package:laundry_app/features/common/presentation/widgets/app_button.dart';
import 'package:laundry_app/features/common/presentation/widgets/app_text_field.dart';
import 'package:laundry_app/features/common/domain/models/service_model.dart';
import 'package:laundry_app/features/common/domain/models/service_item.dart';
import 'package:laundry_app/features/common/presentation/providers/app_providers.dart';

class ModelDetailsPage extends ConsumerStatefulWidget {
  final String modelType; // 'laundry', 'service', 'serviceItem', 'order'

  const ModelDetailsPage({
    super.key,
    this.modelType = 'laundry',
  });

  @override
  ConsumerState<ModelDetailsPage> createState() => _ModelDetailsPageState();
}

class _ModelDetailsPageState extends ConsumerState<ModelDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  String? _selectedLaundryId;
  String? _selectedServiceId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    switch (widget.modelType) {
      case 'laundry':
        _controllers['name'] = TextEditingController();
        _controllers['description'] = TextEditingController();
        _controllers['address'] = TextEditingController();
        _controllers['phone'] = TextEditingController();
        _controllers['rating'] = TextEditingController(text: '0.0');
        _controllers['minOrderAmount'] = TextEditingController(text: '0.0');
        _controllers['discountPercentage'] = TextEditingController(text: '0');
        _controllers['logoUrl'] = TextEditingController();
        _controllers['bannerImageUrl'] = TextEditingController();
        _controllers['workingHours'] = TextEditingController();
        break;
      case 'service':
        _controllers['name'] = TextEditingController();
        _controllers['description'] = TextEditingController();
        _controllers['pricePerKg'] = TextEditingController();
        _controllers['estimatedHours'] = TextEditingController();
        break;
      case 'serviceItem':
        _controllers['name'] = TextEditingController();
        _controllers['price'] = TextEditingController();
        _controllers['min'] = TextEditingController(text: '0');
        _controllers['max'] = TextEditingController(text: '50');
        break;
      case 'order':
        _controllers['totalPrice'] = TextEditingController();
        _controllers['notes'] = TextEditingController();
        break;
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveModel() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final modelId = const Uuid().v4();

      switch (widget.modelType) {
        case 'laundry':
          if (_selectedLaundryId == null) {
            throw Exception('Please select a laundry');
          }
          await _saveLaundry(firestore, modelId);
          break;
        case 'service':
          if (_selectedLaundryId == null) {
            throw Exception('Please select a laundry');
          }
          await _saveService(firestore, modelId);
          break;
        case 'serviceItem':
          if (_selectedServiceId == null) {
            throw Exception('Please select a service');
          }
          await _saveServiceItem(firestore, modelId);
          break;
        case 'order':
          await _saveOrder(firestore, modelId);
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.modelType} saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveLaundry(FirebaseFirestore firestore, String id) async {
    final laundryData = {
      'id': id,
      'name': _controllers['name']!.text.trim(),
      'description': _controllers['description']!.text.trim(),
      'address': _controllers['address']!.text.trim(),
      'rating': double.tryParse(_controllers['rating']?.text ?? '0.0') ?? 0.0,
      'minOrderAmount': double.tryParse(_controllers['minOrderAmount']?.text ?? '0.0') ?? 0.0,
      'discountPercentage': int.tryParse(_controllers['discountPercentage']?.text ?? '0') ?? 0,
      'isPreferred': false,
      'logoUrl': _controllers['logoUrl']?.text.trim().isEmpty ?? true
          ? null
          : _controllers['logoUrl']!.text.trim(),
      'bannerImageUrl': _controllers['bannerImageUrl']?.text.trim().isEmpty ?? true
          ? null
          : _controllers['bannerImageUrl']!.text.trim(),
    };
    
    // Add optional fields if they exist
    if (_controllers.containsKey('phone') && _controllers['phone']!.text.isNotEmpty) {
      laundryData['phone'] = _controllers['phone']!.text.trim();
    }
    if (_controllers.containsKey('workingHours') && _controllers['workingHours']!.text.isNotEmpty) {
      laundryData['workingHours'] = _controllers['workingHours']!.text.trim();
    }
    
    await firestore.collection('laundries').doc(id).set(laundryData);
  }

  Future<void> _saveService(FirebaseFirestore firestore, String id) async {
    final service = ServiceModel(
      id: id,
      laundryId: _selectedLaundryId!,
      name: _controllers['name']!.text.trim(),
      description: _controllers['description']!.text.trim(),
      pricePerKg: double.tryParse(_controllers['pricePerKg']!.text) ?? 0.0,
      estimatedHours: int.tryParse(_controllers['estimatedHours']!.text) ?? 0,
    );
    await firestore.collection('services').doc(id).set(service.toMap());
  }

  Future<void> _saveServiceItem(FirebaseFirestore firestore, String id) async {
    final item = ServiceItem(
      id: id,
      name: _controllers['name']!.text.trim(),
      price: double.tryParse(_controllers['price']!.text) ?? 0.0,
      min: int.tryParse(_controllers['min']!.text) ?? 0,
      max: int.tryParse(_controllers['max']!.text) ?? 0,
    );
    await firestore
        .collection('services')
        .doc(_selectedServiceId)
        .collection('items')
        .doc(id)
        .set(item.toMap());
  }

  Future<void> _saveOrder(FirebaseFirestore firestore, String id) async {
    // Order creation requires user context, so this is a simplified version
    // In real app, you'd need userId, items, etc.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order creation requires user context')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add ${widget.modelType.toUpperCase()}'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (type) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ModelDetailsPage(modelType: type),
                ),
              );
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'laundry', child: Text('Laundry')),
              const PopupMenuItem(value: 'service', child: Text('Service')),
              const PopupMenuItem(value: 'serviceItem', child: Text('Service Item')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.modelType == 'service' || widget.modelType == 'serviceItem')
                _buildLaundryDropdown() ?? const SizedBox.shrink(),
              if (widget.modelType == 'serviceItem') ...[
                const SizedBox(height: 16),
                _buildServiceDropdown() ?? const SizedBox.shrink(),
              ],
              ..._buildFormFields(),
              const SizedBox(height: 24),
              AppButton(
                text: 'Save ${widget.modelType.toUpperCase()}',
                onPressed: _saveModel,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildLaundryDropdown() {
    final laundriesAsync = ref.watch(laundriesProvider);

    return laundriesAsync.when(
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
      error: (error, stack) => Text('Error: $error'),
    );
  }

  Widget? _buildServiceDropdown() {
    if (_selectedLaundryId == null) return null;

    final servicesAsync = ref.watch(servicesProvider(_selectedLaundryId!));

    return servicesAsync.when(
      data: (services) {
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
              child: Text(service.name),
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
      error: (error, stack) => Text('Error: $error'),
    );
  }

  List<Widget> _buildFormFields() {
    final fields = <Widget>[];

    _controllers.forEach((key, controller) {
      if (key == 'name' || key == 'description') {
        fields.addAll([
          const SizedBox(height: 16),
          AppTextField(
            label: key.toUpperCase() + ' *',
            controller: controller,
            maxLines: key == 'description' ? 3 : 1,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter $key';
              }
              return null;
            },
          ),
        ]);
      } else if (key.contains('Url')) {
        fields.addAll([
          const SizedBox(height: 16),
          AppTextField(
            label: key,
            controller: controller,
            hint: 'Optional URL',
          ),
        ]);
      } else {
        fields.addAll([
          const SizedBox(height: 16),
          AppTextField(
            label: key.toUpperCase(),
            controller: controller,
            hint: key.contains('Url') ? 'Optional URL' : null,
            keyboardType: key.contains('price') || key.contains('amount') || key.contains('rating')
                ? TextInputType.number
                : key.contains('hours') || key.contains('min') || key.contains('max')
                    ? TextInputType.number
                    : null,
            validator: (value) {
              if (key == 'name' && (value == null || value.isEmpty)) {
                return 'Required';
              }
              if (key.contains('price') || key.contains('amount') || key.contains('rating')) {
                if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                  return 'Invalid number';
                }
              }
              if (key.contains('hours') || key.contains('min') || key.contains('max')) {
                if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
                  return 'Invalid number';
                }
              }
              return null;
            },
          ),
        ]);
      }
    });

    return fields;
  }
}

