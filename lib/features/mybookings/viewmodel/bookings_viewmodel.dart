import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookingsViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _bookings = [];
  Map<String, dynamic>? _operatorPolicy;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get bookings => _bookings;
  Map<String, dynamic>? get operatorPolicy => _operatorPolicy;
  Map<String, dynamic>? _modifyPolicy;
  Map<String, dynamic>? _cancelPolicy;

  Map<String, dynamic>? get modifyPolicy => _modifyPolicy;
  Map<String, dynamic>? get cancelPolicy => _cancelPolicy;

  /// Fetch operator policy from Firestore
  Future<void> fetchOperatorPolicy() async {
    try {
      final snapshot = await _firestore
          .collection('policies')
          .where('title', isEqualTo: 'operatorpolicy')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        _operatorPolicy = snapshot.docs.first.data();
      } else {
        // Create default operator policy if not exists
        await _createDefaultOperatorPolicy();
      }
    } catch (e) {
      print('❌ Error fetching operator policy: $e');
      // Use default policy content if fetch fails
      _operatorPolicy = {
        'title': 'operatorpolicy',
        'content': _getDefaultPolicyContent(),
      };
    }
    notifyListeners();
  }

  Future<void> fetchModifyPolicy() async {
    try {
      final snapshot = await _firestore
          .collection('policies')
          .where('title', isEqualTo: 'modifypolicy')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        _modifyPolicy = snapshot.docs.first.data();
      } else {
        // Create default modify policy if not exists
        await _createDefaultModifyPolicy();
      }
    } catch (e) {
      print('❌ Error fetching modify policy: $e');
      _modifyPolicy = {
        'title': 'modifypolicy',
        'content': _getDefaultModifyPolicyContent(),
      };
    }
    notifyListeners();
  }

  /// Fetch cancel policy from Firestore
  Future<void> fetchCancelPolicy() async {
    try {
      final snapshot = await _firestore
          .collection('policies')
          .where('title', isEqualTo: 'cancelpolicy')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        _cancelPolicy = snapshot.docs.first.data();
      } else {
        // Create default cancel policy if not exists
        await _createDefaultCancelPolicy();
      }
    } catch (e) {
      print('❌ Error fetching cancel policy: $e');
      _cancelPolicy = {
        'title': 'cancelpolicy',
        'content': _getDefaultCancelPolicyContent(),
      };
    }
    notifyListeners();
  }

  Future<void> _createDefaultModifyPolicy() async {
    try {
      final defaultPolicy = {
        'title': 'modifypolicy',
        'content': _getDefaultModifyPolicyContent(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('policies').add(defaultPolicy);
      _modifyPolicy = defaultPolicy;
      print('✅ Default modify policy created');
    } catch (e) {
      print('❌ Error creating default modify policy: $e');
    }
  }

  /// Create default cancel policy in Firestore
  Future<void> _createDefaultCancelPolicy() async {
    try {
      final defaultPolicy = {
        'title': 'cancelpolicy',
        'content': _getDefaultCancelPolicyContent(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('policies').add(defaultPolicy);
      _cancelPolicy = defaultPolicy;
      print('✅ Default cancel policy created');
    } catch (e) {
      print('❌ Error creating default cancel policy: $e');
    }
  }

  String _getDefaultModifyPolicyContent() {
    return '''
MODIFICATION POLICY (TEST VERSION)

1. MODIFICATION RULES:
• Unlimited modifications allowed
• Changes to date, seats, or passenger details permitted
• No fees for modifications in testing mode
• Modifications must be made at least 2 hours before departure

2. RESTRICTIONS:
• Date changes limited to 1 per booking
• Seat changes subject to availability

3. PROCESS:
• Changes processed instantly
• Contact support for complex modifications

For queries, contact: support@busoperator.com
''';
  }

  /// Default cancel policy content
  String _getDefaultCancelPolicyContent() {
    return '''
CANCELLATION POLICY (TEST VERSION)

1. CANCELLATION RULES:
• Cancellation allowed at any time
• Full refund for all cancellations
• No time restrictions in testing mode

2. REFUND PROCESS:
• Instant refunds
• 100% refund guaranteed

3. RESTRICTIONS:
• None in testing mode

For queries, contact: support@busoperator.com
''';
  }

  /// Create default operator policy in Firestore
  Future<void> _createDefaultOperatorPolicy() async {
    try {
      final defaultPolicy = {
        'title': 'operatorpolicy',
        'content': _getDefaultPolicyContent(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('policies').add(defaultPolicy);
      _operatorPolicy = defaultPolicy;
      print('✅ Default operator policy created');
    } catch (e) {
      print('❌ Error creating default operator policy: $e');
    }
  }

  /// Default policy content
  String _getDefaultPolicyContent() {
    return '''
BOOKING CANCELLATION & MODIFICATION POLICY (TEST VERSION)

1. CANCELLATION POLICY:
• Cancellation allowed at any time
• Full refund for all cancellations
• No time restrictions

2. MODIFICATION POLICY:
• Unlimited modifications allowed
• No fees for any changes
• All changes permitted

3. REFUND PROCESS:
• Instant refunds
• 100% refund guaranteed

4. TESTING MODE:
• All restrictions removed for testing
• Cancel anytime without penalties

For queries, contact: support@busoperator.com
''';
  }

  /// Creates a new booking with the current user's ID from SharedPreferences
  Future<String?> createBooking({
    required Map<String, dynamic> busData,
    required List<String> selectedSeats,
    required DateTime travelDate,
    required String pickupPoint,
    required double totalAmount,
    required String passengerName,
    required String passengerContact,
    required String sourceCity,
    required String destinationCity,
    required List<Map<String, dynamic>> passengers,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Get current user ID from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');

      if (userId == null || userId.isEmpty) {
        throw 'User not logged in. Please login first.';
      }

      // Validate inputs
      if (passengerName.isEmpty) {
        throw 'Passenger name cannot be empty';
      }
      if (passengerContact.isEmpty ||
          !RegExp(r'^\d{10}$').hasMatch(passengerContact)) {
        throw 'Invalid passenger contact number';
      }
      if (selectedSeats.isEmpty) {
        throw 'At least one seat must be selected';
      }

      // Convert seat strings to integers
      final seats = selectedSeats.map((seat) {
        final seatNum = int.tryParse(seat);
        if (seatNum == null) {
          throw 'Invalid seat number: $seat';
        }
        return seatNum;
      }).toList();

      // Use a transaction to ensure seat availability
      final docRef = await _firestore.runTransaction<String>((
        transaction,
      ) async {
        final bookingDateStr = DateFormat('yyyy-MM-dd').format(travelDate);
        final snapshot = await _firestore
            .collection('bookings')
            .where('busId', isEqualTo: busData['id']?.toString() ?? '')
            .where('bookingDate', isEqualTo: bookingDateStr)
            .where('status', isEqualTo: 'confirmed')
            .get();

        final bookedSeats = <int>{};
        for (var doc in snapshot.docs) {
          final data = doc.data();
          bookedSeats.addAll(
            (data['seats'] as List<dynamic>?)?.cast<int>() ?? [],
          );
        }

        // Check if any selected seats are already booked
        for (var seat in seats) {
          if (bookedSeats.contains(seat)) {
            throw 'Seat $seat is already booked';
          }
        }

        // Create booking with current user ID
        final bookingData = {
          'boarded': false,
          'boardingTime': null,
          'bookingDate': bookingDateStr,
          'busId': busData['id']?.toString() ?? '',
          'passengerName': passengerName,
          'passengerContact': passengerContact,
          'passengers': passengers,
          'pickupPoint': pickupPoint,
          'seats': seats,
          'status': 'confirmed',
          'totalFare': totalAmount,
          'tripId': busData['tripId']?.toString() ?? '',
          'userId': userId, // Use userId from SharedPreferences
          'createdAt': FieldValue.serverTimestamp(),
          'sourceCity': sourceCity,
          'destinationCity': destinationCity,
          'modificationCount': 0, // Track number of modifications
          'lastModifiedAt': null,
        };

        final newDocRef = _firestore.collection('bookings').doc();
        transaction.set(newDocRef, bookingData);
        return newDocRef.id;
      });

      print('✅ Booking created with ID: $docRef');
      return docRef;
    } catch (e) {
      _error = 'Failed to create booking: $e';
      print('❌ Error creating booking: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch only current user's bookings
  Future<void> fetchUserBookings() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Get current user ID from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');

      if (userId == null || userId.isEmpty) {
        _bookings = [];
        _error = 'No user logged in';
        print('❌ No user logged in, cannot fetch bookings');
        return;
      }

      print('🔍 Fetching bookings for user: $userId');

      // Fetch ONLY current user's bookings
      final snapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .get();

      print('✅ Fetched user bookings: ${snapshot.docs.length}');

      _bookings = [];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;

        // Fetch the bus document for each booking
        if (data['busId'] != null && data['busId'].toString().isNotEmpty) {
          try {
            final busDoc = await _firestore
                .collection('buses')
                .doc(data['busId'].toString())
                .get();
            if (busDoc.exists) {
              data['busData'] = busDoc.data();
            } else {
              data['busData'] = null;
              print('⚠️ Bus document not found for busId: ${data['busId']}');
            }
          } catch (e) {
            print(
              '❌ Error fetching bus details for busId ${data['busId']}: $e',
            );
            data['busData'] = null;
          }
        } else {
          data['busData'] = null;
        }

        _bookings.add(data);
      }

      // Sort bookings by creation date in memory (most recent first)
      _bookings.sort((a, b) {
        final aCreatedAt = a['createdAt'];
        final bCreatedAt = b['createdAt'];

        if (aCreatedAt is Timestamp && bCreatedAt is Timestamp) {
          return bCreatedAt.compareTo(aCreatedAt); // Descending order
        }

        // Fallback: put bookings without timestamp at the end
        if (aCreatedAt is Timestamp) return -1;
        if (bCreatedAt is Timestamp) return 1;
        return 0;
      });

      print('✅ User bookings with bus details loaded: ${_bookings.length}');
    } catch (e) {
      _error = 'Failed to fetch bookings: $e';
      _bookings = [];
      print('❌ Error fetching user bookings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cancel booking with policy validation
  Future<bool> cancelBooking(String bookingId) async {
    print('🔄 Starting cancelBooking for ID: $bookingId');

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Get current user ID to verify ownership
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? currentUserId = prefs.getString('userId');
      print('👤 Current User ID: $currentUserId');

      if (currentUserId == null || currentUserId.isEmpty) {
        print('❌ No user logged in');
        throw 'User not logged in';
      }

      // Verify the booking belongs to current user before cancelling
      print('🔍 Fetching booking document...');
      final bookingDoc = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (!bookingDoc.exists) {
        print('❌ Booking document does not exist');
        throw 'Booking not found';
      }

      final bookingData = bookingDoc.data() as Map<String, dynamic>;
      print('📄 Booking data: $bookingData');

      if (bookingData['userId'] != currentUserId) {
        print('❌ User ID mismatch: ${bookingData['userId']} != $currentUserId');
        throw 'Unauthorized to cancel this booking';
      }

      // Check current status
      final currentStatus = bookingData['status']?.toString() ?? '';
      print('📊 Current booking status: $currentStatus');

      if (currentStatus == 'cancelled') {
        print('⚠️ Booking is already cancelled');
        throw 'Booking is already cancelled';
      }

      // Perform the Firestore update
      print('💾 Updating Firestore document...');
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'lastModifiedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Firestore update successful');

      // Update local list immediately
      print('🔄 Updating local list...');
      final bookingIndex = _bookings.indexWhere((b) => b['id'] == bookingId);
      print('📍 Booking index in local list: $bookingIndex');

      if (bookingIndex != -1) {
        _bookings[bookingIndex]['status'] = 'cancelled';
        _bookings[bookingIndex]['cancelledAt'] = Timestamp.now();
        _bookings[bookingIndex]['lastModifiedAt'] = Timestamp.now();
        print('✅ Local list updated');
      } else {
        print('⚠️ Booking not found in local list');
      }

      print('✅ Booking cancelled successfully: $bookingId');

      // Force UI update
      notifyListeners();

      return true;
    } catch (e) {
      _error = 'Failed to cancel booking: $e';
      print('❌ Error cancelling booking: $e');
      print('❌ Error type: ${e.runtimeType}');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
      print('🏁 cancelBooking method completed');
    }
  }

  Future<void> verifyBookingStatus(String bookingId) async {
    try {
      print('🔍 Verifying booking status in Firestore...');
      final doc = await _firestore.collection('bookings').doc(bookingId).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        print('📊 Firestore status: ${data['status']}');
        print('📊 Cancelled at: ${data['cancelledAt']}');
      } else {
        print('❌ Document not found in Firestore');
      }
    } catch (e) {
      print('❌ Error verifying status: $e');
    }
  }

  /// IMPROVED: Check if booking can be cancelled/modified
  bool canCancelOrModifyBooking(Map<String, dynamic> booking) {
    final status = booking['status']?.toString().toLowerCase() ?? '';

    // For testing: Only check if status is confirmed
    return status == 'confirmed';
  }

  /// Modify booking (change date, seats, passenger details)
  Future<bool> modifyBooking({
    required String bookingId,
    DateTime? newTravelDate,
    List<String>? newSeats,
    String? newPassengerName,
    String? newPassengerContact,
    String? newPickupPoint,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? currentUserId = prefs.getString('userId');

      if (currentUserId == null) {
        throw 'User not logged in';
      }

      // Verify the booking belongs to current user
      final bookingDoc = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (!bookingDoc.exists) {
        throw 'Booking not found';
      }

      final bookingData = bookingDoc.data() as Map<String, dynamic>;
      if (bookingData['userId'] != currentUserId) {
        throw 'Unauthorized to modify this booking';
      }

      // Check modification limits
      final modificationCount = bookingData['modificationCount'] ?? 0;
      if (modificationCount >= 1 && newTravelDate != null) {
        throw 'Date modification allowed only once per booking';
      }

      // Check if modification is allowed based on time
      final currentBookingDateStr = bookingData['bookingDate']?.toString();
      if (currentBookingDateStr != null) {
        final currentBookingDate = DateFormat(
          'yyyy-MM-dd',
        ).parse(currentBookingDateStr);
        final now = DateTime.now();
        final timeDifference = currentBookingDate.difference(now);

        if (timeDifference.inHours < 2) {
          throw 'Modification not allowed less than 2 hours before departure';
        }
      }

      // Prepare update data
      Map<String, dynamic> updateData = {
        'lastModifiedAt': FieldValue.serverTimestamp(),
      };

      // Handle date change
      if (newTravelDate != null) {
        final newDateStr = DateFormat('yyyy-MM-dd').format(newTravelDate);

        // Check seat availability for new date
        if (newSeats != null) {
          final seatNumbers = newSeats
              .map((seat) => int.tryParse(seat) ?? 0)
              .toList();
          final availability = await _checkSeatAvailability(
            bookingData['busId']?.toString() ?? '',
            newDateStr,
            seatNumbers,
            excludeBookingId: bookingId,
          );

          if (!availability) {
            throw 'Selected seats not available for the new date';
          }

          updateData['seats'] = seatNumbers;
        }

        updateData['bookingDate'] = newDateStr;
        updateData['modificationCount'] = (modificationCount) + 1;
      }

      // Handle seat change only (same date)
      if (newSeats != null && newTravelDate == null) {
        final seatNumbers = newSeats
            .map((seat) => int.tryParse(seat) ?? 0)
            .toList();
        final availability = await _checkSeatAvailability(
          bookingData['busId']?.toString() ?? '',
          currentBookingDateStr ?? '',
          seatNumbers,
          excludeBookingId: bookingId,
        );

        if (!availability) {
          throw 'Selected seats not available';
        }

        updateData['seats'] = seatNumbers;
      }

      // Handle passenger details change
      if (newPassengerName != null && newPassengerName.isNotEmpty) {
        updateData['passengerName'] = newPassengerName;
      }

      if (newPassengerContact != null && newPassengerContact.isNotEmpty) {
        if (!RegExp(r'^\d{10}$').hasMatch(newPassengerContact)) {
          throw 'Invalid passenger contact number';
        }
        updateData['passengerContact'] = newPassengerContact;
      }

      if (newPickupPoint != null && newPickupPoint.isNotEmpty) {
        updateData['pickupPoint'] = newPickupPoint;
      }

      // Update booking in Firestore
      await _firestore.collection('bookings').doc(bookingId).update(updateData);

      // Update local list
      final bookingIndex = _bookings.indexWhere((b) => b['id'] == bookingId);
      if (bookingIndex != -1) {
        updateData.forEach((key, value) {
          _bookings[bookingIndex][key] = value;
        });
      }

      print('✅ Booking modified: $bookingId');
      return true;
    } catch (e) {
      _error = 'Failed to modify booking: $e';
      print('❌ Error modifying booking: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check seat availability for a specific date
  Future<bool> _checkSeatAvailability(
    String busId,
    String bookingDate,
    List<int> seatNumbers, {
    String? excludeBookingId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('busId', isEqualTo: busId)
          .where('bookingDate', isEqualTo: bookingDate)
          .where('status', isEqualTo: 'confirmed')
          .get();

      final bookedSeats = <int>{};
      for (var doc in snapshot.docs) {
        // Exclude current booking from check
        if (excludeBookingId != null && doc.id == excludeBookingId) {
          continue;
        }

        final data = doc.data();
        bookedSeats.addAll(
          (data['seats'] as List<dynamic>?)?.cast<int>() ?? [],
        );
      }

      // Check if any requested seats are already booked
      for (var seat in seatNumbers) {
        if (bookedSeats.contains(seat)) {
          return false;
        }
      }

      return true;
    } catch (e) {
      print('❌ Error checking seat availability: $e');
      return false;
    }
  }

  /// Delete booking
  Future<bool> deleteBooking(String bookingId) async {
    try {
      _isLoading = true;
      notifyListeners();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? currentUserId = prefs.getString('userId');

      if (currentUserId == null) {
        throw 'User not logged in';
      }

      // Verify the booking belongs to current user before deleting
      final bookingDoc = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (!bookingDoc.exists) {
        throw 'Booking not found';
      }

      final bookingData = bookingDoc.data() as Map<String, dynamic>;
      if (bookingData['userId'] != currentUserId) {
        throw 'Unauthorized to delete this booking';
      }

      await _firestore.collection('bookings').doc(bookingId).delete();
      _bookings.removeWhere((booking) => booking['id'] == bookingId);

      print('✅ Booking deleted permanently: $bookingId');
      return true;
    } catch (e) {
      _error = 'Failed to delete booking: $e';
      print('❌ Error deleting booking: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if booking can be cancelled/modified

  /// Calculate refund amount based on cancellation time
  double calculateRefundAmount(Map<String, dynamic> booking) {
    final totalFare =
        double.tryParse(booking['totalFare']?.toString() ?? '0') ?? 0.0;
    return totalFare; // Always full refund for testing
  }

  /// Get refund percentage based on cancellation time
  String getRefundPercentage(Map<String, dynamic> booking) {
    return '100%'; // Always full refund for testing
  }

  // Existing utility methods remain the same...
  bool canDeleteBooking(Map<String, dynamic> booking) {
    final status = booking['status']?.toString() ?? '';
    final bookingDateStr = booking['bookingDate']?.toString() ?? '';
    DateTime bookingDate;

    try {
      bookingDate = DateFormat('yyyy-MM-dd').parse(bookingDateStr);
    } catch (e) {
      bookingDate = DateTime.now();
    }

    if (status == 'cancelled' || bookingDate.isBefore(DateTime.now())) {
      return true;
    }
    return false;
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'completed':
        return Icons.done_all;
      case 'pending':
        return Icons.schedule;
      default:
        return Icons.help;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  List<Map<String, dynamic>> getBookingsByStatus(String status) {
    return _bookings
        .where(
          (booking) =>
              booking['status']?.toString().toLowerCase() ==
              status.toLowerCase(),
        )
        .toList();
  }

  List<Map<String, dynamic>> getUpcomingBookings() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _bookings.where((booking) {
      final bookingDateStr = booking['bookingDate']?.toString();
      if (bookingDateStr == null) return false;

      try {
        final bookingDate = DateFormat('yyyy-MM-dd').parse(bookingDateStr);
        return (bookingDate.isAfter(today) ||
                bookingDate.isAtSameMomentAs(today)) &&
            booking['status'] == 'confirmed';
      } catch (e) {
        return false;
      }
    }).toList();
  }

  List<Map<String, dynamic>> getPastBookings() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _bookings.where((booking) {
      final bookingDateStr = booking['bookingDate']?.toString();
      if (bookingDateStr == null) return false;

      try {
        final bookingDate = DateFormat('yyyy-MM-dd').parse(bookingDateStr);
        return bookingDate.isBefore(today);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  Future<void> retryFetchBookings() async {
    clearError();
    await fetchUserBookings();
  }
}
