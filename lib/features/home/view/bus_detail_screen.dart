import 'package:darshan_trip/features/home/view/passenger_details_screen.dart';
import 'package:darshan_trip/features/home/view/payment_screen.dart';
import 'package:darshan_trip/features/home/viewmodel/bus_detail_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:darshan_trip/features/mybookings/viewmodel/bookings_viewmodel.dart';

class BusDetailScreen extends StatefulWidget {
  final Map<String, dynamic> bus;
  final String? sourceCity;
  final String? destinationCity;
  final DateTime selectedDate;

  const BusDetailScreen({
    super.key,
    required this.bus,
    this.sourceCity,
    this.destinationCity,
    required this.selectedDate,
  });

  @override
  State<BusDetailScreen> createState() => _BusDetailScreenState();
}

class _BusDetailScreenState extends State<BusDetailScreen> {
  bool _isLowerDeck = true;
  bool _isFemalePassenger = false;
  final _formKey = GlobalKey<FormState>();
  final _passengerNameController = TextEditingController();
  final _passengerContactController = TextEditingController();
  final _passengerEmailController = TextEditingController();
  String? _selectedPickupPoint;
  bool _showBreakdown = false;

  @override
  void dispose() {
    _passengerNameController.dispose();
    _passengerContactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BusDetailViewModel(
        bus: widget.bus,
        sourceCity: widget.sourceCity,
        destinationCity: widget.destinationCity,
      )..setSelectedDate(widget.selectedDate),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: _buildAppBar(context),
        body: Consumer<BusDetailViewModel>(
          builder: (context, viewModel, child) {
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBusInfoHeader(viewModel),
                        _buildRouteDetails(viewModel, context),
                        _buildSeatSelection(viewModel, context),
                      ],
                    ),
                  ),
                ),
                _buildBottomBar(viewModel, context),
              ],
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.orange.shade600,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
        tooltip: 'Back',
      ),
      title: Text(
        '${widget.bus['departureTime'] ?? '06:00'} - ${widget.bus['arrivalTime'] ?? '13:30'}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.white),
          onPressed: () => _showBusInfoDialog(context),
          tooltip: 'Bus Information',
        ),
      ],
    );
  }

  Widget _buildBusInfoHeader(BusDetailViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.bus['departureTime'] ?? '06:00'} - ${widget.bus['arrivalTime'] ?? '13:30'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.orange.shade600, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      widget.bus['rating']?.toString() ?? '4.0',
                      style: TextStyle(
                        color: Colors.orange.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.bus['busName'] ?? widget.bus['name'] ?? 'Unknown Bus',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.bus['busType'] ??
                (widget.bus['hasAC'] == true ? 'A/C Seater' : 'Non A/C Seater'),
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.directions_bus,
                color: Colors.orange.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${viewModel.availableSeats} Seats available',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                semanticsLabel: '${viewModel.availableSeats} seats available',
              ),
              const Spacer(),
              Text(
                'From ${widget.bus['price'] ?? '₹${widget.bus['ticketPrice'] ?? 500}'}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteDetails(
    BusDetailViewModel viewModel,
    BuildContext context,
  ) {
    final departureDate = DateTime.now();
    final durationString = widget.bus['duration'] ?? '7h 30m';
    final hours = int.tryParse(durationString.split('h')[0]) ?? 7;
    final arrivalDate = departureDate.add(Duration(hours: hours));

    final fromCity = widget.sourceCity ?? widget.bus['from'] ?? 'Mumbai';
    final toCity = widget.destinationCity ?? widget.bus['to'] ?? 'Delhi';

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bus Route',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Icon(Icons.circle, color: Colors.orange.shade600, size: 12),
                  SizedBox(
                    height: 40,
                    child: VerticalDivider(
                      color: Colors.grey.shade300,
                      thickness: 1,
                    ),
                  ),
                  Icon(Icons.location_on, color: Colors.red.shade400, size: 16),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fromCity,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.bus['departureTime'] ?? '06:00'} - ${DateFormat('dd MMM').format(departureDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      toCity,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.bus['arrivalTime'] ?? '13:30'} - ${DateFormat('dd MMM').format(arrivalDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    durationString,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    viewModel.isLoadingAdditionalData
                        ? 'Calculating distance...'
                        : '${viewModel.distanceInKm.toStringAsFixed(0)} km',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _showAllStops(context, viewModel),
            child: Row(
              children: [
                Text(
                  'View all stops',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.orange.shade600,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatSelection(
    BusDetailViewModel viewModel,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Seats',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${viewModel.selectedSeats.length} selected',
                style: TextStyle(fontSize: 14, color: Colors.orange.shade600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSeatLegend(),
          const SizedBox(height: 16),

          // 👇👇 Add decker tabs only if double decker
          if (viewModel.isDoubleDecker) ...[
            _buildDeckerTabs(viewModel),
            const SizedBox(height: 16),
          ],

          Row(
            children: [
              const Text(
                'Female Passenger',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(width: 8),
              Switch(
                value: _isFemalePassenger,
                onChanged: (value) {
                  setState(() {
                    _isFemalePassenger = value;
                    // ... (same deselection logic as before)
                  });
                },
                activeColor: Colors.orange.shade600,
                activeTrackColor: Colors.orange.shade200,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isFemalePassenger
                ? 'Female passengers can select any available seat including female-only seats'
                : 'Male passengers cannot select female-only seats or seats adjacent to female passengers',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),

          const SizedBox(height: 16),

          // 👇👇 Now seat grid will respect lower/upper tab
          _buildSeatGrid(viewModel, context),
        ],
      ),
    );
  }

  Widget _buildSeatLegend() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildLegendItem(
            icon: Icons.event_seat,
            color: Colors.grey.shade200,
            label: 'Available',
          ),
          const SizedBox(width: 16),
          _buildLegendItem(
            icon: Icons.event_seat,
            color: Colors.orange.shade100,
            label: 'Selected',
          ),
          const SizedBox(width: 16),
          _buildLegendItem(
            icon: Icons.event_seat,
            color: Colors.grey.shade500,
            label: 'Booked',
          ),
          const SizedBox(width: 16),
          _buildLegendItem(
            icon: Icons.event_seat,
            color: Colors.pink.shade200,
            label: 'Female Only',
            extraIcon: Icons.female,
          ),
          const SizedBox(width: 16),
          _buildLegendItem(
            icon: Icons.king_bed,
            color: Colors.blue.shade100,
            label: 'Sleeper',
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required IconData icon,
    required Color color,
    required String label,
    IconData? extraIcon,
  }) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            if (extraIcon != null)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(1),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(extraIcon, color: Colors.pink.shade400, size: 8),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDeckerTabs(BusDetailViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isLowerDeck = true;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _isLowerDeck
                      ? Colors.orange.shade600
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Lower Deck (Seater)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isLowerDeck ? Colors.white : Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isLowerDeck = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: !_isLowerDeck
                      ? Colors.orange.shade600
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Upper Deck (Sleeper)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: !_isLowerDeck ? Colors.white : Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatGrid(BusDetailViewModel viewModel, BuildContext context) {
    final seatData = _isLowerDeck
        ? viewModel.seatData
        : viewModel.upperSeatData;

    if (seatData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'Loading seats...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 40,
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              if (widget.bus['driverDirection'] == 'left') ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.drive_eta, size: 16),
                      SizedBox(width: 4),
                      Text('Driver', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                const Spacer(),
              ] else ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.drive_eta, size: 16),
                      SizedBox(width: 4),
                      Text('Driver', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: viewModel.columns,
            childAspectRatio: _isLowerDeck ? 0.8 : 1.2,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: seatData.length,
          itemBuilder: (context, index) {
            final seat = seatData[index];
            return _buildSeatItem(seat, viewModel, context, index);
          },
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isLowerDeck ? Icons.arrow_downward : Icons.arrow_upward,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                _isLowerDeck
                    ? 'Lower Deck - ${seatData.where((s) => s['type'] == 'seat').length} Seater seats'
                    : 'Upper Deck - ${seatData.where((s) => s['type'] == 'seat').length} Sleeper seats',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSeatItem(
    Map<String, dynamic> seat,
    BusDetailViewModel viewModel,
    BuildContext context,
    int index,
  ) {
    final seatType = seat['type'] ?? 'seat';
    final seatNumber = seat['seatNumber']?.toString() ?? '';

    if (seatType == 'empty') {
      return const SizedBox.shrink();
    }

    if (seatType == 'aisle') {
      return Container(
        alignment: Alignment.center,
        child: Container(
          width: 2,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      );
    }

    if (seatType != 'seat' || seatNumber.isEmpty) {
      return const SizedBox.shrink();
    }

    final isSelected = viewModel.selectedSeats.contains(seatNumber);
    final isBooked = seat['isBooked'] == true;
    final isFemaleOnly = seat['isFemaleOnly'] == true;
    final category = seat['category'] ?? 'seater';
    final price = (seat['price'] as num?)?.toDouble() ?? 500.0;

    Color backgroundColor;
    Color borderColor;
    Color iconColor;
    IconData icon = category == 'sleeper' ? Icons.king_bed : Icons.event_seat;

    if (isBooked) {
      backgroundColor = Colors.grey.shade500;
      borderColor = Colors.grey.shade600;
      iconColor = Colors.white;
    } else if (isSelected) {
      backgroundColor = Colors.orange.shade100;
      borderColor = Colors.orange.shade600;
      iconColor = Colors.orange.shade600;
    } else if (isFemaleOnly) {
      backgroundColor = Colors.pink.shade50;
      borderColor = Colors.pink.shade300;
      iconColor = Colors.pink.shade400;
    } else if (category == 'sleeper') {
      backgroundColor = Colors.blue.shade50;
      borderColor = Colors.blue.shade200;
      iconColor = Colors.blue.shade400;
    } else {
      backgroundColor = Colors.grey.shade50;
      borderColor = Colors.grey.shade200;
      iconColor = Colors.grey.shade500;
    }

    return GestureDetector(
      onTap: isBooked
          ? null
          : () {
              if (!viewModel.canSelectSeat(
                seatNumber,
                isFemalePassenger: _isFemalePassenger,
              )) {
                final errorMessage = viewModel.getSeatSelectionErrorMessage(
                  seatNumber,
                  isFemalePassenger: _isFemalePassenger,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(errorMessage),
                    backgroundColor: Colors.red.shade400,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              viewModel.toggleSeatSelection(
                seatNumber,
                isFemalePassenger: _isFemalePassenger,
              );
            },
      child: Semantics(
        label:
            'Seat $seatNumber ${isBooked ? 'booked' : 'available'} ${isFemaleOnly ? 'female only' : ''} $category ₹${price.toInt()}',
        button: !isBooked,
        child: Container(
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.orange.shade200,
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: iconColor,
                      size: category == 'sleeper' ? 20 : 18,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      seatNumber,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.orange.shade800
                            : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '₹${price.toInt()}',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.orange.shade700
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              if (isFemaleOnly && !isBooked)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Tooltip(
                    message: "Reserved for female passengers only",
                    preferBelow: false,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.female,
                        color: Colors.pink.shade500,
                        size: 10, // made slightly bigger for visibility
                      ),
                    ),
                  ),
                ),

              if (isBooked)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Icon(Icons.close, color: Colors.white, size: 10),
                ),
              if (category == 'sleeper' && !isBooked)
                Positioned(
                  bottom: 2,
                  left: 4,
                  right: 4,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BusDetailViewModel viewModel, BuildContext context) {
    // Prepare seat price summary
    final priceSummary = <int, int>{}; // {price: count}
    for (String seatNumber in viewModel.selectedSeats) {
      final seat = viewModel.seatData
          .followedBy(viewModel.upperSeatData)
          .firstWhere(
            (s) => s['seatNumber'] == seatNumber,
            orElse: () => {'price': 500},
          );
      final seatPrice = (seat['price'] as num?)?.toInt() ?? 500;
      priceSummary[seatPrice] = (priceSummary[seatPrice] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (viewModel.selectedSeats.isNotEmpty) ...[
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showBreakdown = !_showBreakdown;
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Price Summary',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Icon(
                      _showBreakdown
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_up,
                      color: Colors.orange.shade600,
                    ),
                  ],
                ),
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  children: [
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: priceSummary.entries.map((entry) {
                        return Chip(
                          label: Text(
                            '₹${entry.key} × ${entry.value}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.grey.shade100,
                        );
                      }).toList(),
                    ),
                    if (viewModel.selectedSeats.length > 5)
                      TextButton(
                        onPressed: () =>
                            _showFullBreakdownModal(context, viewModel),
                        child: Text(
                          'View All Seats',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    Divider(height: 16, color: Colors.grey.shade300),
                  ],
                ),
                crossFadeState: _showBreakdown
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${viewModel.selectedSeats.length} Seats selected'),
                      const SizedBox(height: 4),
                      Text(
                        '₹${viewModel.totalPrice}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: viewModel.selectedSeats.isNotEmpty
                      ? () => _proceedToPayment(context, viewModel)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white, // 👈 ensure text is white
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    minimumSize: const Size(120, 48), // 👈 button big enough
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Continue",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white, // 👈 force text color
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBusInfoDialog(BuildContext context) {
    final facilities = widget.bus['facilities'] as List<dynamic>? ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bus Information'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Operator: ${widget.bus['busName'] ?? widget.bus['name'] ?? 'Unknown'}',
              ),
              const SizedBox(height: 8),
              Text('Bus Number: ${widget.bus['busNumber'] ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text(
                'Type: ${widget.bus['busType'] ?? (widget.bus['hasAC'] == true ? 'A/C' : 'Non A/C')} ${widget.bus['isSleeper'] == true ? 'Sleeper' : 'Seater'}',
              ),
              const SizedBox(height: 8),
              Text('Rating: ${widget.bus['rating']?.toString() ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text('Departure: ${widget.bus['departureTime'] ?? '06:00'}'),
              const SizedBox(height: 8),
              Text('Arrival: ${widget.bus['arrivalTime'] ?? '13:30'}'),
              const SizedBox(height: 8),
              Text('Duration: ${widget.bus['duration'] ?? '7h 30m'}'),
              if (facilities.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Facilities:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ...facilities.map(
                  (facility) => Padding(
                    padding: const EdgeInsets.only(left: 16, top: 2),
                    child: Text('• ${facility.toString().toUpperCase()}'),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAllStops(BuildContext context, BusDetailViewModel viewModel) {
    final fromCity = widget.sourceCity ?? widget.bus['from'] ?? 'Mumbai';
    final toCity = widget.destinationCity ?? widget.bus['to'] ?? 'Delhi';
    final stops = [
      {'name': fromCity},
      ...viewModel.pickupPoints,
      {'name': toCity},
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'All Stops',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                itemCount: stops.length,
                itemBuilder: (context, index) {
                  final stop = stops[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle, // same icon for all
                          color: Colors.orange.shade600,
                          size: 16,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            stop['name'].toString(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _proceedToPayment(BuildContext context, BusDetailViewModel viewModel) {
    if (viewModel.selectedSeats.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PassengerDetailsScreen(
            viewModel: viewModel,
            bus: widget.bus,
            sourceCity: widget.sourceCity,
            destinationCity: widget.destinationCity,
          ),
        ),
      );
    }
  }

  void _showFullBreakdownModal(
    BuildContext context,
    BusDetailViewModel viewModel,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (_, controller) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Full Price Breakdown',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: viewModel.selectedSeats.length,
                    itemBuilder: (context, index) {
                      final seatNumber = viewModel.selectedSeats[index];
                      final seat = viewModel.seatData
                          .followedBy(viewModel.upperSeatData)
                          .firstWhere(
                            (s) => s['seatNumber'] == seatNumber,
                            orElse: () => {'price': 500},
                          );
                      final seatPrice = (seat['price'] as num?)?.toInt() ?? 500;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Seat $seatNumber'),
                            Text('₹$seatPrice'),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Divider(height: 16, color: Colors.grey.shade300),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      '₹${viewModel.totalPrice}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}
