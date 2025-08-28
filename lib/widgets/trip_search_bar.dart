import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TripSearchBar extends StatefulWidget {
  final Function(String, String, DateTime?) onSearch;
  final List<String> cities;

  const TripSearchBar({
    super.key,
    required this.onSearch,
    required this.cities,
  });

  @override
  State<TripSearchBar> createState() => _TripSearchBarState();
}

class _TripSearchBarState extends State<TripSearchBar> {
  final _sourceController = TextEditingController();
  final _destinationController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade600, Colors.orange.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.directions_bus_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  "Bus Tickets",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Safe Travel ✨",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // City Selection and Date
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Source and Destination
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showCityPicker(context, true),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "FROM",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _sourceController.text.isEmpty
                                    ? "Select City"
                                    : _sourceController.text,
                                style: TextStyle(
                                  color: _sourceController.text.isEmpty
                                      ? Colors.grey.shade400
                                      : Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: GestureDetector(
                        onTap: _swapCities,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade600,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.swap_horiz_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showCityPicker(context, false),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "TO",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _destinationController.text.isEmpty
                                    ? "Select City"
                                    : _destinationController.text,
                                style: TextStyle(
                                  color: _destinationController.text.isEmpty
                                      ? Colors.grey.shade400
                                      : Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Date Selection
                GestureDetector(
                  onTap: () => _showDatePicker(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          color: Colors.orange.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "DEPARTURE",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedDate != null
                                  ? DateFormat(
                                      'EEE, dd MMM yyyy',
                                    ).format(_selectedDate!)
                                  : "Select Date",
                              style: TextStyle(
                                color: _selectedDate == null
                                    ? Colors.grey.shade400
                                    : Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Search Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _canSearch
                        ? () => widget.onSearch(
                            _sourceController.text,
                            _destinationController.text,
                            _selectedDate,
                          )
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      shadowColor: Colors.orange.shade200,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_rounded, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          "Search Buses",
                          style: TextStyle(
                            color: _canSearch
                                ? Colors.white
                                : Colors.grey.shade500,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool get _canSearch =>
      _sourceController.text.isNotEmpty &&
      _destinationController.text.isNotEmpty &&
      _selectedDate != null;

  void _swapCities() {
    final temp = _sourceController.text;
    _sourceController.text = _destinationController.text;
    _destinationController.text = temp;
    setState(() {});
  }

  Future<void> _showCityPicker(BuildContext context, bool isSource) async {
    final String? selectedCity = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text(
                      isSource
                          ? 'Select Source City'
                          : 'Select Destination City',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Search cities...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.orange.shade600,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.orange.shade600,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  onChanged: (value) {
                    // Implement city filtering logic here if needed
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Cities list
              Expanded(
                child: ListView.builder(
                  itemCount: widget.cities.length,
                  itemBuilder: (context, index) {
                    final city = widget.cities[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.shade100,
                        child: Icon(
                          Icons.location_city_rounded,
                          color: Colors.orange.shade600,
                        ),
                      ),
                      title: Text(
                        city,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                      onTap: () => Navigator.pop(context, city),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selectedCity != null) {
      setState(() {
        if (isSource) {
          _sourceController.text = selectedCity;
        } else {
          _destinationController.text = selectedCity;
        }
      });
    }
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange.shade600,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      setState(() {
        _selectedDate = selectedDate;
      });
    }
  }
}
