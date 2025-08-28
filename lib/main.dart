import 'package:darshan_trip/core/services/local_notifications_service.dart';
import 'package:darshan_trip/features/home/viewmodel/home_viewmodel.dart';
import 'package:darshan_trip/features/profile/viewmodel/profile_screen_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add this import
import 'features/splash/view/splash_screen.dart';
import 'features/splash/viewmodel/splash_viewmodel.dart';
import 'features/onboarding/viewmodel/onboarding_viewmodel.dart';
import 'features/auth/viewmodel/auth_viewmodel.dart';
import 'features/mybookings/viewmodel/bookings_viewmodel.dart';
import 'features/notifications/viewmodel/notifications_viewmodel.dart';
import 'features/profile/viewmodel/wallet_viewmodel.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();
  print("Firebase Initialized Successfully");

  await LocalNotificationService().initialize();

  // Enable Firestore offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  print("Firestore Offline Persistence Enabled");

  // Configure App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );
  print("Firebase App Check Configured");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SplashViewModel()),
        ChangeNotifierProvider(create: (_) => OnboardingViewModel()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => BookingsViewModel()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationsViewModel()),
        ChangeNotifierProvider(create: (_) => WalletViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileScreenViewModel()),
      ],
      child: Consumer<AuthViewModel>(
        builder: (context, authVM, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Darshan Trip',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.orange,
                primary: Colors.orange.shade600,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: IconThemeData(color: Colors.black87),
                titleTextStyle: TextStyle(
                  color: Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            routes: AppRoutes.routes,
            initialRoute: '/',
            navigatorObservers: [AuthNavigationObserver()],
          );
        },
      ),
    );
  }
}

class AuthNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _checkAuthForProtectedRoutes(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _checkAuthForProtectedRoutes(newRoute);
    }
  }

  void _checkAuthForProtectedRoutes(Route<dynamic> route) {
    final protectedRoutes = [
      '/home',
      '/bookings',
      '/wallet',
      '/personal-info',
      '/passengers',
      '/payment-methods',
      '/referrals',
      '/logout',
    ];

    final routeName = route.settings.name;
    if (routeName != null && protectedRoutes.contains(routeName)) {
      print('Navigating to protected route: $routeName');
    }
  }
}
