import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:darshan_trip/features/home/view/bus_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SearchResultsViewModel extends ChangeNotifier {
  String _sourceCity = '';
  String _destinationCity = '';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;

  // Filter states
  bool _isACFilterEnabled = false;
  bool _isSleeperFilterEnabled = false;
  bool _isLuxuryFilterEnabled = false;

  // Bus results data
  List<Map<String, dynamic>> _busResults = [];
  List<Map<String, dynamic>> _filteredBusResults = [];

  // Additional collections data
  List<Map<String, dynamic>> _amenities = [];
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _drivers = [];
  List<Map<String, dynamic>> _pickupPoints = [];
  List<Map<String, dynamic>> _promotions = [];
  List<Map<String, dynamic>> _startPoints = [];
  List<Map<String, dynamic>> _users = [];

  // Getters
  String get sourceCity => _sourceCity;
  String get destinationCity => _destinationCity;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  bool get isACFilterEnabled => _isACFilterEnabled;
  bool get isSleeperFilterEnabled => _isSleeperFilterEnabled;
  bool get isLuxuryFilterEnabled => _isLuxuryFilterEnabled;
  List<Map<String, dynamic>> get busResults => _busResults;
  List<Map<String, dynamic>> get filteredBusResults => _filteredBusResults;
  List<Map<String, dynamic>> get amenities => _amenities;
  List<Map<String, dynamic>> get bookings => _bookings;
  List<Map<String, dynamic>> get drivers => _drivers;
  List<Map<String, dynamic>> get pickupPoints => _pickupPoints;
  List<Map<String, dynamic>> get promotions => _promotions;
  List<Map<String, dynamic>> get startPoints => _startPoints;
  List<Map<String, dynamic>> get users => _users;

  // Initialize with search parameters
  void initialize(String source, String destination, DateTime date) {
    _sourceCity = source;
    _destinationCity = destination;
    _selectedDate = date;
    _loadTripResults(); // Changed from _loadBusResults to _loadTripResults
    fetchAllCollections();
  }

  // New method to load trip results based on source and destination
  Future<void> _loadTripResults() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Step 1: Find matching startPoints and destinations
      String? startPointId = await _findStartPointId(_sourceCity);
      String? destinationId = await _findDestinationId(_destinationCity);

      if (startPointId == null || destinationId == null) {
        print(
          '❌ Could not find startPointId: $startPointId or destinationId: $destinationId',
        );
        _busResults = [];
        _filteredBusResults = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      print(
        '✅ Found startPointId: $startPointId, destinationId: $destinationId',
      );

      // Step 2: Query trips collection for matching trips
      final tripsSnapshot = await FirebaseFirestore.instance
          .collection('trips')
          .where('startPointId', isEqualTo: startPointId)
          .where('destinationId', isEqualTo: destinationId)
          .where('status', isEqualTo: 'active')
          .get()
          .timeout(const Duration(seconds: 15));

      print('✅ Found ${tripsSnapshot.docs.length} matching trips');

      if (tripsSnapshot.docs.isEmpty) {
        _busResults = [];
        _filteredBusResults = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Step 3: For each trip, get bus details and build result
      List<Map<String, dynamic>> busList = [];
      final selectedDateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final currentDay = DateFormat('EEEE').format(_selectedDate).toLowerCase();

      for (var tripDoc in tripsSnapshot.docs) {
        final tripData = tripDoc.data();
        final busId = tripData['busId'] as String;
        final tripId = tripDoc.id;

        try {
          // Get bus details
          final busDoc = await FirebaseFirestore.instance
              .collection('buses')
              .doc(busId)
              .get();

          if (!busDoc.exists) {
            print('❌ Bus not found for busId: $busId');
            continue;
          }

          final busData = busDoc.data()!;

          // Check if bus is running on selected day
          final offDays =
              (busData['offDays'] as List<dynamic>?)
                  ?.map((day) => day.toString().toLowerCase())
                  .toList() ??
              [];

          if (offDays.contains(currentDay)) {
            print('⏸️ Bus $busId is off on $currentDay');
            continue;
          }

          // Calculate total seats from layout
          int totalSeats = _calculateTotalSeats(busData);
          if (totalSeats == 0) {
            totalSeats = busData['totalSeat'] ?? 0;
          }

          // Fetch confirmed bookings for this trip & date
          final bookingsSnapshot = await FirebaseFirestore.instance
              .collection('bookings')
              .where('tripId', isEqualTo: tripId) // Use tripId instead of busId
              .where('bookingDate', isEqualTo: selectedDateString)
              .where('status', isEqualTo: 'confirmed')
              .get();

          List<int> bookedSeats = [];
          for (var booking in bookingsSnapshot.docs) {
            final bookingData = booking.data();
            bookedSeats.addAll(
              (bookingData['seats'] as List<dynamic>? ?? []).map(
                (s) => s as int,
              ),
            );
          }

          final bookedSeatsCount = bookedSeats.length;
          final availableSeats = totalSeats - bookedSeatsCount;

          // Skip if no seats available
          if (availableSeats <= 0) {
            print('❌ No seats available for trip: $tripId');
            continue;
          }

          // Fetch fares for this bus/trip
          final faresSnapshot = await FirebaseFirestore.instance
              .collection('fares')
              .where('busId', isEqualTo: busId)
              .get();

          int startingPrice = busData['ticketPrice'] ?? 500;
          if (faresSnapshot.docs.isNotEmpty) {
            final seatPrices = faresSnapshot.docs
                .map((d) => (d.data()['price'] ?? startingPrice) as int)
                .toList();
            if (seatPrices.isNotEmpty) {
              startingPrice = seatPrices.reduce((a, b) => a < b ? a : b);
            }
          }

          final singleSeats = _calculateSingleSeats(busData);

          // Build final bus/trip object
          busList.add({
            'id': busId,
            'tripId': tripId, // Add trip ID for booking reference
            'operatorGroup': {
              'name': busData['name'] ?? 'Unknown Bus',
              'subtitle': 'Bus Operator',
              'busCount': 1,
              'startingPrice': '₹$startingPrice',
            },
            'departureTime': tripData['startPointTime'] ?? '06:00',
            'arrivalTime': tripData['dropPointTime'] ?? '13:30',
            'duration': '${tripData['journeyDuration'] ?? 7}h 30m',
            'totalSeats': totalSeats,
            'availableSeats': availableSeats,
            'bookedSeats': bookedSeats,
            'singleSeats': singleSeats,
            'seats': '$availableSeats Seats ($singleSeats Single)',
            'busName': busData['name'] ?? busData['busNumber'] ?? 'Unknown Bus',
            'busNumber': busData['busNumber'] ?? '',
            'busType': _getBusType(busData),
            'price': '₹$startingPrice',
            'rating': (busData['rating'] as num?)?.toDouble() ?? 4.0,
            'reviewCount': busData['reviewCount'] ?? 0,
            'isNewBus': busData['isNewBus'] ?? false,
            'hasAC': busData['hasAC'] ?? false,
            'hasSleeper': busData['isSleeper'] ?? false,
            'isLuxury': busData['isLuxury'] ?? false,
            'facilities': List<String>.from(busData['facilities'] ?? []),
            'seatLayout': busData['seatLayout'],
            'driverMobile': busData['driverMobile'],
            'totalDecker': busData['totalDecker'] ?? 'single',
            // Trip specific data
            'tripTitle': tripData['title'] ?? 'Unknown Trip',
            'pickupPoints': tripData['pickupPoints'] ?? [],
            'dynamicPricing': tripData['dynamicPricing'] ?? [],
            'liveStatus': tripData['liveStatus'] ?? 'inactive',
          });

          print(
            '✅ Added trip: ${tripData['title']} with $availableSeats available seats',
          );
        } catch (e) {
          print('❌ Error processing trip $tripId: $e');
          continue;
        }
      }

      _busResults = busList;
      _filteredBusResults = List.from(_busResults);
      print('✅ Total trip results: ${_busResults.length}');
    } catch (e) {
      print('❌ Error fetching trip data: $e');
      _busResults = [];
      _filteredBusResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper method to find startPointId based on source city name
  Future<String?> _findStartPointId(String cityName) async {
    try {
      // First try to find in startPoints collection
      final startPointsSnapshot = await FirebaseFirestore.instance
          .collection('startPoints')
          .where('name', isEqualTo: cityName)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (startPointsSnapshot.docs.isNotEmpty) {
        return startPointsSnapshot.docs.first.id;
      }

      // If not found in startPoints, try pickupPoints collection
      final pickupPointsSnapshot = await FirebaseFirestore.instance
          .collection('pickupPoints')
          .where('name', isEqualTo: cityName)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (pickupPointsSnapshot.docs.isNotEmpty) {
        // You might need to find which startPoint this pickupPoint belongs to
        // For now, we'll return null and suggest creating proper relationships
        print('⚠️ Found pickup point but need to map to startPoint');
        return null;
      }

      return null;
    } catch (e) {
      print('❌ Error finding startPointId for $cityName: $e');
      return null;
    }
  }

  // Helper method to find destinationId based on destination city name
  Future<String?> _findDestinationId(String cityName) async {
    try {
      final destinationsSnapshot = await FirebaseFirestore.instance
          .collection('destinations')
          .where('name', isEqualTo: cityName)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (destinationsSnapshot.docs.isNotEmpty) {
        return destinationsSnapshot.docs.first.id;
      }

      return null;
    } catch (e) {
      print('❌ Error finding destinationId for $cityName: $e');
      return null;
    }
  }

  // Fetch Amenities
  Future<void> fetchAmenities() async {
    try {
      final amenitiesSnapshot = await FirebaseFirestore.instance
          .collection('amenities')
          .get()
          .timeout(const Duration(seconds: 10));

      _amenities = amenitiesSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      print("✅ Amenities fetched: ${_amenities.length} items");
      notifyListeners();
    } catch (e) {
      print('❌ Error fetching amenities: $e');
      _amenities = [];
    }
  }

  // Fetch Bookings
  Future<void> fetchBookings() async {
    try {
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .get()
          .timeout(const Duration(seconds: 10));

      _bookings = bookingsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      print("✅ Bookings fetched: ${_bookings.length} items");
      notifyListeners();
    } catch (e) {
      print('❌ Error fetching bookings: $e');
      _bookings = [];
    }
  }

  // Fetch Drivers
  Future<void> fetchDrivers() async {
    try {
      final driversSnapshot = await FirebaseFirestore.instance
          .collection('drivers')
          .get()
          .timeout(const Duration(seconds: 10));

      _drivers = driversSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      print("✅ Drivers fetched: ${_drivers.length} items");
      notifyListeners();
    } catch (e) {
      print('❌ Error fetching drivers: $e');
      _drivers = [];
    }
  }

  // Fetch Pickup Points
  Future<void> fetchPickupPoints() async {
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

  // Fetch Promotions
  Future<void> fetchPromotions() async {
    try {
      final promotionsSnapshot = await FirebaseFirestore.instance
          .collection('promotions')
          .get()
          .timeout(const Duration(seconds: 10));

      _promotions = promotionsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      print("✅ Promotions fetched: ${_promotions.length} items");
      notifyListeners();
    } catch (e) {
      print('❌ Error fetching promotions: $e');
      _promotions = [];
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

  // Fetch Users
  Future<void> fetchUsers() async {
    try {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get()
          .timeout(const Duration(seconds: 10));

      _users = usersSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      print("✅ Users fetched: ${_users.length} items");
      notifyListeners();
    } catch (e) {
      print('❌ Error fetching users: $e');
      _users = [];
    }
  }

  // Fetch all collections at once
  Future<void> fetchAllCollections() async {
    try {
      await Future.wait([
        fetchAmenities(),
        fetchBookings(),
        fetchDrivers(),
        fetchPickupPoints(),
        fetchPromotions(),
        fetchStartPoints(),
        fetchUsers(),
      ]);
    } catch (e) {
      print('❌ Error fetching all collections: $e');
    }
  }

  // Get formatted date string
  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final selectedDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    if (selectedDay == today) {
      return "Today, ${_formatDate(_selectedDate)}";
    } else if (selectedDay == tomorrow) {
      return "Tomorrow, ${_formatDate(_selectedDate)}";
    } else {
      return _formatDate(_selectedDate);
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM').format(date);
  }

  // Helper methods (unchanged)
  String _getBusType(Map<String, dynamic> data) {
    final hasAC = data['hasAC'] ?? false;
    final isSleeper = data['isSleeper'] ?? false;
    final isLuxury = data['isLuxury'] ?? false;

    if (isLuxury) {
      return isSleeper ? 'Luxury Sleeper' : 'Luxury Seater';
    } else if (isSleeper) {
      return hasAC ? 'A/C Sleeper' : 'Non A/C Sleeper';
    } else {
      return hasAC ? 'A/C Seater' : 'Non A/C Seater';
    }
  }

  int _calculateTotalSeats(Map<String, dynamic> data) {
    int totalSeats = 0;

    final seatLayout = data['seatLayout'] as Map<String, dynamic>?;
    if (seatLayout != null) {
      final grid = seatLayout['grid'] as List<dynamic>? ?? [];
      totalSeats += grid
          .where((seat) => (seat as Map<String, dynamic>?)?['type'] == 'seat')
          .length;
    }

    final lowerSeatLayout = data['lowerSeatLayout'] as Map<String, dynamic>?;
    if (lowerSeatLayout != null) {
      final lowerGrid = lowerSeatLayout['grid'] as List<dynamic>? ?? [];
      totalSeats += lowerGrid
          .where((seat) => (seat as Map<String, dynamic>?)?['type'] == 'seat')
          .length;
    }

    final upperSeatLayout = data['upperSeatLayout'] as Map<String, dynamic>?;
    if (upperSeatLayout != null) {
      final upperGrid = upperSeatLayout['grid'] as List<dynamic>? ?? [];
      totalSeats += upperGrid
          .where((seat) => (seat as Map<String, dynamic>?)?['type'] == 'seat')
          .length;
    }

    return totalSeats;
  }

  int _calculateSingleSeats(Map<String, dynamic> data) {
    int singleSeats = 0;
    final totalDecker = data['totalDecker'] as String? ?? 'single';

    if (totalDecker == 'single') {
      final seatLayout = data['seatLayout'] as Map<String, dynamic>?;
      if (seatLayout != null) {
        final cols = seatLayout['cols'] as int? ?? 4;
        final grid = seatLayout['grid'] as List<dynamic>? ?? [];

        if (cols <= 3) {
          final totalRows = (grid.length / cols).ceil();
          singleSeats = totalRows;
        } else {
          singleSeats =
              (grid
                          .where(
                            (seat) =>
                                (seat as Map<String, dynamic>?)?['type'] ==
                                'seat',
                          )
                          .length *
                      0.3)
                  .floor();
        }
      }
    } else {
      final lowerSeatLayout = data['lowerSeatLayout'] as Map<String, dynamic>?;
      if (lowerSeatLayout != null) {
        final lowerGrid = lowerSeatLayout['grid'] as List<dynamic>? ?? [];
        singleSeats += lowerGrid.where((seat) {
          final seatData = seat as Map<String, dynamic>?;
          return seatData?['type'] == 'seat' &&
              seatData?['category'] == 'seater';
        }).length;
      }
    }

    return singleSeats;
  }

  // Filter methods
  void toggleACFilter() {
    _isACFilterEnabled = !_isACFilterEnabled;
    _applyFilters();
    notifyListeners();
  }

  void toggleSleeperFilter() {
    _isSleeperFilterEnabled = !_isSleeperFilterEnabled;
    _applyFilters();
    notifyListeners();
  }

  void toggleLuxuryFilter() {
    _isLuxuryFilterEnabled = !_isLuxuryFilterEnabled;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredBusResults = _busResults.where((bus) {
      bool passesFilter = true;

      if (_isACFilterEnabled && !bus['hasAC']) {
        passesFilter = false;
      }

      if (_isSleeperFilterEnabled && !bus['hasSleeper']) {
        passesFilter = false;
      }

      if (_isLuxuryFilterEnabled && !bus['isLuxury']) {
        passesFilter = false;
      }

      if (bus['availableSeats'] <= 0) {
        passesFilter = false;
      }

      return passesFilter;
    }).toList();
  }

  // Action methods
  void openFilters() {
    // TODO: Implement filter modal
  }

  // Removed selectedDate parameter from selectBus method
  void selectBus(BuildContext context, Map<String, dynamic> bus) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusDetailScreen(
          bus: bus,
          sourceCity: _sourceCity,
          destinationCity: _destinationCity,
          selectedDate: _selectedDate,
        ),
      ),
    );
  }

  void sortBuses(String sortType) {
    switch (sortType) {
      case 'price_low_to_high':
        _filteredBusResults.sort((a, b) {
          final priceA = int.parse(
            a['price'].toString().replaceAll(RegExp(r'[₹,]'), ''),
          );
          final priceB = int.parse(
            b['price'].toString().replaceAll(RegExp(r'[₹,]'), ''),
          );
          return priceA.compareTo(priceB);
        });
        break;
      case 'price_high_to_low':
        _filteredBusResults.sort((a, b) {
          final priceA = int.parse(
            a['price'].toString().replaceAll(RegExp(r'[₹,]'), ''),
          );
          final priceB = int.parse(
            b['price'].toString().replaceAll(RegExp(r'[₹,]'), ''),
          );
          return priceB.compareTo(priceA);
        });
        break;
      case 'departure_earliest':
        _filteredBusResults.sort((a, b) {
          final timeA = _parseTime(a['departureTime']);
          final timeB = _parseTime(b['departureTime']);
          return timeA.compareTo(timeB);
        });
        break;
      case 'departure_latest':
        _filteredBusResults.sort((a, b) {
          final timeA = _parseTime(a['departureTime']);
          final timeB = _parseTime(b['departureTime']);
          return timeB.compareTo(timeA);
        });
        break;
      case 'duration_shortest':
        _filteredBusResults.sort((a, b) {
          final durationA = _parseDuration(a['duration']);
          final durationB = _parseDuration(b['duration']);
          return durationA.compareTo(durationB);
        });
        break;
      case 'rating_highest':
        _filteredBusResults.sort((a, b) {
          final ratingA = a['rating'] ?? 0.0;
          final ratingB = b['rating'] ?? 0.0;
          return ratingB.compareTo(ratingA);
        });
        break;
      case 'seats_available':
        _filteredBusResults.sort((a, b) {
          final seatsA = a['availableSeats'] ?? 0;
          final seatsB = b['availableSeats'] ?? 0;
          return seatsB.compareTo(seatsA);
        });
        break;
    }
    notifyListeners();
  }

  int _parseTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return hour * 60 + minute;
  }

  int _parseDuration(String duration) {
    final regex = RegExp(r'(\d+)h\s*(\d+)m');
    final match = regex.firstMatch(duration);
    if (match != null) {
      final hours = int.parse(match.group(1)!);
      final minutes = int.parse(match.group(2)!);
      return hours * 60 + minutes;
    }
    return 0;
  }

  // Refresh results
  Future<void> refreshResults() async {
    await _loadTripResults();
    await fetchAllCollections();
  }

  // Clear all filters
  void clearAllFilters() {
    _isACFilterEnabled = false;
    _isSleeperFilterEnabled = false;
    _isLuxuryFilterEnabled = false;
    _filteredBusResults = List.from(_busResults);
    notifyListeners();
  }

  // Update available seats after booking
  void updateAvailableSeats(String busId, int bookedSeats) {
    final busIndex = _busResults.indexWhere((bus) => bus['id'] == busId);
    if (busIndex != -1) {
      final currentAvailable = _busResults[busIndex]['availableSeats'] ?? 0;
      _busResults[busIndex]['availableSeats'] = currentAvailable - bookedSeats;

      final singleSeats = _busResults[busIndex]['singleSeats'];
      final newAvailable = _busResults[busIndex]['availableSeats'];
      _busResults[busIndex]['seats'] =
          '$newAvailable Seats ($singleSeats Single)';

      _applyFilters();
      notifyListeners();
    }
  }
}
