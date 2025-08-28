import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:darshan_trip/features/home/viewmodel/bus_detail_viewmodel.dart';
import 'package:darshan_trip/features/mybookings/viewmodel/bookings_viewmodel.dart';
import 'package:darshan_trip/features/profile/viewmodel/wallet_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  final String busId;
  final double totalAmount;
  final List<String> selectedSeats;
  final String passengerName;
  final String passengerContact;
  final Map<String, dynamic>? busDetails;
  final BusDetailViewModel viewModel;

  const PaymentScreen({
    super.key,
    required this.bookingData,
    required this.busId,
    required this.totalAmount,
    required this.selectedSeats,
    required this.passengerName,
    required this.passengerContact,
    this.busDetails,
    required this.viewModel,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  String? selectedPaymentMethod;
  bool isProcessingPayment = false;
  bool _isNavigating = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Promo code related variables
  final TextEditingController _promoCodeController = TextEditingController();
  Map<String, dynamic>? _appliedPromoCode;
  bool _isApplyingPromo = false;
  double _discountAmount = 0.0;
  double _finalAmount = 0.0;

  final List<PaymentOption> paymentOptions = [
    PaymentOption(
      id: 'upi',
      title: 'UPI',
      subtitle: 'Pay with Google Pay, PhonePe, etc.',
      icon: Icons.bubble_chart,
      color: Colors.deepPurple,
      isRecommended: true,
    ),
    PaymentOption(
      id: 'card',
      title: 'Credit/Debit Card',
      subtitle: 'Visa, Mastercard, RuPay',
      icon: Icons.credit_card,
      color: Colors.blue.shade700,
    ),
    PaymentOption(
      id: 'netbanking',
      title: 'Net Banking',
      subtitle: 'All major banks supported',
      icon: Icons.account_balance,
      color: Colors.green.shade600,
    ),
    PaymentOption(
      id: 'wallet',
      title: 'Wallet',
      subtitle: 'Pay using your wallet balance',
      icon: Icons.account_balance_wallet,
      color: Colors.orange.shade800,
    ),
  ];

  @override
  void initState() {
    super.initState();
    print('🔍 PaymentScreen initialized with:');
    print('   BusId: ${widget.busId}');
    print('   Total Amount: ${widget.totalAmount}');
    print('   Selected Seats: ${widget.selectedSeats}');
    print('   Passenger Name: ${widget.passengerName}');
    print('   Passenger Contact: ${widget.passengerContact}');
    print('   Bus Details: ${widget.busDetails}');
    print('   Booking Data: ${widget.bookingData}');

    // Initialize final amount with original total
    _finalAmount =
        widget.bookingData['totalAmount']?.toDouble() ?? widget.totalAmount;

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _promoCodeController.dispose();
    super.dispose();
  }

  String _getEmailForPayment() {
    return '${widget.passengerContact}@temp.com';
  }

  // Check if user is new (first time booking)
  Future<bool> _isNewUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return true;

      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      return bookingsSnapshot.docs.isEmpty;
    } catch (e) {
      print('Error checking if new user: $e');
      return false;
    }
  }

  // Validate promo code conditions
  Future<bool> _validatePromoConditions(Map<String, dynamic> promo) async {
    final conditions = promo['conditions'] as List<dynamic>? ?? [];

    for (final condition in conditions) {
      final conditionMap = condition as Map<String, dynamic>;
      final type = conditionMap['type'] as String;

      switch (type) {
        case 'newUser':
          final isNew = await _isNewUser();
          if (!isNew) return false;
          break;
        case 'firstBooking':
          final isFirstBooking = await _isNewUser();
          if (!isFirstBooking) return false;
          break;
        case 'minAmount':
          final minAmount = (conditionMap['value'] ?? 0).toDouble();
          final currentAmount =
              widget.bookingData['totalAmount']?.toDouble() ??
              widget.totalAmount;
          if (currentAmount < minAmount) return false;
          break;
        // Add more condition types as needed
      }
    }

    return true;
  }

  // Apply promo code
  Future<void> _applyPromoCode() async {
    if (_promoCodeController.text.trim().isEmpty) {
      _showSnackBar('Please enter a promo code', Colors.red);
      return;
    }

    setState(() {
      _isApplyingPromo = true;
    });

    try {
      final promoCode = _promoCodeController.text.trim().toUpperCase();

      // Fetch promo code from Firestore
      final promoSnapshot = await FirebaseFirestore.instance
          .collection('promotions')
          .where('code', isEqualTo: promoCode)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (promoSnapshot.docs.isEmpty) {
        _showSnackBar('Invalid promo code', Colors.red);
        return;
      }

      final promoDoc = promoSnapshot.docs.first;
      final promoData = promoDoc.data();

      // Check if promo code is within valid date range
      final startDate = DateTime.parse(promoData['startDate']);
      final endDate = DateTime.parse(promoData['endDate']);
      final now = DateTime.now();

      if (now.isBefore(startDate) || now.isAfter(endDate)) {
        _showSnackBar('Promo code has expired', Colors.red);
        return;
      }

      // Validate conditions
      final isValid = await _validatePromoConditions(promoData);
      if (!isValid) {
        _showSnackBar('You are not eligible for this promo code', Colors.red);
        return;
      }

      // Calculate discount
      final originalAmount =
          widget.bookingData['totalAmount']?.toDouble() ?? widget.totalAmount;
      final discountType = promoData['discountType'] as String;
      final discountValue = (promoData['discountValue'] ?? 0).toDouble();

      double discount = 0.0;
      if (discountType == 'fixed') {
        discount = discountValue;
      } else if (discountType == 'percentage') {
        discount = (originalAmount * discountValue) / 100;
      }

      // Ensure discount doesn't exceed the original amount
      discount = discount > originalAmount ? originalAmount : discount;

      setState(() {
        _appliedPromoCode = promoData;
        _discountAmount = discount;
        _finalAmount = originalAmount - discount;
      });

      _showSnackBar('Promo code applied successfully!', Colors.green);
    } catch (e) {
      print('Error applying promo code: $e');
      _showSnackBar('Error applying promo code', Colors.red);
    } finally {
      setState(() {
        _isApplyingPromo = false;
      });
    }
  }

  // Remove applied promo code
  void _removePromoCode() {
    setState(() {
      _appliedPromoCode = null;
      _discountAmount = 0.0;
      _finalAmount =
          widget.bookingData['totalAmount']?.toDouble() ?? widget.totalAmount;
      _promoCodeController.clear();
    });
    _showSnackBar('Promo code removed', Colors.orange);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final walletVM = context.watch<WalletViewModel>();
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBookingSummary(),
                const SizedBox(height: 20),
                _buildBusDetails(),
                const SizedBox(height: 20),
                _buildPriceBreakdown(),
                const SizedBox(height: 20),
                _buildPromoCodeSection(),
                const SizedBox(height: 20),
                _buildPaymentOptions(walletVM),
                const SizedBox(height: 24),
                _buildSecurityInfo(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomPaymentBar(context, walletVM),
    );
  }

  // New promo code section widget
  Widget _buildPromoCodeSection() {
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
          Row(
            children: [
              Icon(Icons.local_offer, color: Colors.orange.shade600, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Apply Promo Code',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_appliedPromoCode == null) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoCodeController,
                    decoration: InputDecoration(
                      hintText: 'Enter promo code',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.orange.shade600),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isApplyingPromo ? null : _applyPromoCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isApplyingPromo
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'APPLY',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ] else ...[
            // Applied promo code display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Promo Applied: ${_appliedPromoCode!['code']}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        if (_appliedPromoCode!['name']?.isNotEmpty == true)
                          Text(
                            _appliedPromoCode!['name'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade600,
                            ),
                          ),
                        Text(
                          'You saved ₹${_discountAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _removePromoCode,
                    icon: Icon(
                      Icons.close,
                      color: Colors.green.shade600,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.orange.shade600,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: _isNavigating || isProcessingPayment
            ? null
            : () {
                // Return with cancelled status
                Navigator.pop(context, {'status': 'cancelled'});
              },
      ),
      title: const Text(
        'Payment',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline, color: Colors.white),
          onPressed: _isNavigating || isProcessingPayment
              ? null
              : () => _showHelpDialog(context),
        ),
      ],
    );
  }

  Widget _buildBookingSummary() {
    final seats = widget.bookingData['selectedSeats'] ?? widget.selectedSeats;
    final passengerName =
        widget.bookingData['passengerName'] ?? widget.passengerName;
    final passengerContact =
        widget.bookingData['passengerContact'] ?? widget.passengerContact;
    final totalAmount =
        widget.bookingData['totalAmount']?.toDouble() ?? widget.totalAmount;
    final passengers = widget.bookingData['passengers'] as List<dynamic>? ?? [];

    // Get travel date from booking data - this is the key fix
    String travelDateStr = 'N/A';
    if (widget.bookingData['travelDate'] != null) {
      try {
        final dateValue = widget.bookingData['travelDate'];
        DateTime date;

        if (dateValue is DateTime) {
          date = dateValue;
        } else if (dateValue is String) {
          date = DateTime.parse(dateValue);
        } else {
          date = DateTime.now();
        }

        travelDateStr = DateFormat('dd MMM yyyy, EEEE').format(date);
      } catch (e) {
        print('Error formatting travel date: $e');
        travelDateStr = widget.bookingData['travelDate'].toString();
      }
    } else {
      // Fallback to current date if no travel date is provided
      travelDateStr = DateFormat('dd MMM yyyy, EEEE').format(DateTime.now());
    }

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Booking Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            'Selected Seats',
            seats is List ? seats.join(', ') : seats.toString(),
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Number of Passengers',
            passengers.length.toString(),
          ),
          const SizedBox(height: 16),

          // Travel Date Display - Enhanced styling
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
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
                      'Travel Date',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      travelDateStr,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Passenger Details Section (existing code remains the same)
          if (passengers.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.group, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Passenger Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...passengers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final passenger = entry.value as Map<String, dynamic>;
                    final isPrimary = index == 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isPrimary ? Colors.orange.shade50 : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isPrimary
                              ? Colors.orange.shade200
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Passenger ${index + 1}${isPrimary ? ' (Primary)' : ''}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isPrimary
                                      ? Colors.orange.shade700
                                      : Colors.black87,
                                ),
                              ),
                              if (isPrimary)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade600,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'PRIMARY',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Name',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      passenger['name']?.toString() ??
                                          'Unknown',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Age',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      passenger['age']?.toString() ?? 'N/A',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Gender',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      passenger['gender']?.toString() ?? 'N/A',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.phone,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                passenger['contact']?.toString() ?? 'N/A',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ] else ...[
            // Fallback for single passenger (backward compatibility)
            _buildSummaryRow('Primary Contact', passengerName),
            const SizedBox(height: 8),
            _buildSummaryRow('Primary Contact Number', passengerContact),
            const SizedBox(height: 8),
          ],

          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                '₹$totalAmount',
                style: TextStyle(
                  fontSize: 20,
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

  Future<double> _getGSTPercentage() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('gst')
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['GST'] ?? 3).toDouble();
      }
      return 3.0; // Default fallback
    } catch (e) {
      print('Error fetching GST: $e');
      return 3.0; // Default fallback
    }
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

  Widget _buildBusDetails() {
    final pickupPointId = widget.bookingData['pickupPoint'];

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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.trip_origin, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Departure',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.busDetails?['departureTime']?.toString() ??
                          '06:00',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.directions_bus,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Destination',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.location_on, color: Colors.red, size: 16),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.busDetails?['arrivalTime']?.toString() ?? '13:30',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Bus Name: ${widget.busDetails?['busName'] ?? 'Unknown Bus'}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber.shade600, size: 18),
              const SizedBox(width: 4),
              Text(
                widget.busDetails?['rating']?.toString() ?? '3.8',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '• ${widget.busDetails?['busType']?.toString() ?? 'Non A/C Seater'}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Route: ${widget.busDetails?['from'] ?? 'Unknown'} → ${widget.busDetails?['to'] ?? 'Unknown'}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Duration: ${widget.busDetails?['duration'] ?? '7h 30m'}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
          if (pickupPointId != null) ...[
            const SizedBox(height: 8),
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('pickupPoints')
                  .doc(pickupPointId.toString())
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox();
                }
                if (snapshot.hasData && snapshot.data!.exists) {
                  final pickupPoint =
                      snapshot.data!.data() as Map<String, dynamic>;
                  return Text(
                    'Pickup: ${pickupPoint['name'] ?? 'Unknown'}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  );
                }
                return const SizedBox();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown() {
    final originalAmount =
        widget.bookingData['totalAmount']?.toDouble() ?? widget.totalAmount;

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
            'Price Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<double>(
            future: _getGSTPercentage(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Column(
                  children: [
                    _buildPriceRow(
                      'Base Fare (${widget.selectedSeats.length} seats)',
                      'Loading...',
                    ),
                    const SizedBox(height: 8),
                    _buildPriceRow('Taxes & Fees (GST)', 'Loading...'),
                    if (_appliedPromoCode != null) ...[
                      const SizedBox(height: 8),
                      _buildPriceRow(
                        'Discount (${_appliedPromoCode!['code']})',
                        'Loading...',
                        isDiscount: true,
                      ),
                    ],
                    const Divider(height: 20),
                    _buildPriceRow(
                      'Final Amount',
                      '₹${_finalAmount.toStringAsFixed(2)}',
                      isTotal: true,
                    ),
                  ],
                );
              }

              final gstPercentage = snapshot.data ?? 3.0;

              // Calculate base price from original amount
              final basePrice = originalAmount / (1 + (gstPercentage / 100));
              final gstAmount = originalAmount - basePrice;

              return Column(
                children: [
                  _buildPriceRow(
                    'Base Fare (${widget.selectedSeats.length} seats)',
                    '₹${basePrice.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 8),
                  _buildPriceRow(
                    'Taxes & Fees (GST ${gstPercentage.toStringAsFixed(0)}%)',
                    '₹${gstAmount.toStringAsFixed(2)}',
                  ),
                  if (_appliedPromoCode != null) ...[
                    const SizedBox(height: 8),
                    _buildPriceRow(
                      'Discount (${_appliedPromoCode!['code']})',
                      '-₹${_discountAmount.toStringAsFixed(2)}',
                      isDiscount: true,
                    ),
                  ],
                  const Divider(height: 20),
                  _buildPriceRow(
                    'Final Amount',
                    '₹${_finalAmount.toStringAsFixed(2)}',
                    isTotal: true,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String amount, {
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            color: isTotal ? Colors.black87 : Colors.grey.shade600,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: isTotal
                ? Colors.orange.shade600
                : isDiscount
                ? Colors.green.shade600
                : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOptions(WalletViewModel walletVM) {
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
            'Choose Payment Method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...paymentOptions.map(
            (option) => _buildPaymentOption(option, walletVM),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(PaymentOption option, WalletViewModel walletVM) {
    final isSelected = selectedPaymentMethod == option.id;
    final isWalletOption = option.id == 'wallet';
    final isWalletSufficient =
        isWalletOption && walletVM.walletBalance >= _finalAmount;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: (isWalletOption && !isWalletSufficient) || _isNavigating
            ? null
            : () => setState(() => selectedPaymentMethod = option.id),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.orange.shade600 : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            color: isSelected
                ? Colors.orange.shade50
                : isWalletOption && !isWalletSufficient
                ? Colors.grey.shade100
                : Colors.white,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: option.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(option.icon, color: option.color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          option.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isWalletOption && !isWalletSufficient
                                ? Colors.grey.shade600
                                : Colors.black87,
                          ),
                        ),
                        if (option.isRecommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade600,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'RECOMMENDED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isWalletOption
                          ? 'Balance: ₹${walletVM.walletBalance.toStringAsFixed(2)}'
                          : option.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isWalletOption && !isWalletSufficient
                            ? Colors.red.shade600
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Colors.orange.shade600
                        : Colors.grey.shade400,
                    width: 2,
                  ),
                  color: isSelected
                      ? Colors.orange.shade600
                      : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.security, color: Colors.blue.shade600, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '100% Secure Payment',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your payment information is encrypted and secure',
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPaymentBar(
    BuildContext context,
    WalletViewModel walletVM,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _appliedPromoCode != null ? 'Final Amount' : 'Total Amount',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  Text(
                    '₹${_finalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade600,
                    ),
                  ),
                  if (_appliedPromoCode != null)
                    Text(
                      'You saved ₹${_discountAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed:
                    selectedPaymentMethod != null &&
                        !isProcessingPayment &&
                        !_isNavigating
                    ? () => _processPayment(context, walletVM)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: isProcessingPayment || _isNavigating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Pay Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _processPayment(BuildContext context, WalletViewModel walletVM) async {
    if (selectedPaymentMethod == null || _isNavigating) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isProcessingPayment = true;
      _isNavigating = false;
    });

    try {
      final seats = widget.bookingData['selectedSeats'] ?? widget.selectedSeats;

      if (_finalAmount <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid payment amount'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      bool hasNoSeats = false;
      if (seats is List) {
        hasNoSeats = seats.isEmpty;
      } else if (seats == null) {
        hasNoSeats = true;
      }

      if (hasNoSeats) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No seats selected'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final passengerName =
          widget.bookingData['passengerName'] ?? widget.passengerName;
      final passengerContact =
          widget.bookingData['passengerContact'] ?? widget.passengerContact;

      // Update booking data with final amount and promo details
      Map<String, dynamic> updatedBookingData = Map.from(widget.bookingData);
      updatedBookingData['finalAmount'] = _finalAmount;
      updatedBookingData['originalAmount'] =
          widget.bookingData['totalAmount']?.toDouble() ?? widget.totalAmount;

      if (_appliedPromoCode != null) {
        updatedBookingData['promoCode'] = _appliedPromoCode!['code'];
        updatedBookingData['discountAmount'] = _discountAmount;
        updatedBookingData['promoDetails'] = _appliedPromoCode;
      }

      widget.viewModel.setTotalAmount(_finalAmount);

      if (selectedPaymentMethod == 'wallet') {
        final success = await walletVM.processWalletPayment(
          amount: _finalAmount,
          bookingId: widget.busId,
          description:
              'Bus ticket payment for ${widget.busDetails?['from']} to ${widget.busDetails?['to']}',
        );

        if (success) {
          final bookingsViewModel = Provider.of<BookingsViewModel>(
            context,
            listen: false,
          );
          final bookingId = await widget.viewModel.saveBooking(
            context,
            bookingsViewModel,
            updatedBookingData,
            paymentMethod: 'Wallet',
          );

          if (bookingId != null && mounted) {
            // IMPORTANT: Reset loading states BEFORE showing dialog
            setState(() {
              isProcessingPayment = false;
              _isNavigating = false;
            });

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Payment and booking successful! Booking ID: $bookingId",
                ),
                backgroundColor: Colors.green,
              ),
            );

            // Show success dialog
            _showPaymentSuccessDialog(context, bookingId);
            return; // IMPORTANT: Return here to prevent further execution
          } else {
            throw Exception("Booking failed after wallet payment");
          }
        } else {
          throw Exception("Insufficient wallet balance or payment failed");
        }
      } else {
        // For other payment methods
        await widget.viewModel.initiatePayment(
          context,
          passengerName,
          passengerContact,
          _getEmailForPayment(),
          updatedBookingData,
        );

        if (mounted) {
          setState(() {
            isProcessingPayment = false;
            _isNavigating = true;
          });
        }
      }
    } catch (e) {
      print('❌ Payment error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Only reset loading state if we haven't already done so
      if (mounted && isProcessingPayment) {
        setState(() {
          isProcessingPayment = false;
        });
      }
    }
  }

  void _showPaymentSuccessDialog(BuildContext context, String bookingId) {
    if (!mounted) return;

    // No need to reset states here as they're already reset in the calling method

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
              const SizedBox(height: 8),
              Text(
                'Booking ID: $bookingId',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              if (_appliedPromoCode != null) ...[
                const SizedBox(height: 8),
                Text(
                  'You saved ₹${_discountAmount.toStringAsFixed(2)} with ${_appliedPromoCode!['code']}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    // Navigate to home screen directly
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/home',
                      (route) => false, // Remove all previous routes
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Go to Home',
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
      ),
    );
  }

  void _navigateToHome(BuildContext context) async {
    if (_isNavigating) return;

    setState(() {
      _isNavigating = true;
    });

    if (mounted) {
      print('✅ Navigating to home');
      Navigator.of(context).popUntil((route) => route.isFirst);
    }

    if (mounted) {
      setState(() {
        _isNavigating = false;
      });
    }
  }

  void _showHelpDialog(BuildContext context) {
    if (_isNavigating) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Need Help?'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• All payments are 100% secure and encrypted'),
            SizedBox(height: 8),
            Text('• You will receive SMS confirmation'),
            SizedBox(height: 8),
            Text('• Refund will be processed within 3-5 business days'),
            SizedBox(height: 8),
            Text('• For support, call: 1800-123-456'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: TextStyle(color: Colors.orange.shade600),
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentOption {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isRecommended;

  PaymentOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.isRecommended = false,
  });
}
