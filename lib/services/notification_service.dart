import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_notification.dart';
import 'role_based_access_control.dart';
import 'user_service.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _adminNotificationsCollection = 'admin_notifications';
  final String _userNotificationsCollection = 'user_notifications';

  /// Create a notification for admins when a new room booking is created.
  Future<void> createAdminBookingNotification({
    required String bookingId,
    required String roomName,
    required String userEmail,
    required DateTime checkIn,
    required DateTime checkOut,
    required double total,
  }) async {
    final docRef =
        _firestore.collection(_adminNotificationsCollection).doc();

    final notification = AdminNotification(
      id: docRef.id,
      title: 'New Room Booking',
      message:
          '$userEmail booked $roomName from ${checkIn.toLocal().toIso8601String().substring(0, 10)} '
          'to ${checkOut.toLocal().toIso8601String().substring(0, 10)} for \$$total',
      type: AdminNotificationType.bookingCreated,
      bookingId: bookingId,
      userEmail: userEmail,
      createdAt: DateTime.now(),
      isRead: false,
    );

    await docRef.set(notification.toMap());
  }

  /// Create a notification for admins when a new event booking is created.
  Future<void> createAdminEventBookingNotification({
    required String bookingId,
    required String userEmail,
    required String eventType,
    required DateTime eventDate,
    required int peopleCount,
  }) async {
    final docRef =
        _firestore.collection(_adminNotificationsCollection).doc();

    final notification = AdminNotification(
      id: docRef.id,
      title: 'New Event Booking',
      message:
          '$userEmail booked the function hall for $eventType on ${eventDate.toLocal().toIso8601String().substring(0, 10)} '
          'with $peopleCount ${peopleCount == 1 ? 'person' : 'people'}',
      type: AdminNotificationType.eventBookingCreated,
      bookingId: bookingId,
      userEmail: userEmail,
      createdAt: DateTime.now(),
      isRead: false,
    );

    await docRef.set(notification.toMap());
  }

  /// Stream latest admin notifications (newest first).
  Stream<List<AdminNotification>> getAdminNotifications({int limit = 20}) {
    return _firestore
        .collection(_adminNotificationsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              AdminNotification.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// Send notification to a specific user (e.g., message from receptionist)
  Future<void> sendUserNotification({
    required String callerUserId,
    required String userId,
    required String title,
    required String message,
  }) async {
    // Permission check
    final userService = UserService();
    final callerProfile = await userService.getUserProfile(callerUserId);
    if (callerProfile == null || !RoleBasedAccessControl.userHasPermission(callerProfile, Permission.sendNotifications)) {
      throw Exception('Unauthorized: caller does not have permission to send notifications.');
    }
    final docRef = _firestore.collection(_userNotificationsCollection).doc();
    final data = {
      'title': title,
      'message': message,
      'userId': userId,
      'createdAt': DateTime.now().toIso8601String(),
      'isRead': false,
    };
    await docRef.set(data);
  }

  /// Send notification to user when their booking is accepted (system notification, no permission check)
  Future<void> notifyUserBookingAccepted({
    required String userId,
    required String bookingId,
    required String roomName,
    required DateTime checkIn,
    required DateTime checkOut,
    bool isEventBooking = false,
    String? eventType,
    DateTime? eventDate,
  }) async {
    final docRef = _firestore.collection(_userNotificationsCollection).doc();
    final message = isEventBooking
        ? 'Your event booking for $eventType on ${eventDate!.toLocal().toIso8601String().substring(0, 10)} has been accepted!'
        : 'Your booking for $roomName from ${checkIn.toLocal().toIso8601String().substring(0, 10)} to ${checkOut.toLocal().toIso8601String().substring(0, 10)} has been accepted!';
    
    final data = {
      'title': isEventBooking ? 'Event Booking Accepted' : 'Booking Accepted',
      'message': message,
      'userId': userId,
      'bookingId': bookingId,
      'type': isEventBooking ? 'event_booking_accepted' : 'booking_accepted',
      'createdAt': DateTime.now().toIso8601String(),
      'isRead': false,
    };
    await docRef.set(data);
  }

  /// Send notification to user when their booking is rejected (system notification, no permission check)
  Future<void> notifyUserBookingRejected({
    required String userId,
    required String bookingId,
    required String roomName,
    DateTime? checkIn,
    DateTime? checkOut,
    String? reason,
    bool isEventBooking = false,
    String? eventType,
    DateTime? eventDate,
  }) async {
    final docRef = _firestore.collection(_userNotificationsCollection).doc();
    String message;
    if (isEventBooking) {
      message = 'Your event booking for $eventType on ${eventDate!.toLocal().toIso8601String().substring(0, 10)} has been rejected.';
    } else {
      message = 'Your booking for $roomName';
      if (checkIn != null && checkOut != null) {
        message += ' from ${checkIn.toLocal().toIso8601String().substring(0, 10)} to ${checkOut.toLocal().toIso8601String().substring(0, 10)}';
      }
      message += ' has been rejected.';
    }
    if (reason != null && reason.isNotEmpty) {
      message += ' Reason: $reason';
    }
    
    final data = {
      'title': isEventBooking ? 'Event Booking Rejected' : 'Booking Rejected',
      'message': message,
      'userId': userId,
      'bookingId': bookingId,
      'type': isEventBooking ? 'event_booking_rejected' : 'booking_rejected',
      'createdAt': DateTime.now().toIso8601String(),
      'isRead': false,
    };
    await docRef.set(data);
  }

  /// Get user notifications stream
  Stream<List<Map<String, dynamic>>> getUserNotifications(String userId, {int limit = 50}) {
    return _firestore
        .collection(_userNotificationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }
}


