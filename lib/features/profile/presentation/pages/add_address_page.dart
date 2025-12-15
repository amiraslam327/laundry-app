import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laundry_app/features/common/presentation/widgets/app_text_field.dart';
import 'package:laundry_app/features/common/presentation/widgets/app_button.dart';
import 'package:laundry_app/features/common/presentation/widgets/address_picker_widget.dart';
import 'package:laundry_app/features/common/data/repositories/sqlite_address_repository.dart';
import 'package:laundry_app/features/common/domain/models/sqlite_address_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';

class AddAddressPage extends ConsumerStatefulWidget {
  const AddAddressPage({super.key});

  @override
  ConsumerState<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends ConsumerState<AddAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _addressController = TextEditingController();
  LatLng? _selectedLocation;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an address')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final addressRepo = SqliteAddressRepository();
      final address = SqliteAddressModel(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        fullAddress: _addressController.text.trim(),
        lat: _selectedLocation?.latitude,
        lng: _selectedLocation?.longitude,
        createdAt: DateTime.now(),
      );

      await addressRepo.addAddress(address);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address added successfully')),
        );
        context.pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Address'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Title (e.g., Home, Work, Other)',
                controller: _titleController,
                prefixIcon: const Icon(Icons.label),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AddressPickerWidget(
                addressController: _addressController,
                initialLocation: _selectedLocation,
                onLocationSelected: (location) {
                  setState(() {
                    _selectedLocation = location;
                  });
                },
                label: 'Full Address',
                required: true,
              ),
              const SizedBox(height: 32),
              AppButton(
                text: 'Save Address',
                onPressed: _isSaving ? null : _saveAddress,
                isLoading: _isSaving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

