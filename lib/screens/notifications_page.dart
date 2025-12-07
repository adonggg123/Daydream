import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'theme_constants.dart';

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
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
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
        return AppTheme.successColor;
      case 'booking_rejected':
      case 'event_booking_rejected':
        return AppTheme.errorColor;
      case 'post_liked':
        return AppTheme.accentColor;
      case 'post_commented':
        return AppTheme.infoColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: ClipOval(
                  child: Transform.scale(
                    scale: 1.43, // Scale to maintain 80x80 visual size (80/56 = 1.43)
                  child: Image.asset(
                    'assets/icons/LOGO2.png',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                   )
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Notifications',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.borderColor, width: 2),
                  ),
                  child: Icon(
                    Icons.notifications_none,
                    size: 60,
                    color: AppTheme.textSecondary.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Sign In Required',
                  style: AppTheme.heading2.copyWith(color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 12),
                Text(
                  'Please sign in to view notifications',
                  style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/icons/LOGO2.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Notifications',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          StreamBuilder<int>(
            stream: _notificationService.getUnreadNotificationCount(user.uid),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              if (unreadCount == 0) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$unreadCount new',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notificationService.getUserNotifications(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline,
                        size: 40,
                        color: AppTheme.errorColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Unable to load notifications',
                      style: AppTheme.heading3.copyWith(color: AppTheme.errorColor),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Please check your connection',
                      style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.notifications_none,
                        size: 60,
                        color: AppTheme.primaryColor.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No notifications',
                      style: AppTheme.heading2.copyWith(color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You\'ll see booking updates and important announcements here',
                      style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final notifications = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final createdAt = DateTime.parse(notification['createdAt']);
              final type = notification['type'] as String?;
              final icon = _getNotificationIcon(type);
              final color = _getNotificationColor(type);
              final isRead = notification['isRead'] ?? false;
              final notificationId = notification['id'] as String?;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: AppTheme.cardDecoration.copyWith(
                  color: isRead ? Colors.white : AppTheme.primaryColor.withOpacity(0.05),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (notificationId != null && !isRead) {
                        _notificationService.markNotificationAsRead(notificationId);
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              icon,
                              color: color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification['title'] ?? 'Notification',
                                  style: AppTheme.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isRead ? AppTheme.textPrimary : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notification['message'] ?? '',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: isRead ? AppTheme.textSecondary : AppTheme.textPrimary.withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _formatTime(createdAt),
                                  style: AppTheme.caption.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: StreamBuilder<int>(
        stream: _notificationService.getUnreadNotificationCount(user.uid),
        builder: (context, snapshot) {
          final unreadCount = snapshot.data ?? 0;
          if (unreadCount == 0) return const SizedBox.shrink();
          
          return FloatingActionButton(
            onPressed: () async {
              await _notificationService.markAllNotificationsAsRead(user.uid);
              setState(() {
                _hasMarkedAsRead = true;
              });
            },
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.done_all),
          );
        },
      ),
    );
  }
}