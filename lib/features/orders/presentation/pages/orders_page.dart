import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundry_app/app/localization/app_localizations.dart';
import 'package:laundry_app/features/common/presentation/widgets/loading_widget.dart';
import 'package:laundry_app/features/common/domain/models/order_model.dart';
import 'package:laundry_app/features/common/presentation/providers/providers.dart';
import 'package:laundry_app/features/common/presentation/providers/app_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> with WidgetsBindingObserver {
  int _selectedTab = 0; // 0: Active, 1: Completed, 2: Cancelled
  bool _didInitialRefresh = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh orders when page becomes visible (e.g., navigating from other pages)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Use a post-frame callback to ensure the widget is fully built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.invalidate(orderListProvider(user.uid));
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Refresh orders stream when returning to the app to ensure real-time data
        ref.invalidate(orderListProvider(user.uid));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.myOrders)),
        body: const Center(child: Text('Please login to view orders')),
      );
    }

    // One-time refresh when entering the page to ensure fresh Firestore data
    if (!_didInitialRefresh) {
      _didInitialRefresh = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.invalidate(orderListProvider(user.uid));
        }
      });
    }

    final ordersAsync = ref.watch(orderListProvider(user.uid));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myOrders),
      ),
      body: Column(
        children: [
          // Tabs
          Row(
            children: [
              Expanded(
                child: _buildTab(0, l10n.active, _selectedTab == 0),
              ),
              Expanded(
                child: _buildTab(1, l10n.completed, _selectedTab == 1),
              ),
              Expanded(
                child: _buildTab(2, l10n.cancelled, _selectedTab == 2),
              ),
            ],
          ),
          const Divider(height: 1),
          // Orders list
          Expanded(
            child: ordersAsync.when(
              data: (allOrders) {
                final filteredOrders = _filterOrders(allOrders, _selectedTab);

                if (filteredOrders.isEmpty) {
                  return Center(
                    child: Text(
                      'No ${_getTabLabel(_selectedTab).toLowerCase()} orders',
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    return _buildOrderCard(context, filteredOrders[index]);
                  },
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
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(orderListProvider(user.uid));
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, 1),
    );
  }

  List<OrderModel> _filterOrders(List<OrderModel> orders, int tab) {
    switch (tab) {
      case 0: // Active
        return orders.where((o) =>
          o.status == OrderStatus.pending ||
          o.status == OrderStatus.accepted ||
          o.status == OrderStatus.processing ||
          o.status == OrderStatus.readyForPickup ||
          o.status == OrderStatus.outForDelivery
        ).toList();
      case 1: // Completed
        return orders.where((o) => o.status == OrderStatus.delivered).toList();
      case 2: // Cancelled
        return orders.where((o) => o.status == OrderStatus.cancelled).toList();
      default:
        return [];
    }
  }

  String _getTabLabel(int tab) {
    switch (tab) {
      case 0:
        return 'Active';
      case 1:
        return 'Completed';
      case 2:
        return 'Cancelled';
      default:
        return '';
    }
  }

  Widget _buildTab(int index, String label, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() => _selectedTab = index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('MMM d');
    final timeFormat = DateFormat('h:mma');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${order.id.substring(0, 8)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.status.displayName,
                    style: TextStyle(
                      color: _getStatusColor(order.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (order.items.isNotEmpty)
              Text(
                order.items.map((item) => item.serviceName).join(', '),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Pickup: ${dateFormat.format(order.pickupTime)} (${timeFormat.format(order.pickupTime)})',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Delivery: ${dateFormat.format(order.deliveryTime)} (${timeFormat.format(order.deliveryTime)})',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SAR ${order.totalPrice.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () {
                    // Refresh before opening details to ensure latest status/timeline
                    ref.invalidate(orderDetailProvider(order.id));
                    context.push('/order/${order.id}');
                  },
                  child: Text(l10n.viewDetails),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.processing:
        return Colors.blue;
      case OrderStatus.readyForPickup:
        return Colors.purple;
      case OrderStatus.outForDelivery:
        return Colors.purple;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.accepted:
        return Colors.blue;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/home');
            break;
          case 1:
            // Already on orders
            break;
          case 2:
            context.go('/cart'); // Use cart route to show current cart items
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Orders'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_basket), label: 'Basket'),
      ],
    );
  }
}

