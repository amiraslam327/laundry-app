import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class AddressPickerWidget extends StatefulWidget {
  final TextEditingController addressController;
  final Function(LatLng?)? onLocationSelected;
  final String? label;
  final bool required;
  final LatLng? initialLocation;

  const AddressPickerWidget({
    super.key,
    required this.addressController,
    this.onLocationSelected,
    this.label,
    this.required = false,
    this.initialLocation,
  });

  @override
  State<AddressPickerWidget> createState() => _AddressPickerWidgetState();
}

class _AddressPickerWidgetState extends State<AddressPickerWidget> {
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;
  bool _isSelectingLocation = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
  }

  @override
  void dispose() {
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
          final address = '${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}'.trim();
          widget.addressController.text = address;
          if (widget.onLocationSelected != null) {
            widget.onLocationSelected!(_selectedLocation);
          }
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

  Future<void> _openMapPicker() async {
    final result = await showDialog<LatLng>(
      context: context,
      builder: (context) => _MapPickerDialog(
        initialLocation: _selectedLocation ?? const LatLng(24.7136, 46.6753), // Riyadh, Saudi Arabia
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result;
      });

      // Get address from coordinates
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          result.latitude,
          result.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks[0];
          final address = '${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}'.trim();
          widget.addressController.text = address;
          if (widget.onLocationSelected != null) {
            widget.onLocationSelected!(_selectedLocation);
          }
        }
      } catch (e) {
        debugPrint('Error getting address: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: widget.addressController,
          decoration: InputDecoration(
            labelText: widget.label ?? 'Address',
            hintText: 'Select address from map',
            prefixIcon: const Icon(Icons.location_on),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: _isSelectingLocation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  onPressed: _isSelectingLocation ? null : _getCurrentLocation,
                  tooltip: 'Use current location',
                ),
                IconButton(
                  icon: const Icon(Icons.map),
                  onPressed: _openMapPicker,
                  tooltip: 'Pick from map',
                ),
              ],
            ),
          ),
          readOnly: true,
          validator: widget.required
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select an address';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }
}

class _MapPickerDialog extends StatefulWidget {
  final LatLng initialLocation;

  const _MapPickerDialog({required this.initialLocation});

  @override
  State<_MapPickerDialog> createState() => _MapPickerDialogState();
}

class _MapPickerDialogState extends State<_MapPickerDialog> {
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(24.7136, 46.6753);
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    _markers.add(
      Marker(
        markerId: const MarkerId('selected'),
        position: _selectedLocation,
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapTap(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _markers = {
        Marker(
          markerId: const MarkerId('selected'),
          position: location,
        ),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        height: 500,
        width: double.infinity,
        child: Column(
          children: [
            AppBar(
              title: const Text('Select Address'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, _selectedLocation),
                  child: const Text('Select'),
                ),
              ],
            ),
            Expanded(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _selectedLocation,
                  zoom: 15,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                onTap: _onMapTap,
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

