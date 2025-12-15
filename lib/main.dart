import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:laundry_app/app/router/app_router.dart';
import 'package:laundry_app/app/theme/app_theme.dart';
import 'package:laundry_app/app/localization/app_localizations.dart';

// TODO: Uncomment and import after running: flutterfire configure
// import 'package:laundry_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  // Note: After running 'flutterfire configure', uncomment the import above
  // and change this line to: await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  bool firebaseInitialized = false;
  try {
    // Check if Firebase is already initialized
    if (Firebase.apps.isEmpty) {
      // Try to initialize with native config files
      await Firebase.initializeApp();
      debugPrint('Firebase initialized successfully with native config');
    } else {
      debugPrint('Firebase already initialized');
    }
    firebaseInitialized = true;
  } catch (e, stackTrace) {
    // If Firebase initialization fails, check:
    // 1. google-services.json is in android/app/
    // 2. Google Services plugin is applied in build.gradle.kts
    // 3. Package name in google-services.json matches applicationId in build.gradle.kts
    // 4. Run 'flutterfire configure' for proper setup
    debugPrint('Firebase initialization error: $e');
    debugPrint('Stack trace: $stackTrace');
    debugPrint('Please ensure:');
    debugPrint('1. google-services.json exists in android/app/');
    debugPrint('2. Google Services plugin is applied in build.gradle.kts');
    debugPrint('3. Package name in google-services.json matches applicationId');
    debugPrint('4. Run "flutterfire configure" for proper setup');
    debugPrint('');
    debugPrint('To fix this error:');
    debugPrint('1. Run: dart pub global activate flutterfire_cli');
    debugPrint('2. Run: flutterfire configure');
    debugPrint('3. Uncomment the firebase_options.dart import above');
    debugPrint('4. Update Firebase.initializeApp() to use DefaultFirebaseOptions.currentPlatform');
    // Don't continue - Firebase is required for this app
    // The app will show an error screen if Firebase fails to initialize
  }
  
  runApp(
    ProviderScope(
      child: LaundryApp(firebaseInitialized: firebaseInitialized),
    ),
  );
}

class LaundryApp extends StatelessWidget {
  final bool firebaseInitialized;
  
  const LaundryApp({super.key, this.firebaseInitialized = true});

  @override
  Widget build(BuildContext context) {
    if (!firebaseInitialized) {
      return MaterialApp(
        title: 'Laundry App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const FirebaseErrorScreen(),
      );
    }
    
    return MaterialApp.router(
      title: 'Laundry App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

class FirebaseErrorScreen extends StatelessWidget {
  const FirebaseErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              Text(
                'Firebase Configuration Error',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Firebase failed to initialize. Please check:',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const Text(
                '1. google-services.json exists in android/app/\n'
                '2. Google Services plugin is applied in build.gradle.kts\n'
                '3. Package name matches applicationId\n'
                '4. Run "flutterfire configure"',
                textAlign: TextAlign.left,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
