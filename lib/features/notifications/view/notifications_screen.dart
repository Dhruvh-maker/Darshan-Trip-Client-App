import 'package:darshan_trip/features/notifications/model/notification_model.dart';
import 'package:darshan_trip/features/notifications/viewmodel/notifications_viewmodel.dart'
    hide NotificationModel;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize notifications when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsViewModel>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: Consumer<NotificationsViewModel>(
        builder: (context, viewModel, child) {
          return _buildNotificationsList(viewModel);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.orange.shade600,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Notifications',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        Consumer<NotificationsViewModel>(
          builder: (context, viewModel, child) {
            return PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                switch (value) {
                  case 'mark_all_read':
                    viewModel.markAllAsRead();
                    break;
                  case 'clear_all':
                    _showClearAllDialog();
                    break;
                  case 'refresh':
                    viewModel.refresh();
                    break;
                }
              },
              itemBuilder: (context) => [
                if (viewModel.unreadCount > 0)
                  const PopupMenuItem(
                    value: 'mark_all_read',
                    child: Row(
                      children: [
                        Icon(Icons.mark_email_read, size: 20),
                        SizedBox(width: 12),
                        Text('Mark all as read'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all, size: 20),
                      SizedBox(width: 12),
                      Text('Clear all'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, size: 20),
                      SizedBox(width: 12),
                      Text('Refresh'),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildNotificationsList(NotificationsViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }

    if (viewModel.error != null) {
      return _buildErrorWidget(viewModel);
    }

    if (viewModel.notifications.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Notification count header
        if (viewModel.notifications.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Text(
                  '${viewModel.notifications.length} Notification${viewModel.notifications.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const Spacer(),
                if (viewModel.unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.shade300,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${viewModel.unreadCount} unread',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
              ],
            ),
          ),

        // Notifications list
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => viewModel.refresh(),
            color: Colors.orange.shade600,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: viewModel.groupedNotifications.length,
              itemBuilder: (context, index) {
                final dateKey = viewModel.groupedNotifications.keys.elementAt(
                  index,
                );
                final notifications = viewModel.groupedNotifications[dateKey]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateHeader(dateKey),
                    const SizedBox(height: 8),
                    ...notifications.map(
                      (notification) =>
                          _buildNotificationItem(notification, viewModel),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateHeader(String dateKey) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        dateKey,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    NotificationModel notification,
    NotificationsViewModel viewModel,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (!notification.isRead) {
              viewModel.markAsRead(notification.id);
            }
            _handleNotificationTap(notification);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: notification.isRead ? Colors.white : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: notification.isRead
                    ? Colors.grey.shade200
                    : Colors.orange.shade200,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: notification.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    notification.icon,
                    color: notification.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.orange.shade600,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            notification.formattedTime,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showNotificationOptions(
                              notification,
                              viewModel,
                            ),
                            child: Icon(
                              Icons.more_horiz,
                              size: 16,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll see notifications about your bookings here',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(NotificationsViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            viewModel.error ?? 'Failed to load notifications',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => viewModel.refresh(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    switch (notification.type) {
      case 'booking_confirmed':
      case 'booking_cancelled':
        // Navigate to booking details
        Navigator.pushNamed(
          context,
          '/booking_details',
          arguments: notification.data['bookingId'],
        );
        break;
      case 'payment_success':
      case 'payment_failed':
        // Navigate to payment history
        Navigator.pushNamed(context, '/payment_history');
        break;
      default:
        // Show notification details in a dialog
        _showNotificationDetails(notification);
    }
  }

  void _showNotificationDetails(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(notification.icon, color: notification.color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                notification.title,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.body,
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
            const SizedBox(height: 12),
            Text(
              'Received: ${notification.formattedTime}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            if (notification.data.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Details:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ...notification.data.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.key}: ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${entry.value}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
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

  void _showNotificationOptions(
    NotificationModel notification,
    NotificationsViewModel viewModel,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(
                notification.isRead
                    ? Icons.mark_email_unread
                    : Icons.mark_email_read,
                color: Colors.orange.shade600,
              ),
              title: Text(
                notification.isRead ? 'Mark as unread' : 'Mark as read',
              ),
              onTap: () {
                Navigator.pop(context);
                if (notification.isRead) {
                  viewModel.markAsUnread(notification.id);
                } else {
                  viewModel.markAsRead(notification.id);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(notification, viewModel);
              },
            ),
            ListTile(
              leading: Icon(Icons.info, color: Colors.blue.shade600),
              title: const Text('View details'),
              onTap: () {
                Navigator.pop(context);
                _showNotificationDetails(notification);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    NotificationModel notification,
    NotificationsViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Notification'),
        content: const Text(
          'Are you sure you want to delete this notification? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.deleteNotification(notification.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notification deleted'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear All Notifications'),
        content: const Text(
          'Are you sure you want to delete all notifications? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<NotificationsViewModel>().clearAllNotifications();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications cleared'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
