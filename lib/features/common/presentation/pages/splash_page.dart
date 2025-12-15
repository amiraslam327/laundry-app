import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundry_app/app/theme/app_theme.dart';
import 'package:laundry_app/features/common/presentation/providers/app_providers.dart';
import 'package:laundry_app/features/common/presentation/providers/providers.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
    _checkAuthAndNavigate();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    try {
      // Check if Firebase is initialized
      final apps = Firebase.apps;
      if (apps.isEmpty) {
        // Firebase not initialized, go to login
        if (mounted) context.go('/login');
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Check if user is admin
        try {
          final usersRepo = ref.read(usersRepositoryProvider);
          final userModel = await usersRepo.getUser(user.uid);
          
          if (mounted) {
            if (userModel?.role == 'admin') {
              context.go('/admin');
            } else {
              context.go('/home');
            }
          }
        } catch (e) {
          debugPrint('Error checking user role: $e');
          // Default to home if role check fails
          if (mounted) context.go('/home');
        }
      } else {
        if (mounted) context.go('/login');
      }
    } catch (e) {
      // If Firebase access fails, go to login
      debugPrint('Error checking auth: $e');
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF0096C7);
    const secondary = Color(0xFF90E0EF);
    const backgroundTop = Color(0xFFBFE7FF);
    const backgroundBottom = Color(0xFFE9F9FF);
    const accent = Color(0xFF00B4D8);
    const navy = Color(0xFF0A3D62);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [backgroundTop, backgroundBottom],
          ),
        ),
        child: Stack(
          children: [
            // Top wave
            Positioned(
              top: -80,
              left: -40,
              right: -40,
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  color: secondary.withOpacity(0.45),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.elliptical(200, 120),
                  ),
                ),
              ),
            ),
            // Bottom wave
            Positioned(
              bottom: -90,
              left: -50,
              right: -50,
              child: Container(
                height: 240,
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.35),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.elliptical(220, 130),
                  ),
                ),
              ),
            ),
            // Decorative bubbles
            ..._buildBubbles(primary, secondary, accent),
            // Centered logo and text with fade-in
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipOval(
                            child: Image.asset(
                              'assets/images/image copy.png',
                              fit: BoxFit.cover,
                              width: 130,
                              height: 130,
                            ),
                          ),
                          Positioned(
                            top: 26,
                            right: 32,
                            child: Icon(
                              Icons.bubble_chart_rounded,
                              size: 18,
                              color: accent,
                            ),
                          ),
                          Positioned(
                            bottom: 28,
                            left: 32,
                            child: Icon(
                              Icons.bubble_chart_rounded,
                              size: 14,
                              color: secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'LaundryApp',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: navy,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Laundry comes home',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: navy.withOpacity(0.75),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBubbles(Color primary, Color secondary, Color accent) {
    final bubbles = <Offset>[
      const Offset(40, 140),
      const Offset(320, 120),
      const Offset(60, 380),
      const Offset(280, 460),
      const Offset(200, 220),
      const Offset(120, 520),
      const Offset(340, 320),
    ];
    final sizes = [12.0, 16.0, 10.0, 14.0, 18.0, 10.0, 12.0];
    final colors = [
      primary.withOpacity(0.25),
      secondary.withOpacity(0.35),
      accent.withOpacity(0.22),
      primary.withOpacity(0.28),
      secondary.withOpacity(0.3),
      accent.withOpacity(0.18),
      primary.withOpacity(0.26),
    ];

    return List<Widget>.generate(bubbles.length, (index) {
      return Positioned(
        left: bubbles[index].dx,
        top: bubbles[index].dy,
        child: Container(
          width: sizes[index],
          height: sizes[index],
          decoration: BoxDecoration(
            color: colors[index],
            shape: BoxShape.circle,
          ),
        ),
      );
    });
  }
}

