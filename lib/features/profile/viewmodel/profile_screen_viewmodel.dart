import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreenViewModel extends ChangeNotifier {
  // Profile Data
  String userName = "Loading...";
  String email = "Loading...";
  String gender = "Loading...";
  String age = "Loading...";
  String contactNumber = "Loading...";
  String kutiName = "Loading...";
  String profileImage =
      "https://ui-avatars.com/api/?name=User&size=72&background=F5A623&color=fff";

  final String backgroundImage =
      "https://plus.unsplash.com/premium_photo-1661963542752-9a8a1d72fb28?w=900&auto=format&fit=crop&q=60";

  // 🔥 FIX: Make sure isLoading is properly initialized and accessible
  bool _isLoading = true;
  bool get isLoading => _isLoading;
  String? localDocumentPath;

  Future<void> saveDocumentPath(String path) async {
    localDocumentPath = path;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('identityDocumentPath', path);

    notifyListeners();
  }

  Future<void> removeDocumentPath() async {
    localDocumentPath = null;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('identityDocumentPath');

    notifyListeners();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ProfileScreenViewModel() {
    fetchUserProfile();
  }

  // Fetch user profile from Firestore and SharedPreferences
  Future<void> fetchUserProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? phone = prefs.getString('userPhone');

      // ✅ Load saved document path on startup
      localDocumentPath = prefs.getString('identityDocumentPath');

      if (phone != null && phone.isNotEmpty) {
        QuerySnapshot userQuery = await _firestore
            .collection('users')
            .where('contactNumber', isEqualTo: phone)
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          var userData = userQuery.docs.first.data() as Map<String, dynamic>;
          userName = userData['name'] ?? "Unknown User";
          email = userData['email'] ?? "No Email";
          gender = userData['gender'] ?? "Not set";
          age = userData['age']?.toString() ?? "Not set";
          contactNumber = userData['contactNumber'] ?? "Not set";
          kutiName = userData['kutiName'] ?? "Not set";

          profileImage =
              "https://ui-avatars.com/api/?name=${Uri.encodeComponent(userName)}&size=72&background=F5A623&color=fff";
        } else {
          await _loadFromSharedPreferences(prefs);
        }
      } else {
        await _loadFromSharedPreferences(prefs);
      }
    } catch (e) {
      print("Error fetching user profile: $e");

      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await _loadFromSharedPreferences(prefs);
      } catch (fallbackError) {
        print("Fallback error: $fallbackError");
        userName = "Error Loading";
        email = "Error Loading";
        gender = "Error Loading";
        age = "Error Loading";
        contactNumber = "Error Loading";
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromSharedPreferences(SharedPreferences prefs) async {
    String? savedName = prefs.getString('userName');
    String? savedEmail = prefs.getString('userEmail');

    // ✅ Load saved document path
    localDocumentPath = prefs.getString('identityDocumentPath');

    if (savedName != null && savedEmail != null) {
      userName = savedName;
      email = savedEmail;
      profileImage =
          "https://ui-avatars.com/api/?name=${Uri.encodeComponent(userName)}&size=72&background=F5A623&color=fff";
    } else {
      userName = "Unknown User";
      email = "No Email";
      gender = prefs.getString('userGender') ?? "Not set";
      age = prefs.getString('userAge') ?? "Not set";
      contactNumber = prefs.getString('userPhone') ?? "Not set";
    }
  }

  // Navigation functions
  void onBookingsTap(BuildContext context) {
    Navigator.pushNamed(context, '/bookings');
  }

  void onPersonalInfoTap(BuildContext context) {
    Navigator.pushNamed(context, '/personal-info');
  }

  void onPassengersTap(BuildContext context) {
    Navigator.pushNamed(context, '/passengers');
  }

  void onWalletTap(BuildContext context) {
    Navigator.pushNamed(context, '/wallet');
  }

  void onPaymentMethodsTap(BuildContext context) {
    Navigator.pushNamed(context, '/payment-methods');
  }

  void onReferralsTap(BuildContext context) {
    Navigator.pushNamed(context, '/referrals');
  }

  void onKnowAboutTap(BuildContext context) {
    Navigator.pushNamed(context, '/about');
  }

  void onRateAppTap(BuildContext context) {
    Navigator.pushNamed(context, '/rate-app');
  }

  void onHelpTap(BuildContext context) {
    Navigator.pushNamed(context, '/help');
  }

  void onEditProfileTap(BuildContext context) {
    Navigator.pushNamed(context, '/edit-profile');
  }

  void onUploadIdentityTap(BuildContext context) {
    Navigator.pushNamed(context, '/upload-identity');
  }

  Future<void> uploadIdentityDocument(String filePath) async {
    try {
      print("Uploading file: $filePath");
      // TODO: Firebase Storage upload logic
    } catch (e) {
      print("Error uploading document: $e");
    }
  }

  // Update Personal Info

  Future<void> updatePersonalInfo(
    String newName,
    String newEmail,
    String newGender,
    String newAge,
    String newContactNumber,
    String newKutiya,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (newName.trim().isEmpty) {
        throw Exception("Name cannot be empty");
      }
      if (newEmail.trim().isEmpty || !_isValidEmail(newEmail)) {
        throw Exception("Please enter a valid email");
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');

      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({
          'name': newName.trim(),
          'email': newEmail.trim(),
          'gender': newGender.trim(),
          'age': newAge.trim(),
          'contactNumber': newContactNumber.trim(),
          'kutiName': newKutiya.trim(),
        });

        await prefs.setString('userName', newName.trim());
        await prefs.setString('userEmail', newEmail.trim());
        await prefs.setString('userGender', newGender.trim());
        await prefs.setString('userAge', newAge.trim());
        await prefs.setString('userPhone', newContactNumber.trim());

        userName = newName.trim();
        email = newEmail.trim();
        gender = newGender.trim();
        age = newAge.trim();
        contactNumber = newContactNumber.trim();
        kutiName = newKutiya.trim();
        profileImage =
            "https://ui-avatars.com/api/?name=${Uri.encodeComponent(userName)}&size=72&background=F5A623&color=fff";

        print("✅ Profile updated successfully");
      } else {
        throw Exception("User session not found");
      }
    } catch (e) {
      print("❌ Error updating profile: $e");
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Refresh profile data
  Future<void> refreshProfile() async {
    await fetchUserProfile();
  }

  Future<void> updatePersonalInfoWithCallback(
    String newName,
    String newEmail,
    String newGender,
    String newAge,
    String newContactNumber,
    String newKutiya, {
    Function()? onSuccess,
    Function(String error)? onError,
  }) async {
    try {
      await updatePersonalInfo(
        newName,
        newEmail,
        newGender,
        newAge,
        newContactNumber,
        newKutiya,
      );
      onSuccess?.call();
    } catch (e) {
      onError?.call(e.toString());
    }
  }
}
