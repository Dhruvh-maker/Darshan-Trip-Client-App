import 'package:darshan_trip/features/notifications/model/notification_model.dart';
import 'package:flutter/material.dart';

class NotificationsViewModel extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // Get notifications by type
  List<NotificationModel> getNotificationsByType(String type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  // Initialize notifications (no fetching from Firestore)
  Future<void> initialize() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Simulate a small delay to mimic initialization
      await Future.delayed(const Duration(milliseconds: 500));

      // Notifications will be added via create methods, no mock data
      print('✅ Initialized notifications');
    } catch (e) {
      print('❌ Error initializing notifications: $e');
      _error = 'Failed to initialize notifications';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create personalized booking notification
  Future<void> createPersonalizedBookingNotification({
    required String bookingId,
    required String passengerName,
    required String busName,
    required String sourceCity,
    required String destinationCity,
    required DateTime travelDate,
    required List<String> seats,
    required double amount,
  }) async {
    await createNotification(
      title: '🎉 Booking Confirmed!',
      body:
          'Dear $passengerName, your booking is confirmed from $sourceCity to $destinationCity',
      type: 'booking_confirmed',
      data: {
        'bookingId': bookingId,
        'busName': busName,
        'route': '$sourceCity → $destinationCity',
        'travelDate': travelDate.toIso8601String(),
        'seats': seats,
        'amount': amount,
        'passengerName': passengerName,
      },
    );
  }

  // Create a new notification
  Future<void> createNotification({
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
  }) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      type: type,
      data: data ?? {},
      timestamp: DateTime.now(),
      imageUrl: imageUrl,
      actionUrl: actionUrl,
    );

    _notifications.insert(0, notification);
    notifyListeners();
    print('✅ Created notification: $title');
  }

  // Create payment success notification
  Future<void> createPaymentSuccessNotification({
    required String bookingId,
    required double amount,
    required String paymentMethod,
  }) async {
    await createNotification(
      title: '💳 Payment Successful',
      body: 'Payment of ₹$amount has been processed successfully',
      type: 'payment_success',
      data: {
        'bookingId': bookingId,
        'amount': amount,
        'paymentMethod': paymentMethod,
      },
    );
  }

  // Create trip reminder notification
  Future<void> createTripReminderNotification({
    required String bookingId,
    required String busName,
    required String route,
    required DateTime departureTime,
  }) async {
    await createNotification(
      title: '🚌 Trip Reminder',
      body:
          'Your bus $busName from $route departs tomorrow at ${departureTime.hour}:${departureTime.minute.toString().padLeft(2, '0')}',
      type: 'trip_reminder',
      data: {
        'bookingId': bookingId,
        'busName': busName,
        'route': route,
        'departureTime': departureTime.toIso8601String(),
      },
    );
  }

  // Create cancellation notification
  Future<void> createCancellationNotification({
    required String bookingId,
    required String busName,
    required String reason,
  }) async {
    await createNotification(
      title: '❌ Booking Cancelled',
      body: 'Your booking for $busName has been cancelled. $reason',
      type: 'booking_cancelled',
      data: {'bookingId': bookingId, 'busName': busName, 'reason': reason},
    );
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
        print('✅ Marked notification as read: $notificationId');
      }
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  // Mark notification as unread
  Future<void> markAsUnread(String notificationId) async {
    try {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: false);
        notifyListeners();
        print('✅ Marked notification as unread: $notificationId');
      }
    } catch (e) {
      print('❌ Error marking notification as unread: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      notifyListeners();
      print('✅ Marked all notifications as read');
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
      print('✅ Deleted notification: $notificationId');
    } catch (e) {
      print('❌ Error deleting notification: $e');
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      _notifications.clear();
      notifyListeners();
      print('✅ Cleared all notifications');
    } catch (e) {
      print('❌ Error clearing notifications: $e');
    }
  }

  // Refresh notifications
  Future<void> refresh() async {
    await initialize();
  }

  // Filter notifications by read status
  List<NotificationModel> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  List<NotificationModel> get readNotifications =>
      _notifications.where((n) => n.isRead).toList();

  // Get notifications grouped by date
  Map<String, List<NotificationModel>> get groupedNotifications {
    final Map<String, List<NotificationModel>> grouped = {};

    for (final notification in _notifications) {
      final date = _formatDateKey(notification.timestamp);
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(notification);
    }

    return grouped;
  }

  String _formatDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notificationDate = DateTime(date.year, date.month, date.day);

    if (notificationDate == today) {
      return 'Today';
    } else if (notificationDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Get notification statistics
  Map<String, int> get notificationStats {
    final stats = <String, int>{};
    for (final notification in _notifications) {
      stats[notification.type] = (stats[notification.type] ?? 0) + 1;
    }
    return stats;
  }
}
