import 'package:flutter/material.dart';
import 'package:laundry_app/utils/firestore_seeder_helper.dart';

/// Admin page to seed Firestore with sample data
/// 
/// Add this route to your app_router.dart:
/// GoRoute(
///   path: '/admin/seed',
///   builder: (context, state) => const AdminSeedPage(),
/// ),
class AdminSeedPage extends StatefulWidget {
  const AdminSeedPage({super.key});

  @override
  State<AdminSeedPage> createState() => _AdminSeedPageState();
}

class _AdminSeedPageState extends State<AdminSeedPage> {
  final FirestoreSeederHelper _seeder = FirestoreSeederHelper();
  bool _isLoading = false;
  String? _message;
  bool _isError = false;

  Future<void> _seedAll() async {
    setState(() {
      _isLoading = true;
      _message = null;
      _isError = false;
    });

    try {
      await _seeder.seedSampleData();
      setState(() {
        _message = '✅ All data seeded successfully!';
        _isError = false;
      });
    } catch (e) {
      setState(() {
        _message = '❌ Error: $e';
        _isError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _seedFragrances() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await _seeder.seedFragrances();
      setState(() {
        _message = '✅ Fragrances seeded successfully!';
        _isError = false;
      });
    } catch (e) {
      setState(() {
        _message = '❌ Error: $e';
        _isError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _seedLaundries() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await _seeder.seedLaundries();
      setState(() {
        _message = '✅ Laundries seeded successfully!';
        _isError = false;
      });
    } catch (e) {
      setState(() {
        _message = '❌ Error: $e';
        _isError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _seedServices() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await _seeder.seedServices();
      setState(() {
        _message = '✅ Services seeded successfully!';
        _isError = false;
      });
    } catch (e) {
      setState(() {
        _message = '❌ Error: $e';
        _isError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _seedCategories() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await _seeder.seedServiceCategories();
      setState(() {
        _message = '✅ Service categories seeded successfully!';
        _isError = false;
      });
    } catch (e) {
      setState(() {
        _message = '❌ Error: $e';
        _isError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will delete all seeded data from Firestore. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await _seeder.clearAllData();
      setState(() {
        _message = '✅ All data cleared successfully!';
        _isError = false;
      });
    } catch (e) {
      setState(() {
        _message = '❌ Error: $e';
        _isError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Seeder'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_message != null)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _isError ? Colors.red[50] : Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isError ? Colors.red : Colors.green,
                  ),
                ),
                child: Text(
                  _message!,
                  style: TextStyle(
                    color: _isError ? Colors.red[900] : Colors.green[900],
                  ),
                ),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seed Sample Data',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _seedAll,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Seed All Collections'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seed Individual Collections',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildSeedButton(
                      'Seed Fragrances',
                      Icons.air,
                      _seedFragrances,
                    ),
                    const SizedBox(height: 8),
                    _buildSeedButton(
                      'Seed Laundries',
                      Icons.local_laundry_service,
                      _seedLaundries,
                    ),
                    const SizedBox(height: 8),
                    _buildSeedButton(
                      'Seed Services',
                      Icons.cleaning_services,
                      _seedServices,
                    ),
                    const SizedBox(height: 8),
                    _buildSeedButton(
                      'Seed Categories',
                      Icons.category,
                      _seedCategories,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Danger Zone',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.red,
                          ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _clearAll,
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Clear All Seeded Data'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeedButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }
}

