import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundry_app/features/common/presentation/widgets/service_card.dart';
import 'package:laundry_app/features/common/presentation/widgets/loading_widget.dart';
import 'package:laundry_app/features/common/domain/models/service_model.dart';
import 'package:laundry_app/features/common/presentation/providers/providers.dart';
import 'package:laundry_app/features/common/presentation/pages/service_customization_sheet.dart';

class LaundryDetailsPage extends ConsumerStatefulWidget {
  final String laundryId;

  const LaundryDetailsPage({
    super.key,
    required this.laundryId,
  });

  @override
  ConsumerState<LaundryDetailsPage> createState() => _LaundryDetailsPageState();
}

class _LaundryDetailsPageState extends ConsumerState<LaundryDetailsPage> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final laundriesRepository = ref.watch(laundriesRepositoryProvider);
    final servicesRepository = ref.watch(servicesRepositoryProvider);

    final laundryStream = laundriesRepository.getLaundryStream(widget.laundryId);
    final servicesStream = servicesRepository.getServicesByLaundry(widget.laundryId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laundry Details'),
      ),
      body: StreamBuilder(
        stream: laundryStream,
        builder: (context, laundrySnapshot) {
          if (laundrySnapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }

          final laundry = laundrySnapshot.data;
          if (laundry == null) {
            return const Center(child: Text('Laundry not found'));
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner
                if (laundry.bannerImageUrl != null)
                  Image.network(
                    laundry.bannerImageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                else
                  Container(
                    height: 200,
                    width: double.infinity,
                    color: Theme.of(context).colorScheme.primary,
                    child: Center(
                      child: Text(
                        laundry.name,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        laundry.name,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text('${laundry.rating}'),
                          const SizedBox(width: 16),
                          const Icon(Icons.location_on, size: 20),
                          Expanded(
                            child: Text(
                              laundry.address,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Category tabs
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['All', 'Quick Wash', 'Standard', 'Premium']
                              .map((category) {
                            final isSelected = _selectedCategory == category;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(category),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() => _selectedCategory = category);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Services list
                      StreamBuilder<List<ServiceModel>>(
                        stream: servicesStream,
                        builder: (context, servicesSnapshot) {
                          if (servicesSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const LoadingWidget();
                          }

                          final services = servicesSnapshot.data ?? [];
                          final filteredServices = _selectedCategory == 'All'
                              ? services
                              : services
                                  .where((s) => s.name == _selectedCategory)
                                  .toList();

                          if (filteredServices.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Text('No services found'),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredServices.length,
                            itemBuilder: (context, index) {
                              final service = filteredServices[index];
                              return ServiceCard(
                                service: service,
                                onAdd: () {
                                  _showServiceCustomization(context, service, laundry.name);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showServiceCustomization(
    BuildContext context,
    ServiceModel service,
    String laundryName,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ServiceCustomizationSheet(
        service: service,
        laundryId: widget.laundryId,
        laundryName: laundryName,
      ),
    );
  }
}

