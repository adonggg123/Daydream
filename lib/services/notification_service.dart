import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_notification.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _adminNotificationsCollection = 'admin_notifications';

  /// Create a notification for admins when a new booking is created.
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
      title: 'New Booking',
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
}


