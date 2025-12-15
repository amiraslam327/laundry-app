import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laundry_app/app/theme/app_theme.dart';
import 'package:laundry_app/features/common/data/repositories/sqlite_address_repository.dart';
import 'package:laundry_app/features/common/domain/models/sqlite_address_model.dart';
import 'package:laundry_app/features/common/presentation/widgets/loading_widget.dart';

class AddressListPage extends ConsumerStatefulWidget {
  const AddressListPage({super.key});

  @override
  ConsumerState<AddressListPage> createState() => _AddressListPageState();
}

class _AddressListPageState extends ConsumerState<AddressListPage> {
  final SqliteAddressRepository _addressRepo = SqliteAddressRepository();
  SqliteAddressModel? _selectedAddress;
  List<SqliteAddressModel> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final selected = await _addressRepo.getSelectedAddress();
      final addresses = await _addressRepo.getAllAddresses();
      
      if (mounted) {
        setState(() {
          _selectedAddress = selected;
          _addresses = addresses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectAddress(SqliteAddressModel address) async {
    try {
      await _addressRepo.setSelectedAddress(address.id);
      if (mounted) {
        setState(() {
          _selectedAddress = address;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address selected')),
        );
        context.pop(address);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteAddress(SqliteAddressModel address) async {
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
        await _addressRepo.deleteAddress(address.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Address deleted')),
          );
          // Refresh list after deletion
          await _loadData();
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

  IconData _getAddressIcon(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('home')) return Icons.home;
    if (lowerTitle.contains('work') || lowerTitle.contains('office')) return Icons.work;
    return Icons.location_on;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildEmptyState() {
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
          ElevatedButton.icon(
            onPressed: () async {
              await context.push('/addresses/add');
              if (mounted) {
                // Refresh list after adding address
                await _loadData();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Address'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _addresses.length,
        itemBuilder: (context, index) {
          final address = _addresses[index];
          final isSelected = _selectedAddress?.id == address.id;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: isSelected ? AppTheme.primaryBlue.withOpacity(0.1) : null,
            elevation: isSelected ? 2 : 1,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryBlue.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getAddressIcon(address.title),
                  color: isSelected ? AppTheme.primaryBlue : Colors.grey,
                  size: 24,
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      address.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppTheme.primaryBlue : null,
                          ),
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Selected',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    address.fullAddress,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (address.lat != null && address.lng != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Lat: ${address.lat!.toStringAsFixed(6)}, Lng: ${address.lng!.toStringAsFixed(6)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                                fontSize: 10,
                              ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Added: ${_formatDate(address.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                          fontSize: 10,
                        ),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isSelected)
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline),
                      onPressed: () => _selectAddress(address),
                      tooltip: 'Select this address',
                      color: AppTheme.primaryBlue,
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteAddress(address),
                    tooltip: 'Delete address',
                  ),
                ],
              ),
              onTap: () => _selectAddress(address),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Addresses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await context.push('/addresses/add');
              if (mounted) {
                // Refresh list after adding address using setState
                await _loadData();
              }
            },
            tooltip: 'Add New Address',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _addresses.isEmpty
              ? _buildEmptyState()
              : _buildAddressList(),
    );
  }
}
