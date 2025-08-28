import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HomeViewModel extends ChangeNotifier {
  int _selectedIndex = 0;
  String _sourceCity = "";
  String _destinationCity = "";
  DateTime _selectedDate = DateTime.now();
  List<String> _cities =
      []; // Will hold combined cities, pickupPoints, and startPoints names
  List<String> _destinations = []; // Will hold only destinations
  bool _isLoadingCities = false;
  bool _isLoadingDestinations = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> loadCities() async {
    if (_cities.isNotEmpty || _isLoadingCities) return;

    _isLoadingCities = true;
    notifyListeners();

    try {
      // Create a set to avoid duplicates
      Set<String> combinedCities = {};

      // Fetch from cities collection
      final citiesSnapshot = await _firestore
          .collection('cities')
          .get()
          .timeout(const Duration(seconds: 10));

      if (citiesSnapshot.docs.isNotEmpty) {
        final cityNames = citiesSnapshot.docs
            .map((doc) => doc['name'] as String)
            .where((name) => name.isNotEmpty);
        combinedCities.addAll(cityNames);
        print("✅ Cities from 'cities' collection: ${cityNames.length}");
      }

      // Fetch from pickupPoints collection
      final pickupPointsSnapshot = await _firestore
          .collection('pickupPoints')
          .where(
            'status',
            isEqualTo: 'active',
          ) // Assuming you want active pickup points
          .get()
          .timeout(const Duration(seconds: 10));

      if (pickupPointsSnapshot.docs.isNotEmpty) {
        final pickupNames = pickupPointsSnapshot.docs
            .map((doc) => doc['name'] as String)
            .where((name) => name.isNotEmpty);
        combinedCities.addAll(pickupNames);
        print("✅ Names from 'pickupPoints' collection: ${pickupNames.length}");
      }

      // Fetch from startPoints collection
      final startPointsSnapshot = await _firestore
          .collection('startPoints')
          .where(
            'status',
            isEqualTo: 'active',
          ) // Assuming you want active start points
          .get()
          .timeout(const Duration(seconds: 10));

      if (startPointsSnapshot.docs.isNotEmpty) {
        final startNames = startPointsSnapshot.docs
            .map((doc) => doc['name'] as String)
            .where((name) => name.isNotEmpty);
        combinedCities.addAll(startNames);
        print("✅ Names from 'startPoints' collection: ${startNames.length}");
      }

      // Convert to sorted list
      _cities = combinedCities.toList()..sort();
      print("✅ Total Combined Cities/Points Fetched: ${_cities.length}");
      print("✅ Sample cities: ${_cities.take(5).toList()}");
    } catch (e) {
      print('Error fetching cities/points from Firestore: $e');
      _cities = [];
    } finally {
      _isLoadingCities = false;
      notifyListeners();
    }
  }

  Future<void> loadDestinations() async {
    if (_destinations.isNotEmpty || _isLoadingDestinations) return;

    _isLoadingDestinations = true;
    notifyListeners();

    try {
      final destinationsSnapshot = await _firestore
          .collection('destinations')
          .where('status', isEqualTo: 'active')
          .get()
          .timeout(const Duration(seconds: 10));

      if (destinationsSnapshot.docs.isNotEmpty) {
        _destinations =
            destinationsSnapshot.docs
                .map((doc) => doc['name'] as String)
                .where((name) => name.isNotEmpty)
                .toList()
              ..sort();
        print("✅ Firestore Destinations Fetched: $_destinations");
      } else {
        print(
          "⚠️ No active destinations found in Firestore 'destinations' collection",
        );
        _destinations = [];
      }
    } catch (e) {
      print('Error fetching destinations from Firestore: $e');
      _destinations = [];
    } finally {
      _isLoadingDestinations = false;
      notifyListeners();
    }
  }

  // Getters
  int get selectedIndex => _selectedIndex;
  String get sourceCity => _sourceCity;
  String get destinationCity => _destinationCity;
  DateTime get selectedDate => _selectedDate;
  List<String> get cities => _cities;
  List<String> get destinations => _destinations;

  bool get isLoadingCities => _isLoadingCities;
  bool get isLoadingDestinations => _isLoadingDestinations;

  // Tab navigation
  void onTabChanged(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  // City selection
  void setSourceCity(String city) {
    _sourceCity = city;
    notifyListeners();
  }

  void setDestinationCity(String city) {
    _destinationCity = city;
    notifyListeners();
  }

  // Swap source and destination
  void swapCities() {
    final temp = _sourceCity;
    _sourceCity = _destinationCity;
    _destinationCity = temp;
    notifyListeners();
  }

  // Date selection
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setToday() {
    _selectedDate = DateTime.now();
    notifyListeners();
  }

  void setTomorrow() {
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    notifyListeners();
  }

  // Search validation
  bool get canSearch => _sourceCity.isNotEmpty && _destinationCity.isNotEmpty;

  // Search buses
  void searchBuses() {
    if (canSearch) {
      notifyListeners();
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
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return "${weekdays[date.weekday - 1]} ${date.day} ${months[date.month - 1]}";
  }

  // Get quick date options
  List<Map<String, dynamic>> get quickDateOptions {
    final now = DateTime.now();
    return [
      {'label': 'Today', 'date': now, 'shortLabel': _formatDate(now)},
      {
        'label': 'Tomorrow',
        'date': now.add(const Duration(days: 1)),
        'shortLabel': _formatDate(now.add(const Duration(days: 1))),
      },
    ];
  }

  // City search functionality
  List<String> searchCities(String query) {
    if (query.isEmpty) return _cities;
    return _cities
        .where((city) => city.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  List<String> searchDestinations(String query) {
    if (query.isEmpty) return _destinations;
    return _destinations
        .where((dest) => dest.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Initialize with empty lists
  void initialize() {
    if (_cities.isEmpty && !_isLoadingCities) loadCities();
    if (_destinations.isEmpty && !_isLoadingDestinations) loadDestinations();
    notifyListeners();
  }

  // Force reload cities and destinations
  Future<void> reloadCities() async {
    _cities.clear();
    await loadCities();
  }

  Future<void> reloadDestinations() async {
    _destinations.clear();
    await loadDestinations();
  }
}
