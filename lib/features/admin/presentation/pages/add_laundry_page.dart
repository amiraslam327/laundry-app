import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:uuid/uuid.dart';
import 'package:laundry_app/app/theme/app_theme.dart';
import 'package:laundry_app/features/common/presentation/widgets/app_button.dart';
import 'package:laundry_app/features/common/presentation/widgets/app_text_field.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class AddLaundryPage extends ConsumerStatefulWidget {
  const AddLaundryPage({super.key});

  @override
  ConsumerState<AddLaundryPage> createState() => _AddLaundryPageState();
}

class _AddLaundryPageState extends ConsumerState<AddLaundryPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _workingHoursController = TextEditingController();
  
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;
  bool _isLoading = false;
  bool _isSelectingLocation = false;
  String _countryCode = '+966';
  String _phoneNumber = '';

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _workingHoursController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isSelectingLocation = true);
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions denied')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions permanently denied')),
          );
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });

      // Get address from coordinates
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks[0];
          _addressController.text = 
              '${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}'.trim();
        }
      } catch (e) {
        debugPrint('Error getting address: $e');
      }

      if (_mapController != null && _selectedLocation != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_selectedLocation!, 15),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    } finally {
      setState(() => _isSelectingLocation = false);
    }
  }

  Future<void> _saveLaundry() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location on the map')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final laundryId = const Uuid().v4();

      await firestore.collection('laundries').doc(laundryId).set({
        'id': laundryId,
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'phone': '$_countryCode$_phoneNumber',
        'address': _addressController.text.trim(),
        'lat': _selectedLocation!.latitude,
        'lng': _selectedLocation!.longitude,
        'workingHours': _workingHoursController.text.trim(),
        'rating': 0.0,
        'isOpen': true,
        'logoUrl': null,
        'isPreferred': false,
        'minOrderAmount': 0.0,
        'discountPercentage': 0,
        'bannerImageUrl': null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laundry added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving laundry: $e')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Laundry'),
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
              AppTextField(
                label: 'Laundry Name *',
                controller: _nameController,
                prefixIcon: const Icon(Icons.local_laundry_service),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter laundry name';
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
              IntlPhoneField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone *',
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
              AppTextField(
                label: 'Address *',
                controller: _addressController,
                maxLines: 2,
                prefixIcon: const Icon(Icons.location_on),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Working Hours *',
                controller: _workingHoursController,
                hint: 'e.g., Mon-Fri: 9AM-6PM',
                prefixIcon: const Icon(Icons.access_time),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter working hours';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Map Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select Location *',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          TextButton.icon(
                            onPressed: _isSelectingLocation ? null : _getCurrentLocation,
                            icon: _isSelectingLocation
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.my_location),
                            label: const Text('Use Current Location'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: _selectedLocation ?? const LatLng(24.7136, 46.6753), // Riyadh default
                              zoom: 12,
                            ),
                            onMapCreated: (controller) {
                              _mapController = controller;
                            },
                            onTap: (LatLng location) {
                              setState(() {
                                _selectedLocation = location;
                              });
                            },
                            markers: _selectedLocation != null
                                ? {
                                    Marker(
                                      markerId: const MarkerId('selected'),
                                      position: _selectedLocation!,
                                      infoWindow: const InfoWindow(title: 'Selected Location'),
                                    ),
                                  }
                                : {},
                            myLocationButtonEnabled: true,
                            myLocationEnabled: true,
                          ),
                        ),
                      ),
                      if (_selectedLocation != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                          'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                text: 'Save Laundry',
                onPressed: _saveLaundry,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

