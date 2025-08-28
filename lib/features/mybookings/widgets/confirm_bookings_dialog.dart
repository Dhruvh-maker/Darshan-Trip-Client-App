import 'package:darshan_trip/features/home/viewmodel/bus_detail_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../viewmodel/bookings_viewmodel.dart';

Widget buildConfirmBookingDialog(
  BuildContext context,
  BusDetailViewModel viewModel,
  BookingsViewModel bookingsViewModel, {
  required DateTime travelDate,
  required String pickupPoint,
  required VoidCallback onConfirm, // Add callback for confirm action
}) {
  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.orange.shade500, Colors.orange.shade300],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(25),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Confirm Booking',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Seats Info Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.orange.shade700.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            'Selected Seats: ${viewModel.selectedSeats.join(', ')}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Total Amount Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.orange.shade700.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            'Total Amount: ₹${viewModel.totalPrice}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'Ready to proceed with booking?',
          style: TextStyle(fontSize: 16, color: Colors.white70),
        ),
        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
                textStyle: const TextStyle(fontSize: 16),
              ),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 12),

            // Confirm Button with custom callback
            Consumer<BookingsViewModel>(
              builder: (context, bookingsVM, child) {
                return ElevatedButton(
                  onPressed: bookingsVM.isLoading ? null : onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.orange.shade900,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 6,
                    shadowColor: Colors.orange.shade400.withOpacity(0.6),
                  ),
                  child: bookingsVM.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.orange,
                            ),
                          ),
                        )
                      : const Text(
                          'Confirm Booking',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                );
              },
            ),
          ],
        ),
      ],
    ),
  );
}
