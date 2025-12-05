import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  final VoidCallback? onPageOpened;
  
  const NotificationsPage({super.key, this.onPageOpened});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy HH:mm');
  bool _hasMarkedAsRead = false;

  @override
  void initState() {
    super.initState();
    // Mark all notifications as read when page is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAllAsRead();
    });
  }

  Future<void> _markAllAsRead() async {
    final user = _authService.currentUser;
    if (user != null && !_hasMarkedAsRead) {
      try {
        await _notificationService.markAllNotificationsAsRead(user.uid);
        _hasMarkedAsRead = true;
        // Notify parent that page was opened
        if (widget.onPageOpened != null) {
          widget.onPageOpened!();
        }
      } catch (e) {
        debugPrint('Error marking notifications as read: $e');
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else {
      return _dateFormat.format(dateTime);
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'booking_accepted':
        return Icons.check_circle;
      case 'booking_rejected':
        return Icons.cancel;
      case 'event_booking_accepted':
        return Icons.event_available;
      case 'event_booking_rejected':
        return Icons.event_busy;
      case 'post_liked':
        return Icons.favorite;
      case 'post_commented':
        return Icons.comment;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'booking_accepted':
      case 'event_booking_accepted':
        return Colors.green;
      case 'booking_rejected':
      case 'event_booking_rejected':
        return Colors.red;
      case 'post_liked':
        return Colors.pink;
      case 'post_commented':
        return Colors.blue;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          backgroundColor: Colors.purple.shade600,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Please log in to view notifications'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notificationService.getUserNotifications(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'ll see booking updates here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final createdAt = DateTime.parse(notification['createdAt']);
              final type = notification['type'] as String?;
              final icon = _getNotificationIcon(type);
              final color = _getNotificationColor(type);
              final isRead = notification['isRead'] ?? false;
              final notificationId = notification['id'] as String?;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: isRead ? Colors.white : Colors.blue.shade50,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.2),
                    child: Icon(icon, color: color),
                  ),
                  title: Text(
                    notification['title'] ?? 'Notification',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isRead ? Colors.grey.shade800 : Colors.black87,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        notification['message'] ?? '',
                        style: TextStyle(
                          color: isRead ? Colors.grey.shade600 : Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  trailing: !isRead
                      ? Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                  onTap: () {
                    // Mark as read when tapped
                    if (notificationId != null && !isRead) {
                      _notificationService.markNotificationAsRead(notificationId);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

