import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Define the notification channel
  static const String _channelId = 'booking_channel';
  static const String _channelName = 'Booking Notifications';
  static const String _channelDescription =
      'Notifications for booking confirmations and payments';

  static const AndroidNotificationDetails _androidNotificationDetails =
      AndroidNotificationDetails(
        _channelId, // channel id
        _channelName, // channel name
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(''),
        enableLights: true,
        enableVibration: true,
        playSound: true,
        showWhen: true,
      );

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: _androidNotificationDetails,
  );

  Future<void> initialize() async {
    try {
      const AndroidInitializationSettings androidInitializationSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: androidInitializationSettings);

      await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel - THIS IS THE MISSING PART
      await _createNotificationChannel();

      // Request permissions for Android 13+
      await _requestPermissions();

      print('✅ Local notifications initialized successfully');
    } catch (e) {
      print('❌ Error initializing local notifications: $e');
    }
  }

  Future<void> _createNotificationChannel() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        showBadge: true,
      );

      await androidImplementation.createNotificationChannel(channel);
      print('✅ Notification channel created: $_channelId');
    }
  }

  Future<void> _requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      final bool? granted = await androidImplementation
          .requestNotificationsPermission();
      print('✅ Notification permission granted: $granted');
    }
  }

  Future<void> _onNotificationTapped(NotificationResponse response) async {
    // Handle notification tap if needed
    print('📱 Notification tapped: ${response.payload}');
  }

  Future<void> showBookingConfirmationNotification({
    required String bookingId,
    required String sourceCity,
    required String destinationCity,
    required double amount,
    required String paymentMethod,
    List<String>? seats,
  }) async {
    try {
      final seatText = seats?.isNotEmpty == true
          ? ' (Seats: ${seats!.join(', ')})'
          : '';

      // Use a unique ID based on booking ID
      final int notificationId = bookingId.hashCode;

      await _notifications.show(
        notificationId,
        '🎫 Booking Confirmed!',
        'Your bus ticket from $sourceCity to $destinationCity has been booked successfully$seatText. Amount: ₹${amount.toStringAsFixed(2)} via $paymentMethod. Booking ID: $bookingId',
        _notificationDetails,
        payload: bookingId,
      );

      print('✅ Created notification: 🎉 Booking Confirmed!');
      print('✅ Booking confirmation notification created');
      print('✅ Booking confirmation notification sent');
    } catch (e) {
      print('❌ Error showing booking notification: $e');
    }
  }

  Future<void> showPaymentSuccessNotification({
    required String bookingId,
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      // Use a unique ID based on booking ID + 1000
      final int notificationId = bookingId.hashCode + 1000;

      await _notifications.show(
        notificationId,
        '💳 Payment Successful!',
        'Payment of ₹${amount.toStringAsFixed(2)} completed successfully via $paymentMethod for booking $bookingId.',
        _notificationDetails,
        payload: bookingId,
      );

      print('✅ Created notification: 💳 Payment Successful');
      print('✅ Payment success notification created');
      print('✅ Payment success notification sent');
    } catch (e) {
      print('❌ Error showing payment notification: $e');
    }
  }

  Future<void> showWalletDebitNotification({
    required String bookingId,
    required double amount,
  }) async {
    try {
      // Use a unique ID based on booking ID + 2000
      final int notificationId = bookingId.hashCode + 2000;

      await _notifications.show(
        notificationId,
        '💸 Wallet Debit',
        '₹${amount.toStringAsFixed(2)} has been debited from your wallet for booking $bookingId.',
        _notificationDetails,
        payload: bookingId,
      );

      print('✅ Wallet debit notification sent');
    } catch (e) {
      print('❌ Error showing wallet debit notification: $e');
    }
  }
}
