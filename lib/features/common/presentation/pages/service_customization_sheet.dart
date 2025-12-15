import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundry_app/features/common/domain/models/service_model.dart';
import 'package:laundry_app/features/common/domain/models/basket_item_model.dart';
import 'package:laundry_app/features/common/domain/models/fragrance_model.dart';
import 'package:laundry_app/features/common/presentation/providers/providers.dart';
import 'package:uuid/uuid.dart';

class ServiceCustomizationSheet extends ConsumerStatefulWidget {
  final ServiceModel service;
  final String laundryId;
  final String laundryName;
  final BasketItemModel? existingItem;

  const ServiceCustomizationSheet({
    super.key,
    required this.service,
    required this.laundryId,
    required this.laundryName,
    this.existingItem,
  });

  @override
  ConsumerState<ServiceCustomizationSheet> createState() =>
      _ServiceCustomizationSheetState();
}

class _ServiceCustomizationSheetState
    extends ConsumerState<ServiceCustomizationSheet> {
  int _currentStep = 0;
  double _quantity = 1.0;
  String? _selectedFragranceId;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingItem != null) {
      _quantity = widget.existingItem!.quantity;
      _selectedFragranceId = widget.existingItem!.fragranceId;
      _notesController.text = widget.existingItem!.notes ?? '';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fragrancesRepository = ref.watch(fragrancesRepositoryProvider);
    final fragrancesStream = fragrancesRepository.getAllFragrances();

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step indicators
          Row(
            children: [
              _buildStepIndicator(0, 'Instruction', Icons.person),
              const Expanded(child: Divider()),
              _buildStepIndicator(1, 'Fragrance', Icons.air),
              const Expanded(child: Divider()),
              _buildStepIndicator(2, 'Package', Icons.shopping_bag),
            ],
          ),
          const SizedBox(height: 24),
          // Step content
          if (_currentStep == 0) _buildQuantityStep(),
          if (_currentStep == 1)
            StreamBuilder(
              stream: fragrancesStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return _buildFragranceStep(snapshot.data!);
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          if (_currentStep == 2) _buildPackageStep(),
          const SizedBox(height: 24),
          // Navigation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentStep > 0)
                OutlinedButton(
                  onPressed: () {
                    setState(() => _currentStep--);
                  },
                  child: const Text('Back'),
                )
              else
                const SizedBox(),
              ElevatedButton(
                onPressed: _currentStep < 2
                    ? () {
                        setState(() => _currentStep++);
                      }
                    : _handleConfirm,
                child: Text(_currentStep < 2 ? 'Next' : 'Confirm'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, IconData icon) {
    final isActive = step == _currentStep;
    final isCompleted = step < _currentStep;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive || isCompleted
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isActive || isCompleted ? Colors.white : Colors.grey[600],
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
        ),
      ],
    );
  }

  Widget _buildQuantityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Quantity',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () {
                if (_quantity > 0.5) {
                  setState(() => _quantity -= 0.5);
                }
              },
            ),
            Expanded(
              child: Text(
                '${_quantity.toStringAsFixed(1)} kg',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                setState(() => _quantity += 0.5);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
            hintText: 'Add any special instructions',
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildFragranceStep(List<FragranceModel> fragrances) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Fragrance',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: fragrances.length,
          itemBuilder: (context, index) {
            final fragrance = fragrances[index];
            final isSelected = _selectedFragranceId == fragrance.id;

            return InkWell(
              onTap: () {
                setState(() => _selectedFragranceId = fragrance.id);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.air,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fragrance.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPackageStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Package Details',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.service.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('Quantity: ${_quantity.toStringAsFixed(1)} kg'),
                if (_selectedFragranceId != null)
                  Text('Fragrance: Selected'),
                const SizedBox(height: 8),
                Text(
                  'Total: SAR ${(_quantity * widget.service.pricePerKg).toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _handleConfirm() {
    final basketNotifier = ref.read(basketProvider.notifier);

    if (widget.existingItem != null) {
      // Update existing item
      final updatedItem = widget.existingItem!.copyWith(
        quantity: _quantity,
        fragranceId: _selectedFragranceId,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
      basketNotifier.updateItem(updatedItem);
    } else {
      // Add new item
      final newItem = BasketItemModel(
        id: const Uuid().v4(),
        serviceId: widget.service.id,
        serviceName: widget.service.name,
        laundryId: widget.laundryId,
        laundryName: widget.laundryName,
        quantity: _quantity,
        pricePerKg: widget.service.pricePerKg,
        fragranceId: _selectedFragranceId,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
      basketNotifier.addItem(newItem);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item added to basket')),
    );
  }
}

