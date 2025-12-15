import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundry_app/app/localization/app_localizations.dart';
import 'package:laundry_app/features/common/presentation/widgets/laundry_card.dart';
import 'package:laundry_app/features/common/presentation/widgets/loading_widget.dart';
import 'package:laundry_app/features/common/domain/models/laundry_model.dart';
import 'package:laundry_app/features/common/presentation/providers/providers.dart';
import 'package:laundry_app/features/common/presentation/providers/app_providers.dart';
import 'package:laundry_app/features/common/presentation/providers/service_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:laundry_app/features/common/domain/models/service_category.dart';
import 'package:laundry_app/features/common/domain/models/fragrance_model.dart';
import 'package:laundry_app/app/theme/app_theme.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentIndex = 0;
  final _searchController = TextEditingController();
  bool _hasAutoSelectedFragrance = false; // Track if we've auto-selected once

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Auto-select first fragrance when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSelectFirstFragrance();
    });
  }

  void _autoSelectFirstFragrance() {
    if (_hasAutoSelectedFragrance) return; // Only auto-select once
    
    final fragrancesAsync = ref.read(fragrancesProvider);
    final currentSelected = ref.read(selectedFragranceProvider);
    
    // Only auto-select if no fragrance is currently selected
    if (currentSelected == null) {
      fragrancesAsync.whenData((fragrances) {
        if (fragrances.isNotEmpty && !_hasAutoSelectedFragrance) {
          _hasAutoSelectedFragrance = true;
          ref.read(selectedFragranceProvider.notifier).state = fragrances.first.id;
        }
      });
    } else {
      _hasAutoSelectedFragrance = true; // Mark as done if already selected
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final laundriesAsync = ref.watch(laundriesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: Text(l10n.laundry),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => context.push('/cart'),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFFF5F9FF),
        child: SafeArea(
          top: false, // allow header image to extend under system status bar
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                child: SizedBox(
                  height: 200,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/image.png',
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 18,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'LaundryApp',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    shadows: const [
                                      Shadow(
                                        offset: Offset(0, 2),
                                        blurRadius: 4,
                                        color: Colors.black54,
                                      ),
                                    ],
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Fresh clothes, every time.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    shadows: const [
                                      Shadow(
                                        offset: Offset(0, 2),
                                        blurRadius: 4,
                                        color: Colors.black54,
                                      ),
                                    ],
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _DrawerItem(
                icon: Icons.home_outlined,
                label: 'Home',
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              _DrawerItem(
                icon: Icons.person_outline,
                label: 'Profile',
                onTap: () {
                  Navigator.pop(context);
                  context.push('/profile');
                },
              ),
              const Divider(height: 1, thickness: 0.6),
              _DrawerItem(
                icon: Icons.logout,
                label: 'Logout',
                isDestructive: true,
                onTap: () async {
                  Navigator.pop(context); // Close drawer first
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

                  if (confirm == true && mounted) {
                    try {
                      final authService = ref.read(authServiceProvider);
                      await authService.signOut();
                      if (mounted) {
                        context.go('/login');
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error logging out: $e')),
                        );
                      }
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.searchByStore,
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            // Promo banner
            _buildPromoBanner(context),
            const SizedBox(height: 24),
            // Service Categories section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.services,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigate to services page showing all categories
                          // We'll use a dummy laundryId or create a special route
                          context.push('/services/all');
                        },
                        child: Text(l10n.viewAll),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCategoriesGrid(context),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Fragrances section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Fragrances',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Navigate to all fragrances page
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildFragrancesList(context),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Nearby Laundries section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.nearbyLaundries,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: View all laundries
                    },
                    child: Text(l10n.viewAll),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Laundries list
            laundriesAsync.when(
              data: (laundries) {
                // Debug: Print laundries count
                debugPrint('Laundries loaded: ${laundries.length}');
                
                if (laundries.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_laundry_service_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No laundries found',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Seed sample data from Profile → Developer Tools',
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/profile'),
                            icon: const Icon(Icons.settings),
                            label: const Text('Go to Profile'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: laundries.length,
                    itemBuilder: (context, index) {
                      return LaundryCard(
                        laundry: laundries[index],
                        onTap: () => context.push('/laundry/${laundries[index].id}'),
                      );
                    },
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(32.0),
                child: LoadingWidget(),
              ),
              error: (error, stack) {
                // Debug: Print error details
                debugPrint('Error loading laundries: $error');
                debugPrint('Stack trace: $stack');
                
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading laundries',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.invalidate(laundriesProvider);
                          },
                          child: const Text('Retry'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => context.push('/profile'),
                          child: const Text('Seed Sample Data'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          switch (index) {
            case 0:
              // Already on home
              break;
            case 1:
              context.go('/orders'); // use go to make Orders a top-level tab (no back button)
              break;
            case 2:
              context.push('/cart');
              break;
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.shopping_basket),
            label: 'Basket',
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UP TO 35% Off',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Discount',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Get Discount on your first Wash on Fold.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Icon(
            Icons.local_laundry_service,
            size: 60,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No categories available'),
            ),
          );
        }

        // Show only first 4 categories
        final displayCategories = categories.take(4).toList();

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.15,
          ),
          itemCount: displayCategories.length,
          itemBuilder: (context, index) {
            final category = displayCategories[index];
            return _buildCategoryCard(context, category);
          },
        );
      },
      loading: () => const LoadingWidget(),
      error: (error, stack) => Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text('Error loading categories: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(categoriesProvider);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, ServiceCategory category) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          context.push('/category/${category.id}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon - you can use category.icon if it's an asset path
              // For now using a placeholder icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_laundry_service,
                  size: 26,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  category.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (category.duration != null) ...[
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    category.duration!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 10,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFragrancesList(BuildContext context) {
    final fragrancesAsync = ref.watch(fragrancesProvider);
    final selectedFragranceId = ref.watch(selectedFragranceProvider);

    // Auto-select first fragrance if none is selected and fragrances are loaded
    fragrancesAsync.whenData((fragrances) {
      if (fragrances.isNotEmpty && selectedFragranceId == null && !_hasAutoSelectedFragrance) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _hasAutoSelectedFragrance = true;
          ref.read(selectedFragranceProvider.notifier).state = fragrances.first.id;
        });
      }
    });

    return fragrancesAsync.when(
      data: (fragrances) {
        if (fragrances.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No fragrances available'),
            ),
          );
        }

        return SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: fragrances.length,
            itemBuilder: (context, index) {
              final fragrance = fragrances[index];
              return _buildFragranceCard(context, fragrance);
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: LoadingWidget()),
      ),
      error: (error, stack) => SizedBox(
        height: 120,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 32, color: Colors.red),
              const SizedBox(height: 8),
              Text(
                'Error loading fragrances',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFragranceCard(BuildContext context, FragranceModel fragrance) {
    final selectedFragranceId = ref.watch(selectedFragranceProvider);
    final isSelected = selectedFragranceId == fragrance.id;

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: isSelected ? 4 : 2,
        color: isSelected ? AppTheme.primaryBlue.withOpacity(0.1) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isSelected
              ? BorderSide(color: AppTheme.primaryBlue, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: () {
            // Toggle selection
            if (isSelected) {
              ref.read(selectedFragranceProvider.notifier).state = null;
            } else {
              ref.read(selectedFragranceProvider.notifier).state = fragrance.id;
            }
            
            // Show confirmation
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isSelected 
                    ? 'Fragrance deselected' 
                    : '${fragrance.name} selected for cart'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Fragrance icon
                Stack(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryBlue
                            : AppTheme.primaryBlue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.air,
                        size: 26,
                        color: isSelected ? Colors.white : AppTheme.primaryBlue,
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    fragrance.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppTheme.primaryBlue : null,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.redAccent : Colors.black87;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade500),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      tileColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      dense: true,
    );
  }
}

