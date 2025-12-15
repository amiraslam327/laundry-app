import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:laundry_app/app/theme/app_theme.dart';
import 'package:laundry_app/features/common/presentation/providers/providers.dart';
import 'package:laundry_app/features/common/domain/models/address_model.dart';
import 'package:laundry_app/features/common/presentation/widgets/app_button.dart';
import 'package:laundry_app/features/common/presentation/widgets/app_text_field.dart';
import 'package:laundry_app/features/common/presentation/widgets/address_picker_widget.dart';
import 'package:laundry_app/features/common/presentation/widgets/loading_widget.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class AddressesPage extends ConsumerStatefulWidget {
  const AddressesPage({super.key});

  @override
  ConsumerState<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends ConsumerState<AddressesPage> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Addresses')),
        body: const Center(child: Text('Please login to view addresses')),
      );
    }

    final addressRepo = ref.read(addressRepositoryProvider);
    final addressesAsync = ref.watch(
      StreamProvider<List<AddressModel>>(
        (ref) => addressRepo.getUserAddresses(user.uid),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Addresses'),
        actions: [
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => context.push('/addresses/edit'),
                      ),
        ],
      ),
      body: addressesAsync.when(
        data: (addresses) {
          if (addresses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No addresses saved',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                              AppButton(
                                text: 'Add Address',
                                onPressed: () => context.push('/addresses/edit'),
                              ),
                ],
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: () async {
              // Force reload by invalidating the provider
              ref.invalidate(StreamProvider((ref) => addressRepo.getUserAddresses(user.uid)));
              // Wait a bit for the stream to emit
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final address = addresses[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(
                    _getAddressIcon(address.label),
                    color: AppTheme.primaryBlue,
                  ),
                  title: Row(
                    children: [
                      Text(
                        address.label,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        address.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (address.name.isNotEmpty || address.phoneNumber.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${address.name.isNotEmpty ? address.name : ''}${address.name.isNotEmpty && address.phoneNumber.isNotEmpty ? ' • ' : ''}${address.phoneNumber.isNotEmpty ? address.phoneNumber : ''}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      if (!address.isDefault)
                        const PopupMenuItem(
                          value: 'set_default',
                          child: Text('Set as Default'),
                        ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'set_default') {
                        _setDefaultAddress(user.uid, address.id);
                      } else if (value == 'edit') {
                        _showEditAddressDialog(context, user.uid, address);
                      } else if (value == 'delete') {
                        _deleteAddress(user.uid, address.id);
                      }
                    },
                  ),
                ),
              );
            },
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
              Text('Error loading addresses: $error'),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getAddressIcon(String label) {
    final lowerLabel = label.toLowerCase();
    if (lowerLabel.contains('home')) return Icons.home;
    if (lowerLabel.contains('office')) return Icons.business;
    if (lowerLabel.contains('rent')) return Icons.apartment;
    return Icons.location_on;
  }

  Future<void> _setDefaultAddress(String userId, String addressId) async {
    try {
      final addressRepo = ref.read(addressRepositoryProvider);
      await addressRepo.setDefaultAddress(userId, addressId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Default address updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteAddress(String userId, String addressId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final addressRepo = ref.read(addressRepositoryProvider);
        await addressRepo.deleteAddress(addressId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Address deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  void _showAddAddressDialog(BuildContext context, String userId) {
    _showAddressDialog(context, userId, null);
  }

  void _showEditAddressDialog(BuildContext context, String userId, AddressModel address) {
    _showAddressDialog(context, userId, address);
  }

  void _showAddressDialog(BuildContext context, String userId, AddressModel? address) {
    final _formKey = GlobalKey<FormState>();
    final _labelController = TextEditingController(text: address?.label ?? '');
    final _nameController = TextEditingController(text: address?.name ?? '');
    
    // Parse phone number
    String initialPhone = '';
    String initialCountryCode = 'SA'; // Default to Saudi Arabia
    if (address?.phoneNumber != null && address!.phoneNumber.isNotEmpty) {
      final phone = address.phoneNumber;
      if (phone.startsWith('+966')) {
        initialCountryCode = 'SA';
        initialPhone = phone.substring(4);
      } else if (phone.startsWith('+')) {
        final match = RegExp(r'^\+(\d{1,4})(.*)$').firstMatch(phone);
        if (match != null) {
          final countryCodeNum = match.group(1)!;
          // Map common country codes
          if (countryCodeNum == '966') {
            initialCountryCode = 'SA';
          } else if (countryCodeNum == '1') {
            initialCountryCode = 'US';
          } else {
            initialCountryCode = countryCodeNum; // Use numeric code as fallback
          }
          initialPhone = match.group(2)!;
        } else {
          initialPhone = phone;
        }
      } else {
        initialPhone = phone;
      }
    }
    
    final _phoneController = TextEditingController(text: initialPhone);
    final _addressController = TextEditingController(text: address?.address ?? '');
    final initialLocation = address != null && address.lat != null && address.lng != null
        ? LatLng(address.lat!, address.lng!)
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // State variables inside StatefulBuilder
          LatLng? _selectedLocation = initialLocation;
          bool _isDefault = address?.isDefault ?? false;
          bool _isSaving = false;
          String _countryCode = initialCountryCode == 'SA' ? '+966' : '+1';
          String _phoneNumber = initialPhone;

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) => Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          address == null ? 'Add Address' : 'Edit Address',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
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
                    initialCountryCode: initialCountryCode,
                    initialValue: initialPhone,
                    onChanged: (phone) {
                      setDialogState(() {
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
                      setDialogState(() {
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
                      setDialogState(() {
                        _isDefault = value ?? false;
                      });
                    },
                  ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Action buttons
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isSaving
                                ? null
                                : () async {
                                    if (!_formKey.currentState!.validate()) return;
                                    if (_addressController.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please select an address')),
                                      );
                                      return;
                                    }

                                    setDialogState(() => _isSaving = true);

                                    try {
                                      final addressRepo = ref.read(addressRepositoryProvider);
                                      // Build phone number properly
                                      final fullPhoneNumber = _phoneNumber.isNotEmpty 
                                          ? '$_countryCode$_phoneNumber'
                                          : (_phoneController.text.trim().isNotEmpty 
                                              ? '$_countryCode${_phoneController.text.trim()}'
                                              : '');
                                      
                                      final newAddress = AddressModel(
                                        id: address?.id ?? const Uuid().v4(),
                                        userId: userId,
                                        label: _labelController.text.trim(),
                                        name: _nameController.text.trim(),
                                        phoneNumber: fullPhoneNumber,
                                        address: _addressController.text.trim(),
                                        lat: _selectedLocation?.latitude,
                                        lng: _selectedLocation?.longitude,
                                        isDefault: _isDefault,
                                        createdAt: address?.createdAt ?? DateTime.now(),
                                      );

                                      if (address == null) {
                                        await addressRepo.addAddress(newAddress);
                                      } else {
                                        await addressRepo.updateAddress(newAddress);
                                      }

                                      if (mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(address == null
                                                ? 'Address added successfully'
                                                : 'Address updated successfully'),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        String errorMessage = 'Error: $e';
                                        if (e.toString().contains('SharedPreferences') || 
                                            e.toString().contains('channel-error')) {
                                          errorMessage = 'Storage error. Please restart the app and try again.';
                                        }
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(errorMessage),
                                            duration: const Duration(seconds: 5),
                                          ),
                                        );
                                      }
                                    } finally {
                                      if (mounted) {
                                        setDialogState(() => _isSaving = false);
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(address == null ? 'Add Address' : 'Update Address'),
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
  }
}

