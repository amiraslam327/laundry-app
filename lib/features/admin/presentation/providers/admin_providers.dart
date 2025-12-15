import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundry_app/features/common/presentation/providers/app_providers.dart';
import 'package:laundry_app/features/common/domain/models/user_model.dart';

/// Provider to check if current user is admin
final isAdminProvider = FutureProvider<bool>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  try {
    final userModelAsync = ref.watch(userProvider);
    return userModelAsync.when(
      data: (userModel) => userModel.role == 'admin',
      loading: () => false,
      error: (_, __) => false,
    );
  } catch (e) {
    return false;
  }
});

/// Provider to get current user model
final currentUserModelProvider = Provider<UserModel?>((ref) {
  final userModelAsync = ref.watch(userProvider);
  return userModelAsync.valueOrNull;
});

