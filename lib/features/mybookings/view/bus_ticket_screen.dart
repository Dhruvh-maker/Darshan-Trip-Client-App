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
        actions: [
          TextButton(
            onPressed: () => _shareTicket(context, booking, busData),
            child: const Text('Share', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => _downloadTicketAsPDF(context, booking, busData),
            child: const Text(
              'Download',
              style: TextStyle(color: Colors.white),
            ),
          ),
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
                              _buildTicketDetailRow(
                                'Booked On',
                                DateFormat(
                                  'dd/MM/yyyy HH:mm',
                                ).format(bookingTime),
                              ),
                              if (booking['lastModifiedAt'] != null) ...[
                                const SizedBox(height: 12),
                                _buildTicketDetailRow(
                                  'Last Modified',
                                  DateFormat('dd/MM/yyyy HH:mm').format(
                                    (booking['lastModifiedAt'] as Timestamp)
                                        .toDate(),
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
                        if (canCancelOrModify) ...[
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () =>
                                      _showModifyDialog(context, booking),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Modify Booking'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () =>
                                      _showCancelDialog(context, booking),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Cancel Booking'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
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
    final TextEditingController nameController = TextEditingController(
      text: booking['passengerName']?.toString() ?? '',
    );
    final TextEditingController contactController = TextEditingController(
      text: booking['passengerContact']?.toString() ?? '',
    );
    final TextEditingController pickupController = TextEditingController(
      text: booking['pickupPoint']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modify Booking'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Passenger Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contactController,
                decoration: const InputDecoration(
                  labelText: 'Contact Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                maxLength: 10,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pickupController,
                decoration: const InputDecoration(
                  labelText: 'Pickup Point',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: const Text(
                  'Note: Date and seat modifications have additional fees and restrictions. Contact support for major changes.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final bookingsViewModel = context.read<BookingsViewModel>();
              final success = await bookingsViewModel.modifyBooking(
                bookingId: booking['id']?.toString() ?? '',
                newPassengerName: nameController.text.trim(),
                newPassengerContact: contactController.text.trim(),
                newPickupPoint: pickupController.text.trim(),
              );

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Booking modified successfully'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      bookingsViewModel.error ?? 'Failed to modify booking',
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text(
              'Save Changes',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, Map<String, dynamic> booking) {
    final bookingsViewModel = context.read<BookingsViewModel>();
    final refundAmount = bookingsViewModel.calculateRefundAmount(booking);
    final refundPercentage = bookingsViewModel.getRefundPercentage(booking);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to cancel this booking?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade50, Colors.green.shade100],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Refund Information',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Refund Amount:'),
                      Text(
                        'Rs ${refundAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Refund Percentage:'),
                      Text(
                        refundPercentage,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Refunds will be processed within 5-7 business days to your original payment method.',
                      style: TextStyle(fontSize: 11),
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
            child: const Text('Keep Booking'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await bookingsViewModel.cancelBooking(
                booking['id']?.toString() ?? '',
              );

              if (success) {
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
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      bookingsViewModel.error ?? 'Failed to cancel booking',
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
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}
