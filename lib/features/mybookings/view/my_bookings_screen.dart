import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../viewmodel/bookings_viewmodel.dart';
import 'bus_ticket_screen.dart'; // Import the BusTicketScreen

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late BookingsViewModel _bookingsViewModel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _bookingsViewModel = context.read<BookingsViewModel>();

    // Fetch bookings and all policies when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bookingsViewModel.fetchUserBookings();
      _bookingsViewModel.fetchOperatorPolicy();
      _bookingsViewModel.fetchModifyPolicy(); // Fetch modify policy
      _bookingsViewModel.fetchCancelPolicy(); // Fetch cancel policy
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "My Bookings",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange.shade600,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.policy, color: Colors.white),
            onPressed: _showOperatorPolicy,
            tooltip: 'View Cancellation Policy',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _bookingsViewModel.retryFetchBookings(),
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "All"),
            Tab(text: "Upcoming"),
            Tab(text: "Past"),
          ],
        ),
      ),
      body: Consumer<BookingsViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFF5A623)),
            );
          }

          if (viewModel.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    viewModel.error!,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      viewModel.clearError();
                      viewModel.fetchUserBookings();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5A623),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      "Retry",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }

          if (viewModel.bookings.isEmpty) {
            return _buildEmptyState();
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildBookingsList(viewModel.bookings),
              _buildBookingsList(viewModel.getUpcomingBookings()),
              _buildBookingsList(viewModel.getPastBookings()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 100, color: Colors.grey.shade400),
            const SizedBox(height: 32),
            const Text(
              "No Bookings Yet",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "You haven't booked any trips yet. Start exploring and book your first trip now!",
              style: TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/home');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5A623),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Explore Trips",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsList(List<Map<String, dynamic>> bookings) {
    if (bookings.isEmpty) {
      return const Center(
        child: Text(
          "No bookings found",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _bookingsViewModel.fetchUserBookings(),
      color: const Color(0xFFF5A623),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          final busData = booking['busData'] ?? {};

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BusTicketScreen(booking: booking),
                ),
              );
            },
            child: _buildBookingCard(booking, busData),
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(
    Map<String, dynamic> booking,
    Map<String, dynamic> busData,
  ) {
    final bookingDateStr = booking['bookingDate']?.toString() ?? '';
    DateTime bookingDate;
    try {
      bookingDate = DateFormat('yyyy-MM-dd').parse(bookingDateStr);
    } catch (e) {
      bookingDate = DateTime.now();
    }

    final bookingTime = booking['createdAt'] is Timestamp
        ? (booking['createdAt'] as Timestamp).toDate()
        : DateTime.now();

    final status = booking['status']?.toString() ?? 'unknown';
    final seats =
        (booking['seats'] as List<dynamic>?)
            ?.map((s) => s.toString())
            .toList() ??
        [];
    final sourceCity =
        booking['sourceCity']?.toString() ??
        busData['from']?.toString() ??
        'Unknown';
    final destinationCity =
        booking['destinationCity']?.toString() ??
        busData['to']?.toString() ??
        'Unknown';
    final passengerNames = booking['passengerName']?.toString() ?? 'Unknown';

    final canCancelOrModify = _bookingsViewModel.canCancelOrModifyBooking(
      booking,
    );
    final refundAmount = _bookingsViewModel.calculateRefundAmount(booking);
    final refundPercentage = _bookingsViewModel.getRefundPercentage(booking);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.orange.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with booking ID and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _bookingsViewModel.getStatusColor(status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _bookingsViewModel.getStatusIcon(status),
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          status.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (String value) {
                      switch (value) {
                        case 'modify':
                          _showModifyDialog(booking);
                          break;
                        case 'cancel':
                          _showCancelDialog(booking);
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      List<PopupMenuEntry<String>> items = [];
                      if (canCancelOrModify &&
                          booking['status']?.toString().toLowerCase() ==
                              'confirmed') {
                        items.add(
                          const PopupMenuItem<String>(
                            value: 'modify',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Colors.blue, size: 18),
                                SizedBox(width: 8),
                                Text('Modify Booking'),
                              ],
                            ),
                          ),
                        );
                        items.add(
                          const PopupMenuItem<String>(
                            value: 'cancel',
                            child: Row(
                              children: [
                                Icon(Icons.cancel, color: Colors.red, size: 18),
                                SizedBox(width: 8),
                                Text('Cancel Booking'),
                              ],
                            ),
                          ),
                        );
                      }
                      return items;
                    },
                    icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                  ),
                ],
              ),
              if (booking['id'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Text(
                        'ID: ${booking['id'].toString().substring(0, 8)}...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontFamily: 'monospace',
                        ),
                      ),
                      if ((booking['modificationCount'] ?? 0) > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Modified ${booking['modificationCount']}x',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.directions_bus,
                      color: Colors.orange.shade600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          busData['busName']?.toString() ??
                              busData['name']?.toString() ??
                              'Unknown Bus',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$sourceCity → $destinationCity',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      Icons.calendar_today,
                      'Travel Date',
                      DateFormat('dd MMM yyyy').format(bookingDate),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      Icons.event_seat,
                      'Seats',
                      seats.join(', '),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      Icons.person,
                      'Passenger(s)',
                      passengerNames,
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      Icons.phone,
                      'Contact',
                      booking['passengerContact']?.toString() ?? 'Not provided',
                    ),
                    if (booking['pickupPoint'] != null) ...[
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        Icons.location_on,
                        'Pickup',
                        booking['sourceCity'].toString(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${booking['totalFare']?.toString() ?? '0'}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      if (status == 'confirmed' && canCancelOrModify)
                        Text(
                          'Refund: ₹${refundAmount.toStringAsFixed(0)} ($refundPercentage)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade600,
                          ),
                        ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Booked: ${DateFormat('dd/MM/yyyy').format(bookingTime)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (booking['lastModifiedAt'] != null &&
                          booking['lastModifiedAt'] is Timestamp)
                        Text(
                          'Modified: ${DateFormat('dd/MM/yyyy').format((booking['lastModifiedAt'] as Timestamp).toDate())}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showModifyDialog(Map<String, dynamic> booking) {
    final passengers =
        (booking['passengers'] as List<dynamic>?)
            ?.map((p) => Map<String, dynamic>.from(p))
            .toList() ??
        [];

    final List<TextEditingController> nameControllers = passengers
        .map((p) => TextEditingController(text: p['name']?.toString() ?? ''))
        .toList();
    final List<TextEditingController> contactControllers = passengers
        .map((p) => TextEditingController(text: p['contact']?.toString() ?? ''))
        .toList();
    final List<TextEditingController> ageControllers = passengers
        .map((p) => TextEditingController(text: p['age']?.toString() ?? ''))
        .toList();
    final List<TextEditingController> genderControllers = passengers
        .map((p) => TextEditingController(text: p['gender']?.toString() ?? ''))
        .toList();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Modify Booking",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // 🔹 Passenger forms
              for (int i = 0; i < passengers.length; i++) ...[
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Passenger ${i + 1}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: nameControllers[i],
                          decoration: InputDecoration(
                            labelText: "Name",
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: contactControllers[i],
                          decoration: InputDecoration(
                            labelText: "Contact",
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: ageControllers[i],
                          decoration: InputDecoration(
                            labelText: "Age",
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: genderControllers[i],
                          decoration: InputDecoration(
                            labelText: "Gender",
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // 🔹 Buttons row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.orange.shade600),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.orange.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);

                        final updatedPassengers = List.generate(
                          passengers.length,
                          (i) {
                            return {
                              'name': nameControllers[i].text.trim(),
                              'contact': contactControllers[i].text.trim(),
                              'age':
                                  int.tryParse(ageControllers[i].text.trim()) ??
                                  0,
                              'gender': genderControllers[i].text.trim(),
                            };
                          },
                        );

                        final success = await _bookingsViewModel.modifyBooking(
                          bookingId: booking['id']?.toString() ?? '',
                          updatedPassengers: updatedPassengers,
                        );

                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Booking modified successfully',
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _bookingsViewModel.error ??
                                    'Failed to modify booking',
                              ),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Save Changes",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCancelDialog(Map<String, dynamic> booking) {
    final refundAmount = _bookingsViewModel.calculateRefundAmount(booking);
    final refundPercentage = _bookingsViewModel.getRefundPercentage(booking);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text('Cancel Booking'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to cancel this booking?',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Consumer<BookingsViewModel>(
                builder: (context, viewModel, child) {
                  final policy = viewModel.cancelPolicy;
                  if (policy == null) {
                    return const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading cancellation policy...'),
                      ],
                    );
                  }

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cancellation Policy:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          policy['content']?.toString() ??
                              'No cancellation policy content available',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Refund Information:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Amount: Rs ${refundAmount.toStringAsFixed(0)}'),
                        Text('Percentage: $refundPercentage'),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              print('🎯 Cancel button pressed for booking: ${booking['id']}');

              final success = await _bookingsViewModel.cancelBooking(
                booking['id']?.toString() ?? '',
              );

              // Verify the update in Firestore
              await _bookingsViewModel.verifyBookingStatus(
                booking['id']?.toString() ?? '',
              );

              if (success && mounted) {
                print('✅ Success reported, refreshing bookings...');
                // Force refresh the bookings list
                await _bookingsViewModel.fetchUserBookings();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Booking cancelled successfully! Refund: Rs ${refundAmount.toStringAsFixed(0)}',
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              } else if (mounted) {
                print('❌ Cancellation failed');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _bookingsViewModel.error ?? 'Failed to cancel booking',
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> booking) {
    final busName =
        booking['busData']?['busName']?.toString() ??
        booking['busData']?['name']?.toString() ??
        'Unknown Bus';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text('Delete Booking'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to permanently delete this booking for $busName?',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.red.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'This action cannot be undone.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              final success = await _bookingsViewModel.deleteBooking(
                booking['id']?.toString() ?? '',
              );

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Booking deleted successfully'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _bookingsViewModel.error ?? 'Failed to delete booking',
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Delete Permanently',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showOperatorPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancellation & Modification Policy'),
        content: Consumer<BookingsViewModel>(
          builder: (context, viewModel, child) {
            final policy = viewModel.operatorPolicy;
            if (policy == null) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading policy...'),
                ],
              );
            }

            return SingleChildScrollView(
              child: Text(
                policy['content']?.toString() ?? 'No policy content available',
                style: const TextStyle(fontSize: 14),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
