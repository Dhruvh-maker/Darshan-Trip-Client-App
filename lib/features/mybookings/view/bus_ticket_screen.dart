import 'package:darshan_trip/core/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import '../viewmodel/bookings_viewmodel.dart';

class BusTicketScreen extends StatelessWidget {
  final Map<String, dynamic> booking;

  const BusTicketScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final busData = booking['busData'] ?? {};
    final bookingDateStr = booking['bookingDate']?.toString() ?? '';
    DateTime bookingDate;
    try {
      bookingDate = DateFormat('yyyy-MM-dd').parse(bookingDateStr);
    } catch (e) {
      bookingDate = DateTime.now();
    }

    final bookingTime = parseFirestoreDate(booking['createdAt']);

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

    final bookingsViewModel = context.read<BookingsViewModel>();
    final canCancelOrModify = bookingsViewModel.canCancelOrModifyBooking(
      booking,
    );
    final refundAmount = bookingsViewModel.calculateRefundAmount(booking);
    final refundPercentage = bookingsViewModel.getRefundPercentage(booking);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Bus Ticket',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF5A623),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (status == 'confirmed') ...[
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: () => _shareTicket(context, booking, busData),
              tooltip: 'Share Ticket',
            ),
            IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              onPressed: () => _downloadTicketAsPDF(context, booking, busData),
              tooltip: 'Download Ticket',
            ),
            if (canCancelOrModify)
              PopupMenuButton<String>(
                onSelected: (String value) {
                  switch (value) {
                    case 'modify':
                      _showModifyDialog(context, booking);
                      break;
                    case 'cancel':
                      _showCancelDialog(context, booking);
                      break;
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
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
                  ];
                },
                icon: const Icon(Icons.more_vert, color: Colors.white),
              ),
          ],
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.orange.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFF5A623),
                          Colors.orange.shade600,
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'BUS TICKET',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sourceCity.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'FROM',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: const Text(
                                '→',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  destinationCity.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'TO',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Details Section
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'BUS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                busData['busName']?.toString() ??
                                    busData['name']?.toString() ??
                                    'Unknown Bus',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                'TRAVEL DATE',
                                DateFormat('dd MMM yyyy').format(bookingDate),
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoCard(
                                'SEAT${seats.length > 1 ? 'S' : ''}',
                                seats.join(', '),
                                Colors.purple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Passenger Details Section
                        if (booking['passengers'] != null &&
                            (booking['passengers'] as List).isNotEmpty) ...[
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
                                    Icon(
                                      Icons.group,
                                      color: Colors.blue.shade700,
                                      size: 20,
                                    ),
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
                                ...(booking['passengers'] as List<dynamic>)
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                      final index = entry.key;
                                      final passenger =
                                          entry.value as Map<String, dynamic>;
                                      final isPrimary = index == 0;
                                      return Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isPrimary
                                              ? Colors.orange.shade50
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: isPrimary
                                                ? Colors.orange.shade200
                                                : Colors.grey.shade300,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
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
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .orange
                                                          .shade600,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                    child: const Text(
                                                      'PRIMARY',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
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
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Name',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors
                                                              .grey
                                                              .shade600,
                                                        ),
                                                      ),
                                                      Text(
                                                        passenger['name']
                                                                ?.toString() ??
                                                            'Unknown',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Age',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors
                                                              .grey
                                                              .shade600,
                                                        ),
                                                      ),
                                                      Text(
                                                        passenger['age']
                                                                ?.toString() ??
                                                            'N/A',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Gender',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors
                                                              .grey
                                                              .shade600,
                                                        ),
                                                      ),
                                                      Text(
                                                        passenger['gender']
                                                                ?.toString() ??
                                                            'N/A',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
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
                                                  passenger['contact']
                                                          ?.toString() ??
                                                      'N/A',
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
                                    })
                                    .toList(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        // Fallback for single passenger
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                'PASSENGER(S)',
                                passengerNames, // Use comma-separated names
                                Colors.indigo,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoCard(
                                'CONTACT',
                                booking['passengerContact']?.toString() ??
                                    'N/A',
                                Colors.teal,
                              ),
                            ),
                          ],
                        ),
                        if (booking['pickupPoint'] != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PICKUP POINT',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  booking['sourceCity'].toString(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.shade100,
                                Colors.green.shade50,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'TOTAL FARE',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Rs ${booking['totalFare']?.toString() ?? '0'}',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              if (status == 'confirmed' && canCancelOrModify)
                                Text(
                                  'Refund on cancellation: Rs ${refundAmount.toStringAsFixed(0)} ($refundPercentage)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _buildTicketDetailRow(
                                'Booking ID',
                                booking['id']?.toString().substring(0, 12) ??
                                    'N/A',
                              ),
                              const SizedBox(height: 12),

                              // ✅ Booked On
                              _buildTicketDetailRow(
                                'Booked On',
                                formatFirestoreDate(booking['createdAt']),
                              ),

                              // ✅ Last Modified (agar hai to hi dikhana)
                              if (booking['lastModifiedAt'] != null) ...[
                                const SizedBox(height: 12),
                                _buildTicketDetailRow(
                                  'Last Modified',
                                  formatFirestoreDate(
                                    booking['lastModifiedAt'],
                                  ),
                                ),
                              ],

                              if ((booking['modificationCount'] ?? 0) > 0) ...[
                                const SizedBox(height: 12),
                                _buildTicketDetailRow(
                                  'Modifications',
                                  '${booking['modificationCount']} time(s)',
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
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
                              Text(
                                'Important Instructions',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Download your ticket before travel\n'
                                'Keep a digital or printed copy handy\n'
                                'Arrive at pickup point 15 minutes early\n'
                                'Carry a valid photo ID for verification',
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTicketDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Future<void> _shareTicket(
    BuildContext context,
    Map<String, dynamic> booking,
    Map<String, dynamic> busData,
  ) async {
    final bookingId = booking['id']?.toString() ?? 'N/A';
    final busName =
        busData['busName']?.toString() ??
        busData['name']?.toString() ??
        'Unknown Bus';
    final route =
        '${booking['sourceCity']?.toString() ?? 'Unknown'} to ${booking['destinationCity']?.toString() ?? 'Unknown'}';
    final seats = (booking['seats'] as List<dynamic>?)?.join(', ') ?? 'N/A';
    final travelDate = DateFormat('dd MMM yyyy').format(
      DateTime.parse(
        booking['bookingDate']?.toString() ?? DateTime.now().toString(),
      ),
    );
    final passengerNames = booking['passengerName']?.toString() ?? 'Unknown';

    final shareText =
        '''
Bus Ticket Details

Bus: $busName
Route: $route
Travel Date: $travelDate
Seats: $seats
Passenger(s): $passengerNames
Fare: Rs ${booking['totalFare']?.toString() ?? '0'}
Booking ID: $bookingId

Status: ${booking['status']?.toString().toUpperCase() ?? 'UNKNOWN'}
    ''';

    await Share.share(shareText, subject: 'Bus Ticket - $bookingId');
  }

  pw.Widget _buildPassengersPdfInfo(List<dynamic> passengers) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'PASSENGER DETAILS',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
          pw.SizedBox(height: 12),
          ...passengers.asMap().entries.map((entry) {
            final index = entry.key;
            final passenger = entry.value as Map<String, dynamic>;
            final isPrimary = index == 0;

            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: isPrimary ? PdfColors.grey200 : PdfColors.white,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(
                  color: isPrimary ? PdfColors.grey400 : PdfColors.grey300,
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Passenger ${index + 1}${isPrimary ? ' (Primary)' : ''}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: isPrimary ? PdfColors.black : PdfColors.black,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        passenger['name']?.toString() ?? 'Unknown',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                      pw.Text(
                        '${passenger['age']} yrs, ${passenger['gender']}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Text(
                    'Contact: ${passenger['contact']?.toString() ?? 'N/A'}',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Future<void> _downloadTicketAsPDF(
    BuildContext context,
    Map<String, dynamic> booking,
    Map<String, dynamic> busData,
  ) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generating PDF...'),
            ],
          ),
        ),
      );

      final pdf = pw.Document();

      // Parse dates
      final bookingDate = DateTime.parse(
        booking['bookingDate']?.toString() ?? DateTime.now().toString(),
      );
      final bookingTime = booking['createdAt'] is Timestamp
          ? (booking['createdAt'] as Timestamp).toDate()
          : DateTime.now();

      final seats =
          (booking['seats'] as List<dynamic>?)
              ?.map((s) => s.toString())
              .toList() ??
          [];

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey800,
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'DARSHAN TRIP BUS TICKET',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                (booking['sourceCity']?.toString() ?? 'Unknown')
                                    .toUpperCase(),
                                style: pw.TextStyle(
                                  fontSize: 20,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.white,
                                ),
                              ),
                              pw.Text(
                                'FROM',
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  color: PdfColors.white,
                                ),
                              ),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                (booking['destinationCity']?.toString() ??
                                        'Unknown')
                                    .toUpperCase(),
                                style: pw.TextStyle(
                                  fontSize: 20,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.white,
                                ),
                              ),
                              pw.Text(
                                'TO',
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  color: PdfColors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 30),

                // Bus Information
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'BUS NAME',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        busData['busName']?.toString() ??
                            busData['name']?.toString() ??
                            'Unknown Bus',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // Travel Details Grid
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _buildPdfInfoBox(
                        'TRAVEL DATE',
                        DateFormat('dd MMM yyyy').format(bookingDate),
                        PdfColors.grey800,
                      ),
                    ),
                    pw.SizedBox(width: 16),
                    pw.Expanded(
                      child: _buildPdfInfoBox(
                        'SEAT NUMBER${seats.length > 1 ? 'S' : ''}',
                        seats.join(', '),
                        PdfColors.grey800,
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 16),

                // Add passengers section in PDF
                if (booking['passengers'] != null &&
                    (booking['passengers'] as List).isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  _buildPassengersPdfInfo(
                    booking['passengers'] as List<dynamic>,
                  ),
                ] else ...[
                  // Fallback for single passenger
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: _buildPdfInfoBox(
                          'PASSENGER',
                          booking['passengerName']?.toString() ?? 'Unknown',
                          PdfColors.grey800,
                        ),
                      ),
                      pw.SizedBox(width: 16),
                      pw.Expanded(
                        child: _buildPdfInfoBox(
                          'CONTACT',
                          booking['passengerContact']?.toString() ?? 'N/A',
                          PdfColors.grey800,
                        ),
                      ),
                    ],
                  ),
                ],

                pw.SizedBox(height: 20),

                // Pickup Point
                if (booking['pickupPoint'] != null)
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'PICKUP POINT',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey800,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          booking['sourceCity'].toString(),
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                pw.SizedBox(height: 20),

                // Total Fare
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'TOTAL FARE',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Rs ${booking['totalFare']?.toString() ?? '0'}',
                        style: pw.TextStyle(
                          fontSize: 36,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // Additional Information
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildPdfDetailRow(
                        'Booking ID:',
                        booking['id']?.toString() ?? 'N/A',
                      ),
                      pw.SizedBox(height: 8),
                      _buildPdfDetailRow(
                        'Booked On:',
                        DateFormat('dd/MM/yyyy HH:mm').format(bookingTime),
                      ),
                      pw.SizedBox(height: 8),
                      _buildPdfDetailRow(
                        'Status:',
                        booking['status']?.toString().toUpperCase() ??
                            'UNKNOWN',
                      ),
                      if (booking['lastModifiedAt'] != null) ...[
                        pw.SizedBox(height: 8),
                        _buildPdfDetailRow(
                          'Last Modified:',
                          DateFormat('dd/MM/yyyy HH:mm').format(
                            (booking['lastModifiedAt'] as Timestamp).toDate(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                pw.SizedBox(height: 30),

                // Footer Instructions
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'IMPORTANT INSTRUCTIONS',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Carry a valid photo ID for verification\n'
                        'Arrive at pickup point 15 minutes before departure\n'
                        'Keep this ticket handy during travel\n'
                        'Contact support for any queries or changes',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),

                // Footer with timestamp
                pw.Center(
                  child: pw.Text(
                    'Generated on: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ),
              ],
            );
          },
        ),
      );

      final directory = await getTemporaryDirectory();
      final fileName =
          'BusTicket_${booking['id']?.toString().substring(0, 8)}_${DateFormat('ddMMyyyy').format(bookingDate)}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Close loading dialog
      Navigator.pop(context);

      // Show success dialog with options
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(children: [Text('PDF Generated')]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Your bus ticket has been generated successfully!',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'File: $fileName',
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await OpenFile.open(file.path);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5A623),
                foregroundColor: Colors.white,
              ),
              child: const Text('Open PDF'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await Share.shareXFiles([XFile(file.path)], text: 'Bus Ticket');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Share'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Close loading dialog if open
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate PDF: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  pw.Widget _buildPdfInfoBox(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfDetailRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 12),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }

  void _showModifyDialog(BuildContext context, Map<String, dynamic> booking) {
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

    /// Gender values ko dropdown ke liye list banaya
    final List<String> genderValues = passengers
        .map((p) => (p['gender']?.toString().toLowerCase() ?? 'male'))
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

              // Passenger forms
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
                          maxLength: 10, // 🔹 only 10 digits allowed
                          decoration: InputDecoration(
                            labelText: "Contact",
                            counterText: "", // 🔹 hides counter
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

                        /// 🔹 Dropdown for Gender
                        DropdownButtonFormField<String>(
                          value: genderValues[i],
                          items: const [
                            DropdownMenuItem(
                              value: "male",
                              child: Text("Male"),
                            ),
                            DropdownMenuItem(
                              value: "female",
                              child: Text("Female"),
                            ),
                          ],
                          onChanged: (value) {
                            genderValues[i] = value ?? "male";
                          },
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

              // Buttons row
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
                              'gender': genderValues[i],
                            };
                          },
                        );

                        final bookingsViewModel = context
                            .read<BookingsViewModel>();
                        final success = await bookingsViewModel.modifyBooking(
                          bookingId: booking['id']?.toString() ?? '',
                          updatedPassengers: updatedPassengers,
                        );

                        if (success && context.mounted) {
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
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                bookingsViewModel.error ??
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

  void _showCancelDialog(BuildContext context, Map<String, dynamic> booking) {
    final bookingsViewModel = context.read<BookingsViewModel>();
    final refundAmount = bookingsViewModel.calculateRefundAmount(booking);
    final refundPercentage = bookingsViewModel.getRefundPercentage(booking);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Pull handle
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              // 🔹 Title
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red.shade600,
                    size: 26,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Cancel Booking',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Text(
                'Are you sure you want to cancel this booking?',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 16),

              // 🔹 Policy + Refund Card
              Expanded(
                child: Consumer<BookingsViewModel>(
                  builder: (context, viewModel, child) {
                    final policy = viewModel.cancelPolicy;
                    if (policy == null) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return ListView(
                      controller: controller,
                      children: [
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.policy,
                                      color: Colors.green.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Cancellation Policy',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  policy['content']?.toString() ??
                                      'No cancellation policy content available',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.green.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.attach_money,
                                        color: Colors.green.shade700,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Refund Details",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Amount: Rs ${refundAmount.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            Text(
                                              'Percentage: $refundPercentage',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // 🔹 Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Keep Booking',
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);

                        final success = await bookingsViewModel.cancelBooking(
                          booking['id']?.toString() ?? '',
                        );

                        await bookingsViewModel.verifyBookingStatus(
                          booking['id']?.toString() ?? '',
                        );

                        if (success && context.mounted) {
                          await bookingsViewModel.fetchUserBookings();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Booking cancelled successfully! Refund: Rs ${refundAmount.toStringAsFixed(0)}',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );

                          Navigator.pop(context); // Back to bookings
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                bookingsViewModel.error ??
                                    'Failed to cancel booking',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.delete_forever, size: 18),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      label: const Text(
                        'Yes, Cancel',
                        style: TextStyle(fontSize: 15, color: Colors.white),
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
}
