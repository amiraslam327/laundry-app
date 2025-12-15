import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundry_app/app/theme/app_theme.dart';
import 'package:laundry_app/features/common/presentation/widgets/app_button.dart';
import 'package:laundry_app/features/common/presentation/widgets/app_text_field.dart';
import 'package:laundry_app/features/common/presentation/widgets/address_picker_widget.dart';
import 'package:laundry_app/utils/admin_setup_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CreateAdminPage extends ConsumerStatefulWidget {
  const CreateAdminPage({super.key});

  @override
  ConsumerState<CreateAdminPage> createState() => _CreateAdminPageState();
}

class _CreateAdminPageState extends ConsumerState<CreateAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  bool _isLoading = false;
  bool _isCreating = true; // true = create new, false = make existing admin
  String _countryCode = '+966';
  String _phoneNumber = '';
  LatLng? _selectedLocation;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _createAdminUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final helper = AdminSetupHelper();

      if (_isCreating) {
        // Create new admin user
        final userId = await helper.createAdminUser(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          fullName: _fullNameController.text.trim(),
          phoneNumber: '$_countryCode$_phoneNumber',
          defaultAddress: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Admin user created successfully! ID: $userId'),
              backgroundColor: Colors.green,
            ),
          );
          // Clear form
          _formKey.currentState?.reset();
        }
      } else {
        // Make existing user admin
        await helper.makeUserAdminByEmail(_emailController.text.trim());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User set as admin successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _makeCurrentUserAdmin() async {
    setState(() => _isLoading = true);

    try {
      final helper = AdminSetupHelper();
      await helper.makeCurrentUserAdmin();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are now an admin! Please logout and login again.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
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
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Admin User'),
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
              // Mode Toggle
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Create New Admin'),
                          selected: _isCreating,
                          onSelected: (selected) {
                            setState(() => _isCreating = selected);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Make Existing Admin'),
                          selected: !_isCreating,
                          onSelected: (selected) {
                            setState(() => _isCreating = !selected);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Quick Action: Make Current User Admin
              if (currentUser != null)
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.person, size: 48, color: Colors.blue),
                        const SizedBox(height: 8),
                        Text(
                          'Current User: ${currentUser.email}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          text: 'Make Me Admin',
                          onPressed: _makeCurrentUserAdmin,
                          isLoading: _isLoading,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Form Fields
              AppTextField(
                label: 'Email *',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              
              if (_isCreating) ...[
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Password *',
                  controller: _passwordController,
                  obscureText: true,
                  prefixIcon: const Icon(Icons.lock),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Full Name *',
                  controller: _fullNameController,
                  prefixIcon: const Icon(Icons.person),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter full name';
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
                  ),
                  initialCountryCode: 'SA', // Saudi Arabia
                  onChanged: (phone) {
                    _countryCode = phone.countryCode;
                    _phoneNumber = phone.number;
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
                  label: 'Address (Optional)',
                  onLocationSelected: (location) {
                    _selectedLocation = location;
                  },
                ),
              ],
              
              const SizedBox(height: 24),
              AppButton(
                text: _isCreating ? 'Create Admin User' : 'Make User Admin',
                onPressed: _createAdminUser,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

