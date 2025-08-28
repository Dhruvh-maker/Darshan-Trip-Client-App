import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/auth/viewmodel/auth_viewmodel.dart';
import '../../../features/profile/viewmodel/wallet_viewmodel.dart';

class SplashViewModel extends ChangeNotifier {
  bool _hasNavigated = false;

  Future<void> initApp(BuildContext context) async {
    if (_hasNavigated) return;

    print("🔥 SplashViewModel initApp() started");

    try {
      // Initialize user session from SharedPreferences
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      await authViewModel.initializeUserSession();

      // If user is logged in, ensure wallet data is fetched
      if (authViewModel.isLoggedIn) {
        print("🔥 User is logged in, ensuring wallet data is loaded");
        final walletViewModel = Provider.of<WalletViewModel>(
          context,
          listen: false,
        );

        // Force refresh wallet data to ensure it's up to date
        await walletViewModel.refreshWalletAfterLogin();

        print(
          "✅ Wallet data loaded: Balance=${walletViewModel.walletBalance}, "
          "ReferralCode=${walletViewModel.myReferralCode}",
        );
      } else {
        print("🔥 No user logged in, skipping wallet data fetch");
      }

      // Show splash for better UX
      await Future.delayed(const Duration(seconds: 2));

      _hasNavigated = true;

      if (context.mounted) {
        Navigator.pushReplacementNamed(
          context,
          authViewModel.isLoggedIn ? '/home' : '/onboarding',
        );
      }

      print("🔥 SplashViewModel initApp() completed");
    } catch (e) {
      print("❌ Error in SplashViewModel initApp(): $e");

      // Even if there's an error, navigate to prevent getting stuck
      _hasNavigated = true;
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    }
  }
}
