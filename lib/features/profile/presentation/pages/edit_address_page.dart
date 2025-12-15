import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:laundry_app/features/common/presentation/providers/providers.dart';
import 'package:laundry_app/features/common/domain/models/address_model.dart';
import 'package:laundry_app/features/common/presentation/widgets/app_button.dart';
import 'package:laundry_app/features/common/presentation/widgets/app_text_field.dart';
import 'package:laundry_app/features/common/presentation/widgets/address_picker_widget.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class EditAddressPage extends ConsumerStatefulWidget {
  final AddressModel? address; // null for add, non-null for edit

  const EditAddressPage({super.key, this.address});

  @override
  ConsumerState<EditAddressPage> createState() => _EditAddressPageState();
}

class _EditAddressPageState extends ConsumerState<EditAddressPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  
  LatLng? _selectedLocation;
  bool _isDefault = false;
  bool _isSaving = false;
  String _countryCode = '+966';
  String _phoneNumber = '';
  String _initialCountryCode = 'SA';

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with existing data if editing
    _labelController = TextEditingController(text: widget.address?.label ?? '');
    _nameController = TextEditingController(text: widget.address?.name ?? '');
    
    // Parse phone number
    String initialPhone = '';
    if (widget.address?.phoneNumber != null && widget.address!.phoneNumber.isNotEmpty) {
      final phone = widget.address!.phoneNumber;
      if (phone.startsWith('+966')) {
        _initialCountryCode = 'SA';
        _countryCode = '+966';
        initialPhone = phone.substring(4);
      } else if (phone.startsWith('+')) {
        final match = RegExp(r'^\+(\d{1,4})(.*)$').firstMatch(phone);
        if (match != null) {
          final countryCodeNum = match.group(1)!;
          if (countryCodeNum == '966') {
            _initialCountryCode = 'SA';
            _countryCode = '+966';
          } else if (countryCodeNum == '1') {
            _initialCountryCode = 'US';
            _countryCode = '+1';
          } else {
            _initialCountryCode = countryCodeNum;
            _countryCode = '+$countryCodeNum';
          }
          initialPhone = match.group(2)!;
        } else {
          initialPhone = phone;
        }
      } else {
        initialPhone = phone;
      }
    }
    
    _phoneController = TextEditingController(text: initialPhone);
    _phoneNumber = initialPhone;
    _addressController = TextEditingController(text: widget.address?.address ?? '');
    _selectedLocation = widget.address != null && widget.address!.lat != null && widget.address!.lng != null
        ? LatLng(widget.address!.lat!, widget.address!.lng!)
        : null;
    _isDefault = widget.address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          context.go('/login');
        }
        return;
      }

      final addressRepo = ref.read(addressRepositoryProvider);
      
      // Build phone number properly
      final fullPhoneNumber = _phoneNumber.isNotEmpty 
          ? '$_countryCode$_phoneNumber'
          : (_phoneController.text.trim().isNotEmpty 
              ? '$_countryCode${_phoneController.text.trim()}'
              : '');
      
      final newAddress = AddressModel(
        id: widget.address?.id ?? const Uuid().v4(),
        userId: user.uid,
        label: _labelController.text.trim(),
        name: _nameController.text.trim(),
        phoneNumber: fullPhoneNumber,
        address: _addressController.text.trim(),
        lat: _selectedLocation?.latitude,
        lng: _selectedLocation?.longitude,
        isDefault: _isDefault,
        createdAt: widget.address?.createdAt ?? DateTime.now(),
      );

      if (widget.address == null) {
        await addressRepo.addAddress(newAddress);
      } else {
        await addressRepo.updateAddress(newAddress);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.address == null
                ? 'Address added successfully'
                : 'Address updated successfully'),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 5),
          ),
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
        title: Text(widget.address == null ? 'Add Address' : 'Edit Address'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Label (e.g., Home, Office, Rent)',
                controller: _labelController,
                prefixIcon: const Icon(Icons.label),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a label';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Full Name *',
                controller: _nameController,
                prefixIcon: const Icon(Icons.person),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              IntlPhoneField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  hintText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                initialCountryCode: _initialCountryCode,
                initialValue: _phoneNumber,
                onChanged: (phone) {
                  setState(() {
                    _countryCode = phone.countryCode;
                    _phoneNumber = phone.number;
                  });
                },
                validator: (phone) {
                  if (phone == null || phone.number.isEmpty) {
                    return 'Please enter phone number';
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
                label: 'Address',
                required: true,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Set as default address'),
                value: _isDefault,
                onChanged: (value) {
                  setState(() {
                    _isDefault = value ?? false;
                  });
                },
              ),
              const SizedBox(height: 32),
              AppButton(
                text: widget.address == null ? 'Add Address' : 'Update Address',
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

