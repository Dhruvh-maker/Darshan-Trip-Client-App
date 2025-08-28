import 'package:darshan_trip/features/auth/authguard/auth_guard.dart';
import 'package:darshan_trip/features/home/view/bus_detail_screen.dart';
import 'package:darshan_trip/features/home/view/home_screen.dart';
import 'package:darshan_trip/features/home/view/search_results_screen.dart';
import 'package:darshan_trip/features/mybookings/view/my_bookings_screen.dart';
import 'package:darshan_trip/features/profile/view/about_screen.dart';
import 'package:darshan_trip/features/profile/view/edit_profile_screen.dart';
import 'package:darshan_trip/features/profile/view/help_screen.dart';
import 'package:darshan_trip/features/profile/view/logout_screen.dart';
import 'package:darshan_trip/features/profile/view/passengers_screen.dart';
import 'package:darshan_trip/features/profile/view/personal_info_screen.dart';
import 'package:darshan_trip/features/profile/view/rate_app_screen.dart';
import 'package:darshan_trip/features/profile/view/referrals_screen.dart';
import 'package:darshan_trip/features/profile/view/wallet_screen.dart';
import 'package:flutter/material.dart';
import '../features/splash/view/splash_screen.dart';
import '../features/onboarding/view/onboarding_screen.dart';
import '../features/auth/view/login_screen.dart';
import '../features/auth/view/signup_screen.dart';
import '../features/auth/view/otp_screen.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    // Public routes (no authentication required)
    '/': (context) => const SplashScreen(),
    '/onboarding': (context) => const OnboardingScreen(),
    '/login': (context) => const LoginScreen(),
    '/signup': (context) => const SignupScreen(),
    '/otp': (context) => const OTPScreen(),

    // Protected routes (authentication required) - wrapped with AuthGuard
    '/home': (context) => const AuthGuard(child: HomeScreen()),

    '/search-results': (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      return AuthGuard(
        child: SearchResultsScreen(
          sourceCity: args?['sourceCity'] as String? ?? '',
          destinationCity: args?['destinationCity'] as String? ?? '',
          selectedDate: args?['selectedDate'] as DateTime? ?? DateTime.now(),
        ),
      );
    },

    '/bus-detail': (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      if (args == null ||
          !args.containsKey('bus') ||
          !args.containsKey('selectedDate')) {
        // Changed condition
        return const Scaffold(
          body: Center(child: Text('Invalid arguments for Bus Detail')),
        );
      }
      return AuthGuard(
        child: BusDetailScreen(
          bus: args['bus'] as Map<String, dynamic>,
          sourceCity: args['sourceCity'] as String?,
          destinationCity: args['destinationCity'] as String?,
          selectedDate:
              args['selectedDate'] as DateTime, // Added this required parameter
        ),
      );
    },

    '/bookings': (context) => const AuthGuard(child: MyBookingsScreen()),

    '/personal-info': (context) => const AuthGuard(child: PersonalInfoScreen()),

    '/passengers': (context) => const AuthGuard(child: PassengersScreen()),

    '/wallet': (context) => const AuthGuard(child: WalletScreen()),

    '/referrals': (context) => const AuthGuard(child: ReferralsScreen()),

    '/logout': (context) => const AuthGuard(child: LogoutScreen()),
    '/edit-profile': (context) => const EditProfileScreen(),

    // Semi-protected routes (can be accessed but with proper handling)
    '/about': (context) => const AboutScreen(),
    '/rate-app': (context) => const RateAppScreen(),
    '/help': (context) => const HelpScreen(),
  };
}
