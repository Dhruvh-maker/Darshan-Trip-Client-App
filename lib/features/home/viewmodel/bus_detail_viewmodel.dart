import 'package:darshan_trip/core/services/local_notifications_service.dart';
import 'package:darshan_trip/features/profile/viewmodel/wallet_viewmodel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfdropcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentcomponents/cfpaymentcomponent.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import 'package:darshan_trip/features/mybookings/viewmodel/bookings_viewmodel.dart';
import 'package:darshan_trip/features/notifications/viewmodel/notifications_viewmodel.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:darshan_trip/core/constants/keys.dart';

class BusDetailViewModel extends ChangeNotifier {
  final Map<String, dynamic> bus;
  final String? sourceCity;
  final String? destinationCity;
  List<String> _selectedSeats = [];
  List<Map<String, dynamic>> _seatData = [];
  List<Map<String, dynamic>> _upperSeatData = [];
  bool _isDoubleDecker = false;
  int _columns = 5;
  bool _isLoadingAdditionalData = false;
  double _totalAmount = 0.0;
  Map<String, double> _seatFares = {};

  // Getters
  double get totalAmount => _totalAmount;
  List<String> get selectedSeats => _selectedSeats;
  List<Map<String, dynamic>> get seatData => _seatData;
  List<Map<String, dynamic>> get upperSeatData => _upperSeatData;
  bool get isDoubleDecker => _isDoubleDecker;
  int get columns => _columns;
  int get totalPrice {
    return totalSelectedPrice.round();
  }

  int get availableSeats => _getAllSeats()
      .where((seat) => seat['type'] == 'seat' && !seat['isBooked'])
      .length;
  List<Map<String, dynamic>> get amenities => _amenities;
  List<Map<String, dynamic>> get drivers => _drivers;
  List<Map<String, dynamic>> get pickupPoints => _pickupPoints;
  List<Map<String, dynamic>> get fares => _fares;
  bool get isLoadingAdditionalData => _isLoadingAdditionalData;
  double get distanceInKm => _distanceInKm;

  // Additional collections data
  List<Map<String, dynamic>> _amenities = [];
  List<Map<String, dynamic>> _drivers = [];
  List<Map<String, dynamic>> _pickupPoints = [];
  List<Map<String, dynamic>> _fares = [];
  List<Map<String, dynamic>> _startPoints = [];

  double _distanceInKm = 0.0;

  DateTime _selectedDate = DateTime.now();

  // Add this setter method
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  BusDetailViewModel({
    required this.bus,
    this.sourceCity,
    this.destinationCity,
  }) {
    _validateBusData();
    _initializeSeats();
    _fetchAndUpdateBookedSeats();

    // Fetch seat-specific fares after initializing seats
    fetchAndApplySeatFares();

    fetchAllBusDetails();
    if (sourceCity != null &&
        sourceCity!.isNotEmpty &&
        destinationCity != null &&
        destinationCity!.isNotEmpty) {
      fetchStartPointsAndCalculateDistance(sourceCity!, destinationCity!);
    } else {
      _distanceInKm = 413.0;
      notifyListeners();
    }
  }

  // Set total amount
  void setTotalAmount(double amount) {
    _totalAmount = amount;
    notifyListeners();
  }

  // Fetch Bus Amenities
  Future<void> fetchBusAmenities() async {
    try {
      final amenityIds = List<String>.from(bus['facilities'] ?? []);
      if (amenityIds.isEmpty) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('amenities')
          .where(FieldPath.documentId, whereIn: amenityIds)
          .get();

      _amenities = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      print("✅ Bus Amenities fetched: ${_amenities.length} items");
      notifyListeners();
    } catch (e) {
      print('❌ Error fetching bus amenities: $e');
      _amenities = [];
    }
  }

  Future<void> fetchAndApplySeatFares() async {
    try {
      final busId = bus['id']?.toString();
      if (busId == null || busId.isEmpty) return;

      // Get current tripId if available
      final tripId = bus['tripId']?.toString();

      // Query fares collection for this bus
      Query fareQuery = FirebaseFirestore.instance
          .collection('fares')
          .where('busId', isEqualTo: busId);

      // If tripId is available, also filter by tripId for more specific pricing
      if (tripId != null && tripId.isNotEmpty) {
        fareQuery = fareQuery.where('tripId', isEqualTo: tripId);
      }

      final faresSnapshot = await fareQuery.get();

      _seatFares.clear();

      // Build seat fare lookup map
      for (var fareDoc in faresSnapshot.docs) {
        final fareData = fareDoc.data() as Map<String, dynamic>;
        final seatNumber = fareData['seatNumber']?.toString();
        final price = fareData['price'];

        if (seatNumber != null && price != null) {
          _seatFares[seatNumber] = (price as num).toDouble();
        }
      }

      print("✅ Seat-specific fares loaded: ${_seatFares.length} seats");
      print("📊 Fare data: $_seatFares");

      // Update seat prices in both lower and upper deck layouts
      _updateSeatPrices(_seatData);
      if (_isDoubleDecker) {
        _updateSeatPrices(_upperSeatData);
      }

      notifyListeners();
    } catch (e) {
      print('❌ Error fetching seat fares: $e');
      _seatFares = {};
    }
  }

  void _updateSeatPrices(List<Map<String, dynamic>> seatLayout) {
    final defaultPrice = (bus['ticketPrice'] as num?)?.toDouble() ?? 500.0;

    for (var seat in seatLayout) {
      if (seat['type'] == 'seat') {
        final seatNumber = seat['seatNumber']?.toString();
        if (seatNumber != null) {
          // Use specific fare if available, otherwise use default price
          seat['price'] = _seatFares[seatNumber] ?? defaultPrice;
        } else {
          seat['price'] = defaultPrice;
        }
      }
    }
  }

  // Fetch Start Points
  Future<void> fetchStartPoints() async {
    try {
      final startPointsSnapshot = await FirebaseFirestore.instance
          .collection('startPoints')
          .get()
          .timeout(const Duration(seconds: 10));

      _startPoints = startPointsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      print("✅ Start Points fetched: ${_startPoints.length} items");
      notifyListeners();
    } catch (e) {
      print('❌ Error fetching start points: $e');
      _startPoints = [];
    }
  }

  Future<void> fetchStartPointsAndCalculateDistance(
    String sourceCity,
    String destinationCity,
  ) async {
    try {
      final startPointsSnapshot = await FirebaseFirestore.instance
          .collection('startPoints')
          .get()
          .timeout(const Duration(seconds: 10));

      _startPoints = startPointsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      print("✅ Start Points fetched: ${_startPoints.length} items");

      Map<String, dynamic>? sourcePoint = _startPoints.firstWhere(
        (point) =>
            point['name']?.toString().toLowerCase() == sourceCity.toLowerCase(),
        orElse: () => {},
      );
      Map<String, dynamic>? destinationPoint = _startPoints.firstWhere(
        (point) =>
            point['name']?.toString().toLowerCase() ==
            destinationCity.toLowerCase(),
        orElse: () => {},
      );

      double? sourceLat = sourcePoint['latitude'] is num
          ? sourcePoint['latitude']?.toDouble()
          : null;
      double? sourceLon = sourcePoint['longitude'] is num
          ? sourcePoint['longitude']?.toDouble()
          : null;
      double? destLat = destinationPoint['latitude'] is num
          ? destinationPoint['latitude']?.toDouble()
          : null;
      double? destLon = destinationPoint['longitude'] is num
          ? destinationPoint['longitude']?.toDouble()
          : null;

      if (sourceLat == null || sourceLon == null) {
        try {
          final sourceLocations = await locationFromAddress(sourceCity);
          if (sourceLocations.isNotEmpty) {
            sourceLat = sourceLocations.first.latitude;
            sourceLon = sourceLocations.first.longitude;
            print("✅ Geocoded $sourceCity: ($sourceLat, $sourceLon)");
          } else {
            print("❌ No geocoding results for $sourceCity");
          }
        } catch (e) {
          print("❌ Geocoding failed for $sourceCity: $e");
        }
      }

      if (destLat == null || destLon == null) {
        try {
          final destLocations = await locationFromAddress(destinationCity);
          if (destLocations.isNotEmpty) {
            destLat = destLocations.first.latitude;
            destLon = destLocations.first.longitude;
            print("✅ Geocoded $destinationCity: ($destLat, $destLon)");
          } else {
            print("❌ No geocoding results for $destinationCity");
          }
        } catch (e) {
          print("❌ Geocoding failed for $destinationCity: $e");
        }
      }

      if (sourceLat != null &&
          sourceLon != null &&
          destLat != null &&
          destLon != null) {
        final distanceInMeters = Geolocator.distanceBetween(
          sourceLat,
          sourceLon,
          destLat,
          destLon,
        );
        _distanceInKm = distanceInMeters / 1000;
        print("✅ Calculated distance: $_distanceInKm km");
      } else {
        print("❌ Missing coordinates for distance calculation");
        _distanceInKm = 413.0;
      }

      notifyListeners();
    } catch (e) {
      print('❌ Error fetching start points or calculating distance: $e');
      _distanceInKm = 413.0;
      notifyListeners();
    }
  }

  // Fetch Bus Driver Info
  Future<void> fetchBusDriver() async {
    try {
      final driverId = bus['driverId']?.toString();
      if (driverId == null || driverId.isEmpty) return;

      final doc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        _drivers = [data];
        print("✅ Bus Driver fetched: ${data['name'] ?? 'Unknown Driver'}");
      }

      notifyListeners();
    } catch (e) {
      print('❌ Error fetching bus driver: $e');
      _drivers = [];
    }
  }

  // Fetch Pickup Points
  Future<void> fetchPickupPointsForRoute() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('pickupPoints')
          .where('status', isEqualTo: 'active')
          .get();

      print("📋 Raw snapshot size: ${snapshot.docs.length} documents");
      _pickupPoints = snapshot.docs.map((doc) {
        final data = doc.data();
        print("📝 Document ID: ${doc.id}, Data: $data");
        data['id'] = doc.id;
        return {
          'id': doc.id,
          'name': data['name']?.toString() ?? 'Unknown',
          'address': data['address'],
          'contactNumber': data['contactNumber'],
          'latitude': data['latitude'],
          'longitude': data['longitude'],
          'status': data['status'],
        };
      }).toList();

      print("✅ Pickup Points fetched: ${_pickupPoints.length} items");
      notifyListeners();
    } catch (e) {
      print('❌ Error fetching pickup points: $e');
      _pickupPoints = [];
    }
  }

  // Fetch Fare details for this bus
  Future<void> fetchBusFares() async {
    try {
      final busId = bus['id']?.toString();
      if (busId == null || busId.isEmpty) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('fares')
          .where('busId', isEqualTo: busId)
          .get();

      _fares = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      print("✅ Bus Fares fetched: ${_fares.length} items");
      notifyListeners();
    } catch (e) {
      print('❌ Error fetching bus fares: $e');
      _fares = [];
    }
  }

  // Fetch all additional data for bus detail
  Future<void> fetchAllBusDetails() async {
    _isLoadingAdditionalData = true;
    notifyListeners();

    try {
      await Future.wait([
        fetchBusAmenities(),
        fetchBusDriver(),
        fetchPickupPointsForRoute(),
        fetchBusFares(),
      ]);
    } catch (e) {
      print('❌ Error fetching all bus details: $e');
    } finally {
      _isLoadingAdditionalData = false;
      notifyListeners();
    }
  }

  // Fetch current booked seats for this bus on selected date
  Future<List<int>> fetchCurrentBookedSeats(DateTime selectedDate) async {
    try {
      final busId = bus['id']?.toString();
      if (busId == null) return [];

      final selectedDateString = DateFormat('yyyy-MM-dd').format(selectedDate);

      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('busId', isEqualTo: busId)
          .where('bookingDate', isEqualTo: selectedDateString)
          .where('status', isEqualTo: 'confirmed')
          .get();

      List<int> bookedSeats = [];
      for (var booking in snapshot.docs) {
        final bookingData = booking.data();
        bookedSeats.addAll(
          (bookingData['seats'] as List<dynamic>? ?? []).map((s) => s as int),
        );
      }

      print("✅ Current booked seats: $bookedSeats");
      return bookedSeats;
    } catch (e) {
      print('❌ Error fetching current booked seats: $e');
      return [];
    }
  }

  Future<void> _fetchAndUpdateBookedSeats() async {
    final DateTime selectedDate =
        DateTime.now(); // Use current date or adjust as needed
    final bookedSeats = await fetchCurrentBookedSeats(selectedDate);

    // Update _seatData
    for (var seat in _seatData) {
      if (seat['type'] == 'seat' &&
          bookedSeats.contains(int.parse(seat['seatNumber']))) {
        seat['isBooked'] = true;
      }
    }

    // Update _upperSeatData if double decker
    if (_isDoubleDecker) {
      for (var seat in _upperSeatData) {
        if (seat['type'] == 'seat' &&
            bookedSeats.contains(int.parse(seat['seatNumber']))) {
          seat['isBooked'] = true;
        }
      }
    }

    notifyListeners(); // Notify UI to reflect changes
  }

  List<Map<String, dynamic>> _getAllSeats() {
    return [..._seatData, ..._upperSeatData];
  }

  void _validateBusData() {
    if (!bus.containsKey('price') || bus['price'] == null) {
      bus['price'] = '₹${bus['ticketPrice'] ?? 619}';
    }

    _isDoubleDecker =
        (bus['totalDecker']?.toString().toLowerCase() == 'double') ||
        bus.containsKey('lowerSeatLayout') ||
        bus.containsKey('upperSeatLayout');
  }

  void _initializeSeats() {
    if (_isDoubleDecker) {
      _initializeDoubleDecker();
    } else {
      _initializeSingleDecker();
    }
  }

  void _initializeSingleDecker() {
    final seatLayout = bus['seatLayout'] as Map<String, dynamic>?;
    final defaultPrice = (bus['ticketPrice'] as num?)?.toDouble() ?? 500.0;

    if (seatLayout != null && seatLayout['grid'] != null) {
      _columns = (seatLayout['cols'] as num?)?.toInt() ?? 5;
      final grid = seatLayout['grid'] as List<dynamic>;

      _seatData = grid.map<Map<String, dynamic>>((seat) {
        if (seat is Map<String, dynamic>) {
          if (seat['type'] == 'seat') {
            final seatNumber = seat['seatNumber']?.toString() ?? '';
            return {
              'seatNumber': seatNumber,
              'type': 'seat',
              'isBooked': false,
              'isFemale': false,
              'isFemaleOnly': seat['isForWomen'] == true,
              'category': seat['category'] ?? 'seater',
              'price':
                  defaultPrice, // Will be updated by fetchAndApplySeatFares
            };
          } else {
            return {
              'seatNumber': '',
              'type': seat['type']?.toString() ?? 'empty',
              'isBooked': false,
              'isFemale': false,
              'isFemaleOnly': false,
              'category': 'empty',
              'price': 0,
            };
          }
        }
        return {
          'seatNumber': '',
          'type': 'empty',
          'isBooked': false,
          'isFemale': false,
          'isFemaleOnly': false,
          'category': 'empty',
          'price': 0,
        };
      }).toList();
    } else {
      _seatData = _createDefaultSingleDeckerLayout();
    }
  }

  void _initializeDoubleDecker() {
    final defaultPrice = (bus['ticketPrice'] as num?)?.toDouble() ?? 500.0;

    final lowerLayout = bus['lowerSeatLayout'] as Map<String, dynamic>?;
    if (lowerLayout != null && lowerLayout['grid'] != null) {
      _columns = (lowerLayout['cols'] as num?)?.toInt() ?? 5;
      final lowerGrid = lowerLayout['grid'] as List<dynamic>;

      _seatData = lowerGrid.map<Map<String, dynamic>>((seat) {
        if (seat is Map<String, dynamic>) {
          final seatType = seat['type']?.toString() ?? 'seat';
          if (seatType == 'seat') {
            final seatNumber = seat['seatNumber']?.toString() ?? '';
            return {
              'seatNumber': seatNumber,
              'type': seatType,
              'isBooked': false,
              'isFemale': false,
              'isFemaleOnly': seat['isForWomen'] == true,
              'category': seat['category'] ?? 'seater',
              'price':
                  defaultPrice, // Will be updated by fetchAndApplySeatFares
            };
          } else {
            return {
              'seatNumber': '',
              'type': seatType,
              'isBooked': false,
              'isFemale': false,
              'isFemaleOnly': false,
              'category': 'empty',
              'price': 0,
            };
          }
        }
        return {
          'seatNumber': '',
          'type': 'empty',
          'isBooked': false,
          'isFemale': false,
          'isFemaleOnly': false,
          'category': 'empty',
          'price': 0,
        };
      }).toList();
    } else {
      _seatData = _createDefaultSingleDeckerLayout(isLowerDeck: true);
    }

    final upperLayout = bus['upperSeatLayout'] as Map<String, dynamic>?;
    if (upperLayout != null && upperLayout['grid'] != null) {
      final upperGrid = upperLayout['grid'] as List<dynamic>;

      _upperSeatData = upperGrid.map<Map<String, dynamic>>((seat) {
        if (seat is Map<String, dynamic> && seat['type'] == 'seat') {
          final seatNumber = seat['seatNumber']?.toString() ?? '';
          return {
            'seatNumber': seatNumber,
            'type': 'seat',
            'isBooked': false,
            'isFemale': false,
            'isFemaleOnly': seat['isForWomen'] == true,
            'category': seat['category'] ?? 'sleeper',
            'price': defaultPrice, // Will be updated by fetchAndApplySeatFares
          };
        }
        return {
          'seatNumber': '',
          'type': seat['type']?.toString() ?? 'aisle',
          'isBooked': false,
          'isFemale': false,
          'isFemaleOnly': false,
          'category': 'empty',
          'price': 0,
        };
      }).toList();
    } else {
      final lowerDeckSeatCount = _seatData
          .where((seat) => seat['type'] == 'seat')
          .length;
      final totalSeats = (bus['totalSeat'] as num?)?.toInt() ?? 40;
      final remainingSeats = totalSeats - lowerDeckSeatCount;
      if (remainingSeats > 0) {
        _upperSeatData = _createDefaultUpperDeckLayout(remainingSeats);
      }
    }
  }

  List<Map<String, dynamic>> _createDefaultSingleDeckerLayout({
    bool isLowerDeck = false,
  }) {
    final List<Map<String, dynamic>> seats = [];
    int seatCounter = isLowerDeck ? 1 : 21;
    final totalSeats = isLowerDeck
        ? ((bus['totalSeat'] as num?)?.toInt() ?? 40) ~/ 2
        : (bus['totalSeat'] as num?)?.toInt() ?? 32;
    const seatsPerRow = 4;
    final rows = (totalSeats / seatsPerRow).ceil();
    final defaultPrice = (bus['ticketPrice'] as num?)?.toDouble() ?? 500.0;

    _columns = 5;
    for (
      int row = 0;
      row < rows && seatCounter <= (isLowerDeck ? 20 : totalSeats);
      row++
    ) {
      for (int col = 0; col < _columns; col++) {
        if (col == 2) {
          seats.add({
            'seatNumber': '',
            'type': 'aisle',
            'isBooked': false,
            'isFemale': false,
            'isFemaleOnly': false,
            'category': 'empty',
            'price': 0,
          });
        } else {
          if (seatCounter <= (isLowerDeck ? 20 : totalSeats)) {
            seats.add({
              'seatNumber': seatCounter.toString(),
              'type': 'seat',
              'isBooked': false,
              'isFemale': false,
              'isFemaleOnly': false,
              'category': isLowerDeck ? 'seater' : 'sleeper',
              'price':
                  defaultPrice, // Will be updated by fetchAndApplySeatFares
            });
            seatCounter++;
          } else {
            seats.add({
              'seatNumber': '',
              'type': 'empty',
              'isBooked': false,
              'isFemale': false,
              'isFemaleOnly': false,
              'category': 'empty',
              'price': 0,
            });
          }
        }
      }
    }
    return seats;
  }

  List<Map<String, dynamic>> _createDefaultUpperDeckLayout(int seatCount) {
    final List<Map<String, dynamic>> seats = [];
    int seatCounter = 21;
    const seatsPerRow = 4;
    final rows = (seatCount / seatsPerRow).ceil();
    final defaultPrice = (bus['ticketPrice'] as num?)?.toDouble() ?? 500.0;

    for (int row = 0; row < rows && (seatCounter - 21) < seatCount; row++) {
      for (int col = 0; col < _columns; col++) {
        if (col == 2) {
          seats.add({
            'seatNumber': '',
            'type': 'aisle',
            'isBooked': false,
            'isFemale': false,
            'isFemaleOnly': false,
            'category': 'empty',
            'price': 0,
          });
        } else if ((seatCounter - 21) < seatCount) {
          seats.add({
            'seatNumber': seatCounter.toString(),
            'type': 'seat',
            'isBooked': false,
            'isFemale': false,
            'isFemaleOnly': false,
            'category': 'sleeper',
            'price': defaultPrice, // Will be updated by fetchAndApplySeatFares
          });
          seatCounter++;
        } else {
          seats.add({
            'seatNumber': '',
            'type': 'empty',
            'isBooked': false,
            'isFemale': false,
            'isFemaleOnly': false,
            'category': 'empty',
            'price': 0,
          });
        }
      }
    }
    return seats;
  }

  List<Map<String, dynamic>> getAvailableSeatsForGender({
    required bool isFemalePassenger,
  }) {
    final allSeats = [..._seatData, ..._upperSeatData];

    return allSeats.where((seat) {
      if (seat['type'] != 'seat' || seat['isBooked'] == true) {
        return false;
      }

      final seatNumber = seat['seatNumber']?.toString() ?? '';
      if (seatNumber.isEmpty) return false;

      return canSelectSeat(seatNumber, isFemalePassenger: isFemalePassenger);
    }).toList();
  }

  Map<String, dynamic> getSeatRestrictions(String seatNumber) {
    Map<String, dynamic> seat = {};
    final lowerIndex = _seatData.indexWhere(
      (s) => s['seatNumber'] == seatNumber,
    );

    if (lowerIndex != -1) {
      seat = _seatData[lowerIndex];
    } else if (_isDoubleDecker) {
      final upperIndex = _upperSeatData.indexWhere(
        (s) => s['seatNumber'] == seatNumber,
      );
      if (upperIndex != -1) {
        seat = _upperSeatData[upperIndex];
      }
    }

    return {
      'isFemaleOnly': seat['isFemaleOnly'] == true,
      'hasAdjacentFemale': _hasAdjacentFemalePassenger(seatNumber),
      'isBooked': seat['isBooked'] == true,
      'category': seat['category'] ?? 'seater',
      'price': (seat['price'] as num?)?.toDouble() ?? 500.0,
    };
  }

  int _getPricePerSeat() {
    if (_selectedSeats.isEmpty) {
      final defaultPrice = (bus['ticketPrice'] as num?)?.toInt() ?? 500;
      return defaultPrice;
    }

    // Calculate average price of selected seats
    double totalPrice = 0;
    int seatCount = 0;

    for (String seatNumber in _selectedSeats) {
      final seat = _getAllSeats().firstWhere(
        (s) => s['seatNumber'] == seatNumber,
        orElse: () => {},
      );
      if (seat.isNotEmpty) {
        totalPrice += (seat['price'] as num?)?.toDouble() ?? 500.0;
        seatCount++;
      }
    }

    return seatCount > 0 ? (totalPrice / seatCount).round() : 500;
  }

  double get totalSelectedPrice {
    double total = 0;
    for (String seatNumber in _selectedSeats) {
      final seat = _getAllSeats().firstWhere(
        (s) => s['seatNumber'] == seatNumber,
        orElse: () => {},
      );
      if (seat.isNotEmpty) {
        total += (seat['price'] as num?)?.toDouble() ?? 500.0;
      }
    }
    return total;
  }

  Map<String, int> _getSeatPosition(
    int seatIndex,
    List<Map<String, dynamic>> layout,
  ) {
    return {'row': seatIndex ~/ _columns, 'column': seatIndex % _columns};
  }

  List<int> _getAdjacentSeatIndices(
    int seatIndex,
    List<Map<String, dynamic>> layout,
  ) {
    final position = _getSeatPosition(seatIndex, layout);
    final row = position['row']!;
    final column = position['column']!;
    final List<int> adjacentIndices = [];

    if (column > 0 &&
        (column != 3 || layout[row * _columns + 2]['type'] == 'aisle')) {
      final leftIndex = row * _columns + (column - 1);
      if (leftIndex >= 0 && leftIndex < layout.length) {
        adjacentIndices.add(leftIndex);
      }
    }

    if (column < _columns - 1 &&
        (column != 1 || layout[row * _columns + 2]['type'] == 'aisle')) {
      final rightIndex = row * _columns + (column + 1);
      if (rightIndex < layout.length) {
        adjacentIndices.add(rightIndex);
      }
    }

    return adjacentIndices;
  }

  bool _hasAdjacentFemalePassenger(String seatNumber) {
    final lowerSeatIndex = _seatData.indexWhere(
      (s) => s['seatNumber'] == seatNumber,
    );
    if (lowerSeatIndex != -1) {
      return _checkAdjacentFemalesInLayout(lowerSeatIndex, _seatData);
    }

    if (_isDoubleDecker) {
      final upperSeatIndex = _upperSeatData.indexWhere(
        (s) => s['seatNumber'] == seatNumber,
      );
      if (upperSeatIndex != -1) {
        return _checkAdjacentFemalesInLayout(upperSeatIndex, _upperSeatData);
      }
    }
    return false;
  }

  bool _checkAdjacentFemalesInLayout(
    int seatIndex,
    List<Map<String, dynamic>> layout,
  ) {
    final adjacentIndices = _getAdjacentSeatIndices(seatIndex, layout);
    for (final index in adjacentIndices) {
      if (index < layout.length) {
        final adjacentSeat = layout[index];
        if (adjacentSeat['type'] == 'seat' &&
            adjacentSeat['isBooked'] == true &&
            adjacentSeat['isFemale'] == true) {
          return true;
        }
        if (adjacentSeat['type'] == 'seat' &&
            _selectedSeats.contains(adjacentSeat['seatNumber']) &&
            adjacentSeat['isFemaleOnly'] == true) {
          return true;
        }
      }
    }
    return false;
  }

  bool canSelectSeat(String seatNumber, {bool isFemalePassenger = false}) {
    Map<String, dynamic> seat = {};
    final lowerIndex = _seatData.indexWhere(
      (s) => s['seatNumber'] == seatNumber,
    );
    if (lowerIndex != -1) {
      seat = _seatData[lowerIndex];
    } else if (_isDoubleDecker) {
      final upperIndex = _upperSeatData.indexWhere(
        (s) => s['seatNumber'] == seatNumber,
      );
      if (upperIndex != -1) {
        seat = _upperSeatData[upperIndex];
      }
    }

    if (seat.isEmpty || seat['isBooked'] == true || seat['type'] != 'seat') {
      return false;
    }

    if (seat['isFemaleOnly'] == true && !isFemalePassenger) {
      return false;
    }

    if (!isFemalePassenger && _hasAdjacentFemalePassenger(seatNumber)) {
      return false;
    }

    return true;
  }

  void toggleSeatSelection(
    String seatNumber, {
    bool isFemalePassenger = false,
  }) {
    if (!canSelectSeat(seatNumber, isFemalePassenger: isFemalePassenger)) {
      return;
    }

    if (_selectedSeats.contains(seatNumber)) {
      _selectedSeats.remove(seatNumber);
    } else {
      _selectedSeats.add(seatNumber);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedSeats.clear();
    notifyListeners();
  }

  String getSeatSelectionErrorMessage(
    String seatNumber, {
    bool isFemalePassenger = false,
  }) {
    Map<String, dynamic> seat = {};
    final lowerIndex = _seatData.indexWhere(
      (s) => s['seatNumber'] == seatNumber,
    );
    if (lowerIndex != -1) {
      seat = _seatData[lowerIndex];
    } else if (_isDoubleDecker) {
      final upperIndex = _upperSeatData.indexWhere(
        (s) => s['seatNumber'] == seatNumber,
      );
      if (upperIndex != -1) {
        seat = _upperSeatData[upperIndex];
      }
    }

    if (seat.isEmpty) {
      return 'Invalid seat selection';
    }

    if (seat['isBooked'] == true) {
      return 'This seat is already booked';
    }

    if (seat['type'] != 'seat') {
      return 'This is not a valid seat';
    }

    if (seat['isFemaleOnly'] == true && !isFemalePassenger) {
      return 'This seat is for female passengers only';
    }

    if (!isFemalePassenger && _hasAdjacentFemalePassenger(seatNumber)) {
      return 'Male passengers cannot select seats next to female passengers';
    }

    return 'This seat cannot be selected';
  }

  // In BusDetailViewModel class, replace the confirmBooking method:
  Future<Map<String, dynamic>?> confirmBooking(
    BuildContext context,
    BookingsViewModel bookingsViewModel, {
    required String pickupPoint,
    required String passengerName,
    required String passengerContact,
    List<Map<String, dynamic>> passengers = const [],
  }) async {
    try {
      print('📝 Preparing booking data for seats: $_selectedSeats');

      final bookingTotalAmount = totalPrice.toDouble();
      setTotalAmount(bookingTotalAmount);

      final bookingData = {
        'busId': bus['id']?.toString() ?? 'unknown_bus_id',
        'busData': bus,
        'selectedSeats': List<String>.from(_selectedSeats),
        'travelDate': _selectedDate, // Use the stored selected date
        'pickupPoint': pickupPoint,
        'totalAmount': bookingTotalAmount,
        'passengerName': passengerName,
        'passengerContact': passengerContact,
        'sourceCity': sourceCity ?? bus['from'] ?? 'Unknown',
        'destinationCity': destinationCity ?? bus['to'] ?? 'Unknown',
        'status': 'pending',
        'passengers': passengers,
      };

      print('✅ Booking data prepared: $bookingData');
      return bookingData;
    } catch (e) {
      print('❌ Error preparing booking data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking preparation failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  Future<String?> saveBooking(
    BuildContext context,
    BookingsViewModel bookingsViewModel,
    Map<String, dynamic> bookingData, {
    String paymentMethod = 'Online Payment',
  }) async {
    try {
      final bookingId = await bookingsViewModel.createBooking(
        busData: bookingData['busData'],
        selectedSeats: bookingData['selectedSeats'],
        travelDate: bookingData['travelDate'],
        pickupPoint: bookingData['pickupPoint'],
        totalAmount: bookingData['totalAmount'],
        passengerName: bookingData['passengerName'],
        passengerContact: bookingData['passengerContact'],
        sourceCity: bookingData['sourceCity'],
        destinationCity: bookingData['destinationCity'],
        passengers: bookingData['passengers'],
      );

      if (bookingId != null) {
        print('✅ Booking saved with ID: $bookingId');

        // Show local notification for booking confirmation
        final localNotificationService = LocalNotificationService();
        await localNotificationService.showBookingConfirmationNotification(
          bookingId: bookingId,
          sourceCity: bookingData['sourceCity'],
          destinationCity: bookingData['destinationCity'],
          amount: bookingData['totalAmount'],
          paymentMethod: paymentMethod,
          seats: List<String>.from(bookingData['selectedSeats'] ?? []),
        );

        // Show payment success notification
        if (paymentMethod == 'Wallet') {
          await localNotificationService.showWalletDebitNotification(
            bookingId: bookingId,
            amount: bookingData['totalAmount'],
          );
        } else {
          await localNotificationService.showPaymentSuccessNotification(
            bookingId: bookingId,
            amount: bookingData['totalAmount'],
            paymentMethod: paymentMethod,
          );
        }

        try {
          final notificationsViewModel = Provider.of<NotificationsViewModel>(
            context,
            listen: false,
          );

          await notificationsViewModel.createPersonalizedBookingNotification(
            bookingId: bookingId,
            passengerName: bookingData['passengerName'],
            busName:
                bookingData['busData']['busName'] ??
                bookingData['busData']['name'] ??
                'Unknown Bus',
            sourceCity: bookingData['sourceCity'],
            destinationCity: bookingData['destinationCity'],
            travelDate: bookingData['travelDate'],
            seats: bookingData['selectedSeats'],
            amount: bookingData['totalAmount'],
          );
          print('✅ Booking confirmation notification created');

          if (paymentMethod == 'Wallet') {
            await notificationsViewModel.createNotification(
              title: '💸 Wallet Payment',
              body:
                  '₹${bookingData['totalAmount']} debited from your wallet for booking',
              type: 'wallet_debit',
              data: {
                'bookingId': bookingId,
                'amount': bookingData['totalAmount'],
                'paymentMethod': 'Wallet',
              },
            );
            print('✅ Wallet debit notification created');
          } else {
            await notificationsViewModel.createPaymentSuccessNotification(
              bookingId: bookingId,
              amount: bookingData['totalAmount'],
              paymentMethod: paymentMethod,
            );
            print('✅ Payment success notification created');
          }
        } catch (e) {
          print('❌ Error creating notifications: $e');
          // Don't throw here, booking was successful
        }

        await bookingsViewModel.fetchUserBookings();
        return bookingId;
      } else {
        print('❌ Booking creation failed: bookingId is null');
        throw Exception('Failed to save booking');
      }
    } catch (e) {
      print('❌ Error saving booking: $e');
      throw e;
    }
  }

  void clearSelectionWithCallback({Function? onClear}) {
    if (_selectedSeats.isNotEmpty) {
      _selectedSeats.clear();
      notifyListeners();
      onClear?.call();
    }
  }

  Future<void> initiatePayment(
    BuildContext context,
    String customerName,
    String customerPhone,
    String customerEmail,
    Map<String, dynamic> bookingData, {
    String paymentMethod = 'Online Payment',
  }) async {
    try {
      print('🔄 Starting payment process...');

      final paymentAmount = bookingData['totalAmount'] ?? _totalAmount;

      print('   Total Amount: $paymentAmount');
      print('   Customer: $customerName');
      print('   Phone: $customerPhone');
      print('   Email: $customerEmail');
      print('   Payment Method: $paymentMethod');

      if (paymentAmount <= 0) {
        throw Exception("Invalid payment amount: $paymentAmount");
      }

      final orderId = 'ORDER_${DateTime.now().millisecondsSinceEpoch}';

      // Fetch appId and secret key from Firestore
      final appId = await CashfreeConfig.getAppId();
      final secretKey = await CashfreeConfig.getSecretKey();

      if (appId.isEmpty || secretKey.isEmpty) {
        throw Exception("Missing appId or secret key from Firestore");
      }

      final sessionId = await _createOrderAndGetSessionId(
        appId: appId,
        secretKey: secretKey,
        orderId: orderId,
        orderAmount: paymentAmount,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
      );

      print('✅ Session ID received: $sessionId');

      final session = CFSessionBuilder()
          .setEnvironment(CFEnvironment.SANDBOX)
          .setOrderId(orderId)
          .setPaymentSessionId(sessionId)
          .build();

      final cfWebCheckout = CFWebCheckoutPaymentBuilder()
          .setSession(session)
          .build();

      final cfService = CFPaymentGatewayService();

      bool paymentCompleted = false;

      cfService.setCallback(
        (successOrderId) async {
          if (paymentCompleted) return; // Prevent multiple callbacks
          paymentCompleted = true;

          print('✅ Payment successful for order: $successOrderId');
          try {
            final bookingsViewModel = Provider.of<BookingsViewModel>(
              context,
              listen: false,
            );
            final bookingId = await saveBooking(
              context,
              bookingsViewModel,
              bookingData,
              paymentMethod: paymentMethod,
            );

            if (bookingId != null) {
              clearSelection(); // Clear seats only after successful booking
              _showSnack(
                context,
                "Payment and booking successful! Booking ID: $bookingId",
                Colors.green,
              );
              _showPaymentSuccessDialog(context);
              Navigator.pop(context, {
                'status': 'success',
                'bookingId': bookingId,
              });
            } else {
              throw Exception("Booking failed after payment");
            }
          } catch (e) {
            print('❌ Error saving booking after payment: $e');
            _showSnack(
              context,
              "Payment successful but booking failed: $e",
              Colors.red,
            );
            Navigator.pop(context, {
              'status': 'failed',
              'message': e.toString(),
            });
          }
        },
        (CFErrorResponse error, String? failedOrderId) {
          if (paymentCompleted) return; // Prevent multiple callbacks
          paymentCompleted = true;

          print('❌ Payment failed: ${error.getMessage()}');
          _showSnack(
            context,
            "Payment failed: ${error.getMessage()}",
            Colors.red,
          );
          Navigator.pop(context, {
            'status': 'failed',
            'message': error.getMessage(),
          });
        },
      );

      print('🚀 Launching payment gateway...');
      await cfService.doPayment(cfWebCheckout);
    } catch (e) {
      print('❌ Payment initiation error: $e');
      _showSnack(context, "Payment error: $e", Colors.red);
      Navigator.pop(context, {'status': 'failed', 'message': e.toString()});
    }
  }

  void validateSeatSelections({required bool isFemalePassenger}) {
    final invalidSeats = <String>[];

    for (String seatNumber in _selectedSeats) {
      if (!canSelectSeat(seatNumber, isFemalePassenger: isFemalePassenger)) {
        invalidSeats.add(seatNumber);
      }
    }

    // Remove invalid seats
    for (String seatNumber in invalidSeats) {
      _selectedSeats.remove(seatNumber);
    }

    if (invalidSeats.isNotEmpty) {
      notifyListeners();
    }
  }

  void _showPaymentSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green.shade600,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Payment Successful!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Your bus ticket has been booked successfully. You will receive a confirmation SMS shortly.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _createOrderAndGetSessionId({
    required String appId,
    required String secretKey,
    required String orderId,
    required double orderAmount,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
  }) async {
    try {
      final uri = Uri.parse("https://sandbox.cashfree.com/pg/orders");

      final body = {
        "order_id": orderId,
        "order_amount": orderAmount.toStringAsFixed(2),
        "order_currency": "INR",
        "customer_details": {
          "customer_id": customerPhone,
          "customer_name": customerName,
          "customer_email": customerEmail,
          "customer_phone": customerPhone,
        },
        "order_meta": {"return_url": "https://example.com/return"},
      };

      final response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "x-client-id": appId,
          "x-client-secret": secretKey,
          "x-api-version": "2023-08-01",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sessionId = data['payment_session_id'] as String?;
        if (sessionId == null) {
          throw Exception("Payment session ID not found in response");
        }
        return sessionId;
      } else {
        throw Exception("Failed to create order: ${response.body}");
      }
    } catch (e) {
      print('❌ Error creating order: $e');
      rethrow;
    }
  }

  void _showSnack(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> initiateWalletPayment(
    BuildContext context,
    String customerName,
    String customerPhone,
    String customerEmail,
    Map<String, dynamic> bookingData,
    WalletViewModel walletViewModel,
  ) async {
    try {
      final paymentAmount = bookingData['totalAmount'] ?? _totalAmount;

      if (paymentAmount <= 0) {
        throw Exception("Invalid payment amount: $paymentAmount");
      }

      final currentBalance = walletViewModel.walletBalance ?? 0.0;
      if (currentBalance < paymentAmount) {
        _showSnack(
          context,
          "Insufficient wallet balance. Please add funds.",
          Colors.red,
        );
        return;
      }

      final bookingsViewModel = Provider.of<BookingsViewModel>(
        context,
        listen: false,
      );

      await walletViewModel.deductFromWallet(paymentAmount);
      final bookingId = await saveBooking(
        context,
        bookingsViewModel,
        bookingData,
        paymentMethod: 'Wallet',
      );

      if (bookingId != null) {
        clearSelection();
        _showSnack(
          context,
          "Payment and booking successful! Booking ID: $bookingId",
          Colors.green,
        );
        _showPaymentSuccessDialog(context);
        Navigator.pop(context, {'status': 'success', 'bookingId': bookingId});
      } else {
        throw Exception("Booking failed after wallet payment");
      }
    } catch (e) {
      print('❌ Wallet payment error: $e');
      _showSnack(context, "Wallet payment failed: $e", Colors.red);
      Navigator.pop(context, {'status': 'failed', 'message': e.toString()});
    }
  }
}
