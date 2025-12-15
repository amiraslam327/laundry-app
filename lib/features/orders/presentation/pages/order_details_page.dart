import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:laundry_app/features/common/presentation/widgets/loading_widget.dart';
import 'package:laundry_app/features/common/domain/models/order_model.dart';
import 'package:laundry_app/features/common/presentation/providers/app_providers.dart';
import 'package:laundry_app/features/common/presentation/providers/providers.dart';
import 'package:laundry_app/app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class OrderDetailsPage extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailsPage({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends ConsumerState<OrderDetailsPage> {
  bool _didInitialRefresh = false;

  @override
  Widget build(BuildContext context) {
    // Force a fresh fetch once when opening the page to avoid stale status
    if (!_didInitialRefresh) {
      _didInitialRefresh = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.invalidate(orderDetailProvider(widget.orderId));
        }
      });
    }

    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/home'),
            tooltip: 'Go to Home',
          ),
        ],
      ),
      body: orderAsync.when(
        data: (order) {

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order ID and Status
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order #${order.id.substring(0, 8)}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Placed on ${DateFormat('MMM d, y').format(order.createdAt)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(order.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            order.status.displayName,
                            style: TextStyle(
                              color: _getStatusColor(order.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Items
                Text(
                  'Items',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: order.items.map((item) {
                      return ListTile(
                        title: Text(item.serviceName),
                        subtitle: Text('${item.quantity.toStringAsFixed(1)} kg'),
                        trailing: Text(
                          'SAR ${item.price.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                // Fragrance
                if (order.fragranceId != null)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.air),
                      title: const Text('Fragrance'),
                      subtitle: Text(order.fragranceId!),
                    ),
                  ),
                const SizedBox(height: 16),
                // Pickup & Delivery
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Pickup'),
                        subtitle: Text(
                          '${DateFormat('MMM d, y').format(order.pickupTime)} at ${DateFormat('h:mma').format(order.pickupTime)}',
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Delivery'),
                        subtitle: Text(
                          '${DateFormat('MMM d, y').format(order.deliveryTime)} at ${DateFormat('h:mma').format(order.deliveryTime)}',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Delivery Information
                if (order.notes != null && order.notes!.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.delivery_dining, color: AppTheme.primaryBlue),
                              const SizedBox(width: 8),
                              Text(
                                'Delivery Information',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Parse and display delivery information
                          ..._parseDeliveryNotes(order.notes!).map((line) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      _getDeliveryIcon(line),
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        line,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                // Total
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          'SAR ${order.totalPrice.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Timeline
                _buildTimeline(context, order),
                const SizedBox(height: 16),
                // Cancel Order Button (only if pending)
                if (order.status == OrderStatus.pending)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _cancelOrder(context, ref, order.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Cancel Order'),
                    ),
                  ),
              ],
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
              Text('Error: $error'),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cancelOrder(BuildContext context, WidgetRef ref, String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final ordersRepo = ref.read(ordersRepositoryProvider);
        await ordersRepo.cancelOrder(orderId);
        if (context.mounted) {
          // Refresh orders list so the cancelled order disappears from Active
          final userId = FirebaseAuth.instance.currentUser?.uid;
          if (userId != null) {
            ref.invalidate(orderListProvider(userId));
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order cancelled')),
          );
          // Navigate back to Orders page after cancelling
          context.go('/orders');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error cancelling order: $e')),
          );
        }
      }
    }
  }

  Widget _buildTimeline(BuildContext context, OrderModel order) {
    // Timeline excludes cancelled; show a simple banner instead when cancelled
    if (order.status == OrderStatus.cancelled) {
      return Card(
        color: Colors.red.withOpacity(0.08),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.cancel, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Order cancelled',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final statuses = [
      OrderStatus.pending,
      OrderStatus.accepted,
      OrderStatus.processing,
      OrderStatus.readyForPickup,
      OrderStatus.outForDelivery,
      OrderStatus.delivered,
    ];

    final currentIndex = statuses.indexOf(order.status);
    if (currentIndex == -1) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Timeline',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...statuses.asMap().entries.map((entry) {
              final index = entry.key;
              final status = entry.value;
              final isCurrent = index == currentIndex;
              final isCompleted = index <= currentIndex;

              return _buildTimelineItem(
                context,
                status,
                isCompleted,
                isCurrent,
                index < statuses.length - 1,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    OrderStatus status,
    bool isCompleted,
    bool isCurrent,
    bool hasNext,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? AppTheme.primaryBlue
                    : Colors.grey[300],
                border: isCurrent
                    ? Border.all(color: AppTheme.primaryBlue, width: 3)
                    : null,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            if (hasNext)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? AppTheme.primaryBlue : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: hasNext ? 16 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.displayName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCompleted ? AppTheme.primaryBlue : Colors.grey,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<String> _parseDeliveryNotes(String notes) {
    // Split by newlines and filter empty strings
    return notes.split('\n').where((line) => line.trim().isNotEmpty).toList();
  }

  IconData _getDeliveryIcon(String line) {
    final lowerLine = line.toLowerCase();
    if (lowerLine.contains('delivery:')) return Icons.local_shipping;
    if (lowerLine.contains('address:')) return Icons.location_on;
    if (lowerLine.contains('name:')) return Icons.person;
    if (lowerLine.contains('phone:')) return Icons.phone;
    return Icons.info;
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.accepted:
        return Colors.blue;
      case OrderStatus.processing:
        return Colors.blue;
      case OrderStatus.readyForPickup:
        return Colors.purple;
      case OrderStatus.outForDelivery:
        return Colors.purple;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }
}

