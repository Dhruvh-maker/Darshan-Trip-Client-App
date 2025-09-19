import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/transaction_model.dart';
import 'package:flutter/material.dart';

class WalletViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _myReferralCode;
  double _walletBalance = 0.0;
  List<WalletTransaction> _transactions = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _lastFetchedUserId;

  String? get myReferralCode => _myReferralCode;
  double get walletBalance => _walletBalance;
  List<WalletTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  WalletViewModel() {
    print("🔥 WalletViewModel constructor called");
    _initializeWallet();
  }

  Future<void> _initializeWallet() async {
    print("🔥 Initializing wallet...");

    // First try to load cached data
    await _loadCachedWalletData();

    // Check SharedPreferences for user session first
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final userPhone = prefs.getString('userPhone');

    if (isLoggedIn && userPhone != null) {
      print("🔥 User session found in SharedPreferences: $userPhone");
      await fetchWalletDataBasedOnPhone(userPhone);
      return;
    }

    // Fallback to Firebase Auth if SharedPreferences doesn't have session
    User? currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.phoneNumber != null) {
      print("🔥 User found in Firebase Auth: ${currentUser.phoneNumber}");
      await fetchWalletData();
    } else {
      print("🔥 No user session found, waiting for login");
      // Listen for auth changes as fallback
      _auth.authStateChanges().listen((User? user) {
        if (user != null &&
            user.phoneNumber != null &&
            (_lastFetchedUserId != user.uid)) {
          print("🔥 Auth state changed, user logged in: ${user.phoneNumber}");
          _lastFetchedUserId = user.uid;
          fetchWalletData();
        } else if (user == null) {
          print("🔥 User logged out via Firebase Auth");
          _checkSharedPreferencesSession();
        }
      });
    }
  }

  // Check SharedPreferences session when Firebase Auth user is null
  Future<void> _checkSharedPreferencesSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final userPhone = prefs.getString('userPhone');

    if (!isLoggedIn || userPhone == null) {
      print("🔥 No valid session found, clearing wallet data");
      _clearWalletData();
    }
  }

  // Cache wallet data to SharedPreferences
  Future<void> _cacheWalletData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('walletBalance', _walletBalance);
      await prefs.setString('myReferralCode', _myReferralCode ?? '');
      print(
        "✅ Wallet data cached: $_walletBalance, referral: $_myReferralCode",
      );
    } catch (e) {
      print("❌ Error caching wallet data: $e");
    }
  }

  // Load cached wallet data
  Future<void> _loadCachedWalletData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _walletBalance = prefs.getDouble('walletBalance') ?? 0.0;
      _myReferralCode = prefs.getString('myReferralCode') ?? '';

      if (_walletBalance > 0 || _myReferralCode!.isNotEmpty) {
        print(
          "✅ Loaded cached wallet data: $_walletBalance, referral: $_myReferralCode",
        );
        notifyListeners();
      }
    } catch (e) {
      print("❌ Error loading cached wallet data: $e");
    }
  }

  void _clearWalletData() {
    _myReferralCode = null;
    _walletBalance = 0.0;
    _transactions = [];
    _isLoading = false;
    _isInitialized = false;
    _lastFetchedUserId = null;

    // Clear cache
    _clearCachedData();

    notifyListeners();
    print("🔥 Wallet data cleared");
  }

  Future<void> _clearCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('walletBalance');
      await prefs.remove('myReferralCode');
    } catch (e) {
      print("❌ Error clearing cached data: $e");
    }
  }

  Future<void> fetchWalletData() async {
    print("🔥 fetchWalletData() called");

    if (_isLoading) {
      print("🔥 Already loading, skipping...");
      return;
    }

    _isLoading = true;
    notifyListeners();

    // Try Firebase Auth first
    User? currentUser = _auth.currentUser;
    String? phoneToUse;

    if (currentUser != null && currentUser.phoneNumber != null) {
      phoneToUse = currentUser.phoneNumber!;
      print("🔥 Using Firebase Auth phone: $phoneToUse");
    } else {
      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      phoneToUse = prefs.getString('userPhone');
      print("🔥 Using SharedPreferences phone: $phoneToUse");
    }

    if (phoneToUse == null) {
      print("❌ No phone number available for fetching wallet data");
      _isLoading = false;
      notifyListeners();
      return;
    }

    await _fetchWalletDataByPhone(phoneToUse);
  }

  Future<void> _fetchWalletDataByPhone(String phone) async {
    try {
      print("🔥 Fetching wallet data for phone: $phone");

      QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('contactNumber', isEqualTo: phone)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        DocumentSnapshot userDoc = userQuery.docs.first;

        final newReferralCode =
            userDoc.get('myReferralCode') as String? ?? 'N/A';
        final newBalance = (userDoc.get('walletBalance') ?? 0.0).toDouble();

        _myReferralCode = newReferralCode;
        _walletBalance = newBalance;

        print("✅ Wallet balance fetched: $_walletBalance");
        print("✅ Referral code fetched: $_myReferralCode");

        // Cache the data
        await _cacheWalletData();

        QuerySnapshot transactionSnapshot = await userDoc.reference
            .collection('walletTransactions')
            .orderBy('timestamp', descending: true)
            .limit(20)
            .get();

        _transactions = transactionSnapshot.docs
            .map((doc) => WalletTransaction.fromFirestore(doc))
            .toList();

        print("✅ ${_transactions.length} transactions fetched");
        _isInitialized = true;
      } else {
        print("❌ User not found in Firestore with phone: $phone");
        _myReferralCode = 'N/A';
        _walletBalance = 0.0;
        _transactions = [];
      }
    } catch (e) {
      print("❌ Error fetching wallet data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Force refresh - useful for debugging
  Future<void> forceRefresh() async {
    print("🔥 Force refresh called");
    _isInitialized = false;
    await fetchWalletData();
  }

  Future<void> fetchWalletDataBasedOnPhone(String phone) async {
    _isLoading = true;
    notifyListeners();

    String formattedPhone = phone.startsWith('+91') ? phone : '+91$phone';
    await _fetchWalletDataByPhone(formattedPhone);
  }

  // NEW METHOD: Simple deduction from wallet (as expected by BusDetailViewModel)
  Future<bool> deductFromWallet(double amount) async {
    if (_walletBalance < amount) {
      print("❌ Insufficient wallet balance: $_walletBalance < $amount");
      return false;
    }

    // Get user phone from SharedPreferences or Firebase Auth
    String? phoneToUse;
    User? currentUser = _auth.currentUser;

    if (currentUser != null && currentUser.phoneNumber != null) {
      phoneToUse = currentUser.phoneNumber!;
    } else {
      final prefs = await SharedPreferences.getInstance();
      phoneToUse = prefs.getString('userPhone');
    }

    if (phoneToUse == null) {
      print("❌ Cannot deduct from wallet. No user phone available.");
      return false;
    }

    try {
      QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('contactNumber', isEqualTo: phoneToUse)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        print("❌ User not found in Firestore.");
        return false;
      }

      DocumentSnapshot userDoc = userQuery.docs.first;

      // Update wallet balance locally and in Firestore
      _walletBalance -= amount;
      await userDoc.reference.update({'walletBalance': _walletBalance});

      // Cache updated balance
      await _cacheWalletData();

      // Add debit transaction
      final transaction = WalletTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: -amount,
        type: 'Bus Booking',
        description: 'Bus ticket booking payment',
        timestamp: Timestamp.now(),
      );

      await userDoc.reference
          .collection('walletTransactions')
          .doc(transaction.id)
          .set(transaction.toMap());

      _transactions.insert(0, transaction);
      print("✅ Amount deducted from wallet: $amount");
      notifyListeners();
      return true;
    } catch (e) {
      print("❌ Error deducting from wallet: $e");
      // Revert local balance on error
      _walletBalance += amount;
      return false;
    }
  }
  // Add this method to your WalletViewModel class

  Future<bool> addToWallet(double amount, String description) async {
    if (amount <= 0) {
      print("❌ Invalid amount to add: $amount");
      return false;
    }

    // Get user phone from SharedPreferences or Firebase Auth
    String? phoneToUse;
    User? currentUser = _auth.currentUser;

    if (currentUser != null && currentUser.phoneNumber != null) {
      phoneToUse = currentUser.phoneNumber!;
    } else {
      final prefs = await SharedPreferences.getInstance();
      phoneToUse = prefs.getString('userPhone');
    }

    if (phoneToUse == null) {
      print("❌ Cannot add to wallet. No user phone available.");
      return false;
    }

    try {
      QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('contactNumber', isEqualTo: phoneToUse)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        print("❌ User not found in Firestore.");
        return false;
      }

      DocumentSnapshot userDoc = userQuery.docs.first;

      // Update wallet balance locally and in Firestore
      _walletBalance += amount;
      await userDoc.reference.update({'walletBalance': _walletBalance});

      // Cache updated balance
      await _cacheWalletData();

      // Add credit transaction
      final transaction = WalletTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        type: 'Refund',
        description: description,
        timestamp: Timestamp.now(),
      );

      await userDoc.reference
          .collection('walletTransactions')
          .doc(transaction.id)
          .set(transaction.toMap());

      _transactions.insert(0, transaction);
      print("✅ Amount added to wallet: $amount");
      notifyListeners();
      return true;
    } catch (e) {
      print("❌ Error adding to wallet: $e");
      // Revert local balance on error
      _walletBalance -= amount;
      return false;
    }
  }

  Future<bool> processWalletPayment({
    required double amount,
    required String bookingId,
    required String description,
  }) async {
    if (_walletBalance < amount) {
      print("Insufficient wallet balance: $_walletBalance < $amount");
      return false;
    }

    // Get user phone from SharedPreferences or Firebase Auth
    String? phoneToUse;
    User? currentUser = _auth.currentUser;

    if (currentUser != null && currentUser.phoneNumber != null) {
      phoneToUse = currentUser.phoneNumber!;
    } else {
      final prefs = await SharedPreferences.getInstance();
      phoneToUse = prefs.getString('userPhone');
    }

    if (phoneToUse == null) {
      print("Cannot process wallet payment. No user phone available.");
      return false;
    }

    try {
      QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('contactNumber', isEqualTo: phoneToUse)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        print("User not found in Firestore.");
        return false;
      }

      DocumentSnapshot userDoc = userQuery.docs.first;

      // Update wallet balance
      _walletBalance -= amount;
      await userDoc.reference.update({'walletBalance': _walletBalance});

      // Cache updated balance
      await _cacheWalletData();

      // Add debit transaction
      final transaction = WalletTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: -amount,
        type: 'Booking Payment',
        description: description,
        timestamp: Timestamp.now(),
      );

      await userDoc.reference
          .collection('walletTransactions')
          .doc(transaction.id)
          .set(transaction.toMap());

      _transactions.insert(0, transaction);
      print("✅ Wallet payment processed: $amount for booking $bookingId");
      notifyListeners();
      return true;
    } catch (e) {
      print("Error processing wallet payment: $e");
      return false;
    }
  }

  // Public method to refresh wallet data when user logs in
  Future<void> refreshWalletAfterLogin() async {
    print("🔥 Refreshing wallet after login");
    _isInitialized = false;
    await fetchWalletData();
  }

  @override
  void dispose() {
    print("🔥 WalletViewModel disposed");
    super.dispose();
  }
}
