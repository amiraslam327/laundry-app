import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundry_app/features/common/domain/models/laundry_model.dart';
import 'package:laundry_app/features/common/presentation/providers/app_providers.dart';
import 'package:laundry_app/app/theme/app_theme.dart';

class LaundryCard extends ConsumerWidget {
  final LaundryModel laundry;
  final VoidCallback? onTap;

  const LaundryCard({
    super.key,
    required this.laundry,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLaundry = ref.watch(selectedLaundryProvider);
    final isSelected = selectedLaundry?.id == laundry.id;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isSelected ? AppTheme.primaryBlue.withOpacity(0.1) : null,
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected
            ? BorderSide(color: AppTheme.primaryBlue, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          // Select this laundry (replaces any previous selection)
          ref.read(selectedLaundryProvider.notifier).state = laundry;
          // Also call the original onTap if provided
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: laundry.logoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: laundry.logoUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: const Icon(Icons.local_laundry_service),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: const Icon(Icons.local_laundry_service),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.local_laundry_service),
                      ),
              ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (laundry.isPreferred)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Preferred',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.white),
                            ),
                          ),
                        if (laundry.isPreferred)
                          const SizedBox(width: 8),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            laundry.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? AppTheme.primaryBlue : null,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: AppTheme.primaryBlue,
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        Text(
                          '${laundry.rating}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '123 Reviews', // TODO: Get from model
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (laundry.discountPercentage > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.green,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.local_offer,
                                  size: 12,
                                  color: Colors.green[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${laundry.discountPercentage}% Discount',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            laundry.address,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

