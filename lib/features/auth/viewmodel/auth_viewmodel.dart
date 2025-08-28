import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:darshan_trip/features/profile/viewmodel/wallet_viewmodel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthViewModel extends ChangeNotifier {
  bool isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;

  // Add user state management
  String? _currentUserId;
  Map<String, dynamic>? _currentUserData;

  // Getters for current user
  String? get currentUserId => _currentUserId;
  Map<String, dynamic>? get currentUserData => _currentUserData;
  bool get isLoggedIn => _currentUserId != null;

  String _generateReferralCode(String name) {
    String formattedName = name.split(' ').join('').toUpperCase();
    if (formattedName.length > 6) {
      formattedName = formattedName.substring(0, 6);
    }
    String randomNumbers = (Random().nextInt(9000) + 1000).toString();
    return '$formattedName$randomNumbers';
  }

  void _showSnackBar(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    IconData icon = Icons.info,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Initialize user session from SharedPreferences
  Future<void> initializeUserSession() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final userId = prefs.getString('userId');

      if (isLoggedIn && userId != null) {
        _currentUserId = userId;

        // Fetch latest user data from Firestore
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          _currentUserData = userDoc.data();
          _currentUserData!['id'] = userDoc.id;
        }

        notifyListeners();
        print('✅ User session restored: $_currentUserId');
      }
    } catch (e) {
      print('❌ Error initializing user session: $e');
    }
  }

  // Send OTP to phone number
  Future<void> sendOTP(BuildContext context, String phone) async {
    isLoading = true;
    notifyListeners();

    try {
      String formattedPhone = phone.startsWith('+91') ? phone : '+91$phone';

      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          await _handleSuccessfulOTPLogin(context, formattedPhone);
        },
        verificationFailed: (FirebaseAuthException e) {
          isLoading = false;
          notifyListeners();
          _showSnackBar(
            context,
            message: "OTP Sending Failed: ${e.message}",
            backgroundColor: Colors.red.shade400,
            icon: Icons.error_outline,
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          isLoading = false;
          notifyListeners();
          Navigator.pushNamed(
            context,
            '/otp',
            arguments: {'phone': formattedPhone},
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      isLoading = false;
      notifyListeners();
      _showSnackBar(
        context,
        message: "Error: $e",
        backgroundColor: Colors.red.shade400,
        icon: Icons.error_outline,
      );
    }
  }

  // Verify OTP entered by user
  Future<void> verifyOTP(BuildContext context, String otp) async {
    isLoading = true;
    notifyListeners();

    try {
      if (_verificationId == null) {
        throw Exception(
          "Verification ID not found. Please try sending OTP again.",
        );
      }

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      String phone = userCredential.user!.phoneNumber!;

      QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('contactNumber', isEqualTo: phone)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        isLoading = false;
        notifyListeners();
        _showSnackBar(
          context,
          message: "User not found. Please sign up first.",
          backgroundColor: Colors.red.shade400,
          icon: Icons.error_outline,
        );
        return;
      }

      await _handleSuccessfulOTPLogin(context, phone);
    } catch (e) {
      isLoading = false;
      notifyListeners();
      _showSnackBar(
        context,
        message: "OTP Verification Failed: ${e.toString()}",
        backgroundColor: Colors.red.shade400,
        icon: Icons.error_outline,
      );
    }
  }

  // Helper method to handle successful OTP login
  Future<void> _handleSuccessfulOTPLogin(
    BuildContext context,
    String phone,
  ) async {
    try {
      QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('contactNumber', isEqualTo: phone)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception("User not found in database.");
      }

      DocumentSnapshot userDoc = userQuery.docs.first;
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // Set current user data
      _currentUserId = userDoc.id;
      _currentUserData = userData;
      _currentUserData!['id'] = userDoc.id;

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', userDoc.id);
      await prefs.setString('userPhone', phone);
      await prefs.setString('userName', userData['name']);
      await prefs.setString('userEmail', userData['email']);
      await prefs.setBool('isLoggedIn', true);

      // Force refresh wallet data after successful login
      await Provider.of<WalletViewModel>(
        context,
        listen: false,
      ).refreshWalletAfterLogin();

      _showSnackBar(
        context,
        message: "Login Successful! ✅",
        backgroundColor: Colors.green.shade400,
        icon: Icons.check_circle,
      );

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      _showSnackBar(
        context,
        message: "Error: $e",
        backgroundColor: Colors.red.shade400,
        icon: Icons.error_outline,
      );
    }
  }

  // FIXED: Password login for existing users - No Firebase Auth needed
  Future<void> loginWithPassword(
    BuildContext context,
    String phone,
    String password,
  ) async {
    isLoading = true;
    notifyListeners();

    try {
      String formattedPhone = phone.startsWith('+91') ? phone : '+91$phone';

      QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('contactNumber', isEqualTo: formattedPhone)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        isLoading = false;
        notifyListeners();
        _showSnackBar(
          context,
          message: "User not found. Please sign up first.",
          backgroundColor: Colors.red.shade400,
          icon: Icons.error_outline,
        );
        return;
      }

      DocumentSnapshot userDoc = userQuery.docs.first;
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String storedHashedPassword = userData['password'];
      String inputHashedPassword = _hashPassword(password);

      if (storedHashedPassword == inputHashedPassword) {
        // Set current user data
        _currentUserId = userDoc.id;
        _currentUserData = userData;
        _currentUserData!['id'] = userDoc.id;

        // Create anonymous Firebase Auth user for compatibility
        try {
          await _auth.signInAnonymously();
        } catch (e) {
          print('⚠️ Firebase Auth anonymous sign-in failed: $e');
          // Continue without Firebase Auth if it fails
        }

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', userDoc.id);
        await prefs.setString('userPhone', formattedPhone);
        await prefs.setString('userName', userData['name']);
        await prefs.setString('userEmail', userData['email']);
        await prefs.setBool('isLoggedIn', true);

        // Force refresh wallet data after successful login
        await Provider.of<WalletViewModel>(
          context,
          listen: false,
        ).refreshWalletAfterLogin();

        _showSnackBar(
          context,
          message: "Login Successful! ✅",
          backgroundColor: Colors.green.shade400,
          icon: Icons.check_circle,
        );

        Navigator.pushReplacementNamed(context, '/home');
      } else {
        isLoading = false;
        notifyListeners();
        _showSnackBar(
          context,
          message: "Invalid password",
          backgroundColor: Colors.red.shade400,
          icon: Icons.error_outline,
        );
      }
    } catch (e) {
      isLoading = false;
      notifyListeners();
      _showSnackBar(
        context,
        message: "Login Failed: ${e.toString()}",
        backgroundColor: Colors.red.shade400,
        icon: Icons.error_outline,
      );
    }
  }

  // Direct signup without OTP
  // Updated signUpDirectly method in AuthViewModel
  Future<void> signUpDirectly(
    BuildContext context, {
    required String name,
    required String age,
    required String gender,
    required String kutiName,
    required String email,
    required String phone,
    required String password,
    String? referralCode,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      String formattedPhone = phone.startsWith('+91') ? phone : '+91$phone';

      QuerySnapshot existingUser = await _firestore
          .collection('users')
          .where('contactNumber', isEqualTo: formattedPhone)
          .limit(1)
          .get();

      if (existingUser.docs.isNotEmpty) {
        isLoading = false;
        notifyListeners();
        _showSnackBar(
          context,
          message: "User already exists! Try logging in.",
          backgroundColor: Colors.orange.shade600,
          icon: Icons.error_outline,
        );
        return;
      }

      DocumentSnapshot? referrerDoc;
      bool hasValidReferral = false;

      if (referralCode != null && referralCode.isNotEmpty) {
        QuerySnapshot referrerQuery = await _firestore
            .collection('users')
            .where(
              'myReferralCode',
              isEqualTo: referralCode.trim().toUpperCase(),
            )
            .limit(1)
            .get();

        if (referrerQuery.docs.isEmpty) {
          isLoading = false;
          notifyListeners();
          _showSnackBar(
            context,
            message: "Invalid referral code.",
            backgroundColor: Colors.red.shade400,
            icon: Icons.error_outline,
          );
          return;
        }
        referrerDoc = referrerQuery.docs.first;
        hasValidReferral = true;
      }

      String uniqueId = DateTime.now().millisecondsSinceEpoch.toString();

      await _firestore.runTransaction((transaction) async {
        DocumentReference newUserRef = _firestore
            .collection('users')
            .doc(uniqueId);

        // Calculate wallet balance based on referral
        double initialWalletBalance = hasValidReferral
            ? 250.0
            : 200.0; // 250 if referred, 200 if not

        Map<String, dynamic> newUserData = {
          '_id': uniqueId,
          'name': name,
          'age': int.parse(age),
          'gender': gender,
          'kutiName': kutiName,
          'email': email,
          'contactNumber': formattedPhone,
          'password': _hashPassword(password),
          'myReferralCode': _generateReferralCode(name),
          'referredByCode': referralCode?.trim().toUpperCase() ?? null,
          'walletBalance': initialWalletBalance,
        };

        transaction.set(newUserRef, newUserData);

        // Add signup bonus transaction
        String signupTransactionId =
            '${uniqueId}_signup_${DateTime.now().millisecondsSinceEpoch}';
        transaction.set(
          newUserRef.collection('walletTransactions').doc(signupTransactionId),
          {
            'amount': 200.0,
            'type': 'Signup Bonus',
            'description': 'Welcome bonus for new user',
            'timestamp': FieldValue.serverTimestamp(),
          },
        );

        if (hasValidReferral && referrerDoc != null) {
          // Add referral bonus transaction for new user
          String referralBonusTransactionId =
              '${uniqueId}_referral_bonus_${DateTime.now().millisecondsSinceEpoch}';
          transaction.set(
            newUserRef
                .collection('walletTransactions')
                .doc(referralBonusTransactionId),
            {
              'amount': 50.0,
              'type': 'Referral Bonus',
              'description':
                  'Extra bonus for using referral code ${referralCode!.trim().toUpperCase()}',
              'timestamp': FieldValue.serverTimestamp(),
            },
          );

          // Update referrer's wallet balance
          double referrerBonus = 50.0;
          double currentBalance = (referrerDoc.get('walletBalance') ?? 0.0)
              .toDouble();

          transaction.update(referrerDoc.reference, {
            'walletBalance': currentBalance + referrerBonus,
          });

          // Add referral credit transaction for referrer
          String referrerTransactionId =
              '${referrerDoc.id}_referral_credit_${DateTime.now().millisecondsSinceEpoch}';
          transaction.set(
            referrerDoc.reference
                .collection('walletTransactions')
                .doc(referrerTransactionId),
            {
              'amount': referrerBonus,
              'type': 'Referral Credit',
              'description': 'Referral reward for inviting $name',
              'timestamp': FieldValue.serverTimestamp(),
            },
          );
        }
      });

      // Set current user data
      _currentUserId = uniqueId;
      _currentUserData = {
        'id': uniqueId,
        'name': name,
        'age': int.parse(age),
        'gender': gender,
        'kutiName': kutiName,
        'email': email,
        'contactNumber': formattedPhone,
        'myReferralCode': _generateReferralCode(name),
        'referredByCode': referralCode?.trim().toUpperCase(),
        'walletBalance': hasValidReferral ? 250.0 : 200.0,
      };

      // Create anonymous Firebase Auth user for compatibility
      try {
        await _auth.signInAnonymously();
      } catch (e) {
        print('⚠️ Firebase Auth anonymous sign-in failed: $e');
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', uniqueId);
      await prefs.setString('userPhone', formattedPhone);
      await prefs.setString('userName', name);
      await prefs.setString('userEmail', email);
      await prefs.setBool('isLoggedIn', true);

      // Force refresh wallet data after successful signup
      await Provider.of<WalletViewModel>(
        context,
        listen: false,
      ).refreshWalletAfterLogin();

      // Show appropriate success message
      String successMessage = hasValidReferral
          ? "Account created successfully! 🎊 ₹250 has been added to your wallet (₹200 signup bonus + ₹50 referral bonus)"
          : "Account created successfully! 🎊 ₹200 has been added to your wallet";

      _showSnackBar(
        context,
        message: successMessage,
        backgroundColor: Colors.green.shade400,
        icon: Icons.check_circle,
      );

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      isLoading = false;
      notifyListeners();
      _showSnackBar(
        context,
        message: "Signup Failed: ${e.toString()}",
        backgroundColor: Colors.red.shade400,
        icon: Icons.error_outline,
      );
    }
  }

  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Sign out user
  Future<void> signOut(BuildContext context) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Clear current user data
      _currentUserId = null;
      _currentUserData = null;

      await _auth.signOut();

      _showSnackBar(
        context,
        message: "Logged out successfully",
        backgroundColor: Colors.orange.shade600,
        icon: Icons.logout,
      );

      // CRITICAL: Use pushNamedAndRemoveUntil to clear entire navigation stack
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (Route<dynamic> route) => false, // This removes ALL previous routes
      );
    } catch (e) {
      _showSnackBar(
        context,
        message: "Sign out failed: ${e.toString()}",
        backgroundColor: Colors.red.shade400,
        icon: Icons.error_outline,
      );
    }
    notifyListeners();
  }
}
