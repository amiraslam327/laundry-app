import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundry_app/app/theme/app_theme.dart';

class PaymentPage extends ConsumerStatefulWidget {
  final double totalAmount;

  const PaymentPage({
    super.key,
    required this.totalAmount,
  });

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  String _selectedMethod = 'cod';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Payment Method'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Amount
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      'SAR ${widget.totalAmount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Payment Methods
            Text(
              'Payment Methods',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            // COD Option
            Card(
              child: RadioListTile<String>(
                title: const Text('Cash on Delivery (COD)'),
                subtitle: const Text('Pay when you receive your order'),
                value: 'cod',
                groupValue: _selectedMethod,
                onChanged: (value) {
                  setState(() => _selectedMethod = value!);
                },
                secondary: const Icon(Icons.money),
              ),
            ),
            const SizedBox(height: 12),
            // Online Payment Option
            Card(
              child: RadioListTile<String>(
                title: const Text('Online Payment'),
                subtitle: const Text('Pay securely online'),
                value: 'online',
                groupValue: _selectedMethod,
                onChanged: (value) {
                  setState(() => _selectedMethod = value!);
                },
                secondary: const Icon(Icons.payment),
              ),
            ),
            const SizedBox(height: 32),
            // Info Card
            if (_selectedMethod == 'online')
              Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Online payment integration coming soon. Please use COD for now.',
                          style: TextStyle(color: Colors.orange[900]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            // Proceed Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedMethod == 'online') {
                    // TODO: Implement online payment
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Online payment coming soon. Please use COD.'),
                      ),
                    );
                  } else {
                    // Return to cart with payment method selected
                    context.pop(_selectedMethod);
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Proceed'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

