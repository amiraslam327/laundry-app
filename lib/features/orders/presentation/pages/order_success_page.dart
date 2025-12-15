import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:laundry_app/app/localization/app_localizations.dart';
import 'package:laundry_app/app/theme/app_theme.dart';
import 'package:laundry_app/features/common/presentation/widgets/app_button.dart';
import 'package:laundry_app/features/common/presentation/providers/app_providers.dart';

class OrderSuccessPage extends ConsumerWidget {
  final String orderId;

  const OrderSuccessPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 80,
                  color: AppTheme.success,
                ),
              ),
              const SizedBox(height: 32),
              // Success message
              Text(
                l10n.orderSuccessful,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.orderPlacedMessage,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // Buttons
              AppButton(
                text: l10n.trackYourPickup,
                onPressed: () {
                  // Refresh orders list before navigating
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    ref.invalidate(orderListProvider(user.uid));
                  }
                  context.go('/orders/$orderId');
                },
              ),
              const SizedBox(height: 16),
              AppButton(
                text: l10n.backToHome,
                isOutlined: true,
                onPressed: () {
                  context.go('/home');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

