import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String
  type; // 'booking_confirmed', 'booking_cancelled', 'payment_success', etc.
  final Map<String, dynamic> data; // Additional data like booking details
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;
  final String? actionUrl; // Deep link or navigation route

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
    this.actionUrl,
  });

  // Create a copy with updated fields
  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    bool? isRead,
    String? imageUrl,
    String? actionUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }

  // Get notification icon based on type
  IconData get icon {
    switch (type) {
      case 'booking_confirmed':
        return Icons.check_circle;
      case 'booking_cancelled':
        return Icons.cancel;
      case 'payment_success':
        return Icons.payment;
      case 'payment_failed':
        return Icons.error;
      case 'refund_processed':
        return Icons.money;
      case 'trip_reminder':
        return Icons.notifications;
      case 'trip_completed':
        return Icons.check_circle_outline;
      case 'offer':
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }

  // Get notification color based on type
  Color get color {
    switch (type) {
      case 'booking_confirmed':
      case 'payment_success':
      case 'refund_processed':
      case 'trip_completed':
        return Colors.green;
      case 'booking_cancelled':
      case 'payment_failed':
        return Colors.red;
      case 'trip_reminder':
        return Colors.blue;
      case 'offer':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Get formatted time string
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  // Get formatted date and time
  String get formattedDateTime {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notificationDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    String dateStr;
    if (notificationDate == today) {
      dateStr = 'Today';
    } else if (notificationDate == yesterday) {
      dateStr = 'Yesterday';
    } else {
      dateStr = '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }

    final timeStr =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    return '$dateStr at $timeStr';
  }

  // Convert to Map (for future database storage if needed)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
    };
  }

  // Create from Map (for future database retrieval if needed)
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? 'general',
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      timestamp: DateTime.parse(
        map['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      isRead: map['isRead'] ?? false,
      imageUrl: map['imageUrl'],
      actionUrl: map['actionUrl'],
    );
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, type: $type, isRead: $isRead, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}
