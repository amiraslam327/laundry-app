import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:laundry_app/app/theme/app_theme.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/home'),
            tooltip: 'Go to User Home',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Card
            Card(
              color: AppTheme.primaryBlue,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.admin_panel_settings,
                      size: 56,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Admin Dashboard',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your laundry business',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Admin Actions Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: [
                _buildAdminCard(
                  context,
                  icon: Icons.local_laundry_service,
                  title: 'Add Laundry',
                  subtitle: 'Create new laundry',
                  color: Colors.blue,
                  onTap: () => context.push('/admin/add-laundry'),
                ),
                _buildAdminCard(
                  context,
                  icon: Icons.cleaning_services,
                  title: 'Add Service',
                  subtitle: 'Add service type',
                  color: Colors.green,
                  onTap: () => context.push('/admin/add-service'),
                ),
                _buildAdminCard(
                  context,
                  icon: Icons.inventory_2,
                  title: 'Add Service Item',
                  subtitle: 'Add items to service',
                  color: Colors.orange,
                  onTap: () => context.push('/admin/add-service-item'),
                ),
                _buildAdminCard(
                  context,
                  icon: Icons.attach_money,
                  title: 'Add Pricing',
                  subtitle: 'Manage pricing',
                  color: Colors.purple,
                  onTap: () => context.push('/admin/add-pricing'),
                ),
                _buildAdminCard(
                  context,
                  icon: Icons.description,
                  title: 'Full Model Details',
                  subtitle: 'Complete form generator',
                  color: Colors.teal,
                  onTap: () => context.push('/admin/model-details?type=laundry'),
                ),
                _buildAdminCard(
                  context,
                  icon: Icons.settings,
                  title: 'Seed Data',
                  subtitle: 'Seed sample data',
                  color: Colors.indigo,
                  onTap: () => context.push('/admin/seed'),
                ),
                _buildAdminCard(
                  context,
                  icon: Icons.admin_panel_settings,
                  title: 'Create Admin',
                  subtitle: 'Create admin user',
                  color: Colors.red,
                  onTap: () => context.push('/admin/create-admin'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Quick Stats (placeholder)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Stats',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(context, 'Laundries', '0', Icons.local_laundry_service),
                        _buildStatItem(context, 'Services', '0', Icons.cleaning_services),
                        _buildStatItem(context, 'Orders', '0', Icons.receipt_long),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16), // Extra bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
          child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
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
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: AppTheme.primaryBlue),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

