import 'package:darshan_trip/features/home/view/bus_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/search_results_viewmodel.dart';

class SearchResultsScreen extends StatelessWidget {
  final String sourceCity;
  final String destinationCity;
  final DateTime selectedDate;

  const SearchResultsScreen({
    super.key,
    required this.sourceCity,
    required this.destinationCity,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          SearchResultsViewModel()
            ..initialize(sourceCity, destinationCity, selectedDate),
      child: Consumer<SearchResultsViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: _buildAppBar(context, viewModel),
            body: viewModel.isLoading
                ? _buildLoadingWidget()
                : Column(
                    children: [
                      _buildSearchSummary(viewModel),
                      _buildFiltersSection(viewModel),
                      Expanded(child: _buildBusResultsList(viewModel)),
                    ],
                  ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    SearchResultsViewModel viewModel,
  ) {
    return AppBar(
      backgroundColor: Colors.orange.shade600,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${viewModel.sourceCity} → ${viewModel.destinationCity}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '${viewModel.busResults.length} Buses',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _buildDateDisplay(viewModel),
        ),
      ],
    );
  }

  Widget _buildDateDisplay(SearchResultsViewModel viewModel) {
    try {
      // Safely parse the formatted date
      final formattedDate = viewModel.formattedDate;
      final parts = formattedDate.contains(',')
          ? formattedDate.split(',')
          : [formattedDate, ''];

      final dayPart = parts.isNotEmpty ? parts[0].trim() : 'Today';
      final datePart = parts.length > 1 ? parts[1].trim() : formattedDate;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            datePart.isNotEmpty ? datePart : dayPart,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (datePart.isNotEmpty && dayPart != datePart)
            Text(
              dayPart,
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
        ],
      );
    } catch (e) {
      print('❌ Error building date display: $e');
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Selected Date',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
          SizedBox(height: 16),
          Text(
            'Searching buses...',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSummary(SearchResultsViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.directions_bus, color: Colors.orange.shade600, size: 20),
          const SizedBox(width: 8),
          const Text(
            'Buses',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${viewModel.busResults.length} found',
              style: const TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(SearchResultsViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Filter & Sort -> plain text style
            _buildSortTextButton(
              'Filter & Sort',
              Icons.filter_list,
              () => viewModel.openFilters(),
            ),
            const SizedBox(width: 16),

            // Normal filter chips
            _buildFilterChip(
              'AC',
              Icons.ac_unit,
              viewModel.isACFilterEnabled,
              () => viewModel.toggleACFilter(),
            ),
            const SizedBox(width: 12),
            _buildFilterChip(
              'SLEEPER',
              Icons.airline_seat_flat,
              viewModel.isSleeperFilterEnabled,
              () => viewModel.toggleSleeperFilter(),
            ),
            const SizedBox(width: 12),
            _buildFilterChip(
              'LUXURY',
              Icons.star,
              viewModel.isLuxuryFilterEnabled,
              () => viewModel.toggleLuxuryFilter(),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Normal text style for "Filter & Sort"
  Widget _buildSortTextButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.black87, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.shade600 : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.orange.shade600 : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusResultsList(SearchResultsViewModel viewModel) {
    if (viewModel.filteredBusResults.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.filteredBusResults.length,
      itemBuilder: (context, index) {
        // This provides the context
        final bus = viewModel.filteredBusResults[index];
        return _buildBusCard(context, bus, viewModel); // Pass context here
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_bus_outlined, color: Colors.grey, size: 64),
          SizedBox(height: 16),
          Text(
            'No buses found',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search criteria',
            style: TextStyle(color: Colors.grey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBusCard(
    BuildContext context,
    Map<String, dynamic> bus,
    SearchResultsViewModel viewModel,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Bus operator header
          if (bus['operatorGroup'] != null) _buildOperatorHeader(bus),

          // Bus details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Time and route info
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bus['departureTime'] ?? '06:00',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          bus['duration'] ?? '7h 30m',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(height: 1, color: Colors.grey.shade300),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          bus['arrivalTime'] ?? '13:30',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          bus['seats'] ?? '40 Seats',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Bus name and facilities
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bus['busName'] ?? 'Unknown Bus',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bus['busType'] ?? 'A/C Seater',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (bus['isNewBus'] == true) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'New Bus',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (bus['rating'] != null &&
                                  bus['rating'] > 0) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.white,
                                        size: 10,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        bus['rating'].toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          bus['price'] ?? '₹500',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Onwards',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    // Removed selectedDate from navigation - only pass required parameters
                    onPressed: () {
                      try {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BusDetailScreen(
                              bus: bus,
                              sourceCity: viewModel.sourceCity,
                              destinationCity: viewModel.destinationCity,
                              selectedDate: viewModel.selectedDate,
                            ),
                          ),
                        );
                      } catch (e) {
                        print('❌ Error navigating to bus detail: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error opening bus details'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Select Seats',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildOperatorHeader(Map<String, dynamic> bus) {
    try {
      final operatorGroup = bus['operatorGroup'] as Map<String, dynamic>?;

      if (operatorGroup == null) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade600, Colors.orange.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  (operatorGroup['name'] ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    operatorGroup['name'] ?? 'Unknown Operator',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    operatorGroup['subtitle'] ?? 'Bus Operator',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      );
    } catch (e) {
      print('❌ Error building operator header: $e');
      return const SizedBox.shrink();
    }
  }
}
