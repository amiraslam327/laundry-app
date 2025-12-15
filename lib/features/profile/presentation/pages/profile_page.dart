import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:laundry_app/features/common/presentation/widgets/app_text_field.dart';
import 'package:laundry_app/features/common/presentation/widgets/app_button.dart';
import 'package:laundry_app/features/common/presentation/widgets/address_picker_widget.dart';
import 'package:laundry_app/features/common/presentation/providers/providers.dart';
import 'package:laundry_app/utils/firestore_seeder_helper.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;
  bool _isEditing = false;
  bool _isSeeding = false;
  String _countryCode = '+966';
  String _phoneNumber = '';
  bool _isAdmin = false;
  LatLng? _selectedLocation; // For address picker

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final usersRepository = ref.read(usersRepositoryProvider);
    final userModel = await usersRepository.getUser(user.uid);

    if (userModel != null) {
      setState(() {
        _nameController.text = userModel.fullName;
        // Parse phone number if it includes country code
        final phone = userModel.phoneNumber;
        if (phone.startsWith('+966')) {
          _countryCode = '+966';
          _phoneNumber = phone.substring(4);
          _phoneController.text = _phoneNumber;
        } else if (phone.startsWith('+')) {
          // Extract country code (first 1-4 digits after +)
          final match = RegExp(r'^\+(\d{1,4})(.*)$').firstMatch(phone);
          if (match != null) {
            _countryCode = '+${match.group(1)}';
            _phoneNumber = match.group(2)!;
            _phoneController.text = _phoneNumber;
          } else {
            _phoneController.text = phone;
          }
        } else {
          _phoneController.text = phone;
        }
        _addressController.text = userModel.defaultAddress ?? '';
        // Check if user is admin (role field might be null or undefined)
        _isAdmin = (userModel.role ?? '') == 'admin';
      });
    } else {
      // If user model not found, assume not admin
      setState(() {
        _isAdmin = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        context.go('/login');
        return;
      }

      final usersRepository = ref.read(usersRepositoryProvider);
      await usersRepository.updateUser(user.uid, {
        'fullName': _nameController.text.trim(),
        'phoneNumber': '$_countryCode$_phoneNumber',
        'defaultAddress': _addressController.text.trim(),
      });

      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _seedFirestore() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seed Firestore Data?'),
        content: const Text(
          'This will add sample data (fragrances, laundries, services, categories) to your Firestore database. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Seed Data'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSeeding = true);

    try {
      final seeder = FirestoreSeederHelper();
      await seeder.seedSampleData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Firestore data seeded successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error seeding data: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSeeding = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: () {
                setState(() => _isEditing = false);
                _loadUserData(); // Reset to original values
              },
              child: const Text('Cancel'),
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() => _isEditing = true);
              },
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile picture placeholder
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: Text(
                                user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                                style: const TextStyle(
                                  fontSize: 40,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (_isEditing)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  child: const Icon(Icons.camera_alt, size: 20),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Email (read-only)
                      AppTextField(
                        label: 'Email',
                        controller: TextEditingController(text: user?.email ?? ''),
                        enabled: false,
                      ),
                      const SizedBox(height: 16),
                      // Name
                      AppTextField(
                        label: 'Full Name',
                        controller: _nameController,
                        enabled: _isEditing,
                        prefixIcon: const Icon(Icons.person),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Phone
                      IntlPhoneField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          hintText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        initialCountryCode: 'SA', // Saudi Arabia
                        enabled: _isEditing,
                        onChanged: (phone) {
                          _countryCode = phone.countryCode;
                          _phoneNumber = phone.number;
                        },
                        validator: (phone) {
                          if (phone == null || phone.number.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Address with map picker
                      if (_isEditing)
                        AddressPickerWidget(
                          addressController: _addressController,
                          onLocationSelected: (location) {
                            setState(() {
                              _selectedLocation = location;
                            });
                          },
                          label: 'Default Address',
                          required: false,
                        )
                      else
                        AppTextField(
                          label: 'Default Address',
                          controller: _addressController,
                          enabled: false,
                          maxLines: 3,
                          prefixIcon: const Icon(Icons.location_on),
                        ),
                      const SizedBox(height: 32),
                      // Save button
                      if (_isEditing)
                        AppButton(
                          text: 'Save Changes',
                          onPressed: _saveProfile,
                          isLoading: _isLoading,
                        ),
                      const SizedBox(height: 24),
                      // Language selector (placeholder)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.language),
                          title: const Text('Language'),
                          subtitle: const Text('English'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            // TODO: Implement language selection
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Language selection coming soon')),
                            );
                          },
                        ),
                      ),
                      // Developer Tools Section (Only for Admin)
                      if (_isAdmin) ...[
                        const SizedBox(height: 16),
                        Card(
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.settings),
                                title: const Text('Developer Tools'),
                                subtitle: const Text('Seed Firestore with sample data'),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _isSeeding ? null : () => context.push('/admin/seed'),
                                        icon: const Icon(Icons.auto_awesome),
                                        label: const Text('Admin Panel'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _isSeeding ? null : _seedFirestore,
                                        icon: _isSeeding
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              )
                                            : const Icon(Icons.cloud_upload),
                                        label: const Text('Quick Seed'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Admin Setup Section (Only for Admin)
                        Card(
                          color: Colors.orange[50],
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.admin_panel_settings, color: Colors.orange),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Admin Setup',
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () => context.push('/admin/create-admin'),
                                  child: const Text('Create New Admin User'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Logout button
                      AppButton(
                        text: 'Logout',
                        isOutlined: true,
                        onPressed: _handleLogout,
                        textColor: Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

