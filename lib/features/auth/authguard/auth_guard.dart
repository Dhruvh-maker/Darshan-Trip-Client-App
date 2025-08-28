import 'package:darshan_trip/features/auth/view/login_screen.dart';
import 'package:darshan_trip/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Enhanced AuthGuard widget to protect authenticated routes
class AuthGuard extends StatelessWidget {
  final Widget child;
  final bool redirectToLogin;
  final bool preventBackNavigation;

  const AuthGuard({
    super.key,
    required this.child,
    this.redirectToLogin = true,
    this.preventBackNavigation =
        true, // Prevent going back to protected screens
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authVM, _) {
        // If user is logged in, show the protected screen with back prevention
        if (authVM.isLoggedIn) {
          // Wrap with WillPopScope to handle back button
          return preventBackNavigation
              ? WillPopScope(
                  onWillPop: () async {
                    // Allow normal back navigation within authenticated screens
                    return true;
                  },
                  child: child,
                )
              : child;
        }

        // If not logged in, prevent back navigation and redirect
        return WillPopScope(
          onWillPop: () async {
            // Prevent going back to authenticated screens when logged out
            return false;
          },
          child: redirectToLogin
              ? const LoginScreen()
              : const Scaffold(
                  backgroundColor: Color(0xFF2B1B15),
                  body: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

/// AuthAwareWidget that shows different content based on auth state
class AuthAwareWidget extends StatelessWidget {
  final Widget authenticatedChild;
  final Widget unauthenticatedChild;

  const AuthAwareWidget({
    super.key,
    required this.authenticatedChild,
    required this.unauthenticatedChild,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authVM, _) {
        if (authVM.isLoggedIn) {
          return authenticatedChild;
        }
        return unauthenticatedChild;
      },
    );
  }
}

/// Mixin for screens that need authentication
mixin AuthenticationMixin {
  void checkAuthAndNavigate(BuildContext context, String route) {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    if (authVM.isLoggedIn) {
      Navigator.pushNamed(context, route);
    } else {
      // Clear stack and go to login
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (Route<dynamic> route) => false,
      );
    }
  }

  bool isAuthenticated(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    return authVM.isLoggedIn;
  }

  // Method to handle logout from any screen
  void performLogout(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    authVM.signOut(context);
  }
}
