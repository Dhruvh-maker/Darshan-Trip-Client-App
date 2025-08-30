import 'package:darshan_trip/features/home/view/payment_screen.dart';
import 'package:darshan_trip/features/home/viewmodel/bus_detail_viewmodel.dart';
import 'package:darshan_trip/features/mybookings/viewmodel/bookings_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class PassengerDetailsScreen extends StatefulWidget {
  final BusDetailViewModel viewModel;
  final Map<String, dynamic> bus;
  final String? sourceCity;
  final String? destinationCity;

  const PassengerDetailsScreen({
    super.key,
    required this.viewModel,
    required this.bus,
    this.sourceCity,
    this.destinationCity,
  });

  @override
  State<PassengerDetailsScreen> createState() => _PassengerDetailsScreenState();
}

class _PassengerDetailsScreenState extends State<PassengerDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedPickupPoint;
  final List<Map<String, dynamic>> _passengers = [];
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    // Initialize with one empty passenger form
    _addPassenger();
    // Set default pickup point
    final pickupPoints = widget.viewModel.pickupPoints;
    _selectedPickupPoint = pickupPoints.isNotEmpty
        ? pickupPoints[0]['id']?.toString()
        : null;
  }

  void _addPassenger() {
    setState(() {
      _passengers.add({
        'name': TextEditingController(),
        'age': TextEditingController(),
        'contact': TextEditingController(), // Added contact controller
        'gender': 'Male', // Default gender
      });
    });
  }

  void _removePassenger(int index) {
    setState(() {
      _passengers[index]['name'].dispose();
      _passengers[index]['age'].dispose();
      _passengers[index]['contact'].dispose(); // Dispose contact controller
      _passengers.removeAt(index);
    });
  }

  @override
  void dispose() {
    for (var passenger in _passengers) {
      passenger['name'].dispose();
      passenger['age'].dispose();
      passenger['contact'].dispose(); // Dispose contact controller
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCard(),
              const SizedBox(height: 16),
              _buildPickupPointDropdown(),
              const SizedBox(height: 16),
              _buildPassengerContainer(),
              const SizedBox(height: 16),
              _buildAddPassengerButton(),
              const SizedBox(height: 80), // Space for bottom bar
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.orange.shade600,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Passenger Details',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            'Selected Seats',
            widget.viewModel.selectedSeats.join(', '),
          ),
          const SizedBox(height: 8),
          _buildSummaryRow('Total Amount', '₹${widget.viewModel.totalPrice}'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPickupPointDropdown() {
    final pickupPoints = widget.viewModel.pickupPoints;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pickup Point',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        widget.viewModel.isLoadingAdditionalData
            ? const Center(child: CircularProgressIndicator())
            : pickupPoints.isEmpty
            ? const Text(
                'No pickup points available',
                style: TextStyle(fontSize: 14, color: Colors.red),
              )
            : DropdownButtonFormField<String>(
                value: _selectedPickupPoint,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.orange.shade600),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: pickupPoints.map((point) {
                  return DropdownMenuItem<String>(
                    value: point['id']?.toString(),
                    child: Text(point['name']?.toString() ?? 'Unknown'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPickupPoint = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a pickup point';
                  }
                  return null;
                },
              ),
      ],
    );
  }

  Widget _buildPassengerContainer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Passenger Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${_passengers.length}/${widget.viewModel.selectedSeats.length}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._passengers.asMap().entries.map((entry) {
            final index = entry.key;
            final passenger = entry.value;
            return _buildPassengerForm(index, passenger);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPassengerForm(int index, Map<String, dynamic> passenger) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Passenger ${index + 1}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              if (_passengers.length > 1)
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red.shade400),
                  onPressed: () => _removePassenger(index),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: passenger['name'],
            decoration: InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter full name';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: passenger['age'],
            decoration: InputDecoration(
              labelText: 'Age',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter age';
              }
              final age = int.tryParse(value);
              if (age == null || age < 1 || age > 120) {
                return 'Enter a valid age (1-120)';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: passenger['contact'],
            decoration: InputDecoration(
              labelText: 'Contact Number',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter contact number';
              }
              if (value.length != 10) {
                return 'Enter a valid 10-digit contact number';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: passenger['gender'],
            decoration: InputDecoration(
              labelText: 'Gender',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: ['Male', 'Female', 'Other']
                .map(
                  (gender) =>
                      DropdownMenuItem(value: gender, child: Text(gender)),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                passenger['gender'] = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select gender';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddPassengerButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: _passengers.length < widget.viewModel.selectedSeats.length
            ? () =>
                  _addPassenger() // Fixed to ensure button works
            : null,
        icon: const Icon(Icons.add_circle_outline, color: Colors.orange),
        label: const Text(
          'Add Passenger',
          style: TextStyle(color: Colors.orange, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.viewModel.selectedSeats.length} Seat${widget.viewModel.selectedSeats.length != 1 ? 's' : ''} selected',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  Text(
                    '₹${widget.viewModel.totalPrice}',
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
              onPressed:
                  widget.viewModel.isLoadingAdditionalData ||
                      _selectedPickupPoint == null ||
                      _isConfirming ||
                      _passengers.isEmpty
                  ? null
                  : () async {
                      if (_formKey.currentState!.validate()) {
                        // ✅ NEW CHECK: Ensure passengers count matches selected seats
                        if (_passengers.length <
                            widget.viewModel.selectedSeats.length) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Please add details for all ${widget.viewModel.selectedSeats.length} passengers',
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.orange.shade600,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                          return; // ⛔ Stop further execution
                        }

                        setState(() => _isConfirming = true);
                        HapticFeedback.lightImpact();

                        try {
                          final bookingsViewModel =
                              Provider.of<BookingsViewModel>(
                                context,
                                listen: false,
                              );

                          final primaryPassenger = _passengers[0];
                          final bookingData = await widget.viewModel
                              .confirmBooking(
                                context,
                                bookingsViewModel,
                                pickupPoint: _selectedPickupPoint!,
                                passengerName: primaryPassenger['name'].text
                                    .trim(),
                                passengerContact: primaryPassenger['contact']
                                    .text
                                    .trim(),
                              );

                          if (bookingData != null) {
                            bookingData['passengers'] = _passengers.map((p) {
                              return {
                                'name': p['name'].text.trim(),
                                'age': int.parse(p['age'].text.trim()),
                                'contact': p['contact'].text.trim(),
                                'gender': p['gender'],
                              };
                            }).toList();

                            final paymentResult = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PaymentScreen(
                                  bookingData: bookingData,
                                  busId:
                                      widget.bus['id']?.toString() ??
                                      'unknown_bus_id',
                                  totalAmount: widget.viewModel.totalPrice
                                      .toDouble(),
                                  selectedSeats: List<String>.from(
                                    widget.viewModel.selectedSeats,
                                  ),
                                  passengerName: primaryPassenger['name'].text
                                      .trim(),
                                  passengerContact: primaryPassenger['contact']
                                      .text
                                      .trim(),
                                  busDetails: {
                                    'busName':
                                        widget.bus['busName'] ??
                                        widget.bus['name'] ??
                                        'Unknown Bus',
                                    'departureTime':
                                        widget.bus['departureTime'] ?? '06:00',
                                    'arrivalTime':
                                        widget.bus['arrivalTime'] ?? '13:30',
                                    'rating':
                                        widget.bus['rating']?.toString() ??
                                        '4.0',
                                    'busType':
                                        widget.bus['busType'] ??
                                        (widget.bus['hasAC'] == true
                                            ? 'A/C Seater'
                                            : 'Non A/C Seater'),
                                    'from':
                                        widget.sourceCity ??
                                        widget.bus['from'] ??
                                        'Unknown',
                                    'to':
                                        widget.destinationCity ??
                                        widget.bus['to'] ??
                                        'Unknown',
                                    'duration':
                                        widget.bus['duration'] ?? '7h 30m',
                                    'price': widget.viewModel.totalPrice,
                                  },
                                  viewModel: widget.viewModel,
                                ),
                              ),
                            );

                            // 🔹 Handle payment result as pehle likha tha...
                          }
                        } catch (e) {
                          print('❌ Error in confirmBooking: $e');
                        } finally {
                          setState(() => _isConfirming = false);
                        }
                      }
                    },

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isConfirming
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Confirm',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
