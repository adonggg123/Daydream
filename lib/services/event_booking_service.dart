import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/event_booking.dart';
import '../models/booking.dart';
import '../services/audit_trail_service.dart';
import '../services/user_service.dart';
import '../services/notification_service.dart';

class EventBookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'event_bookings';
  final AuditTrailService _auditTrail = AuditTrailService();
  final UserService _userService = UserService();
  final NotificationService _notificationService = NotificationService();

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  // Get user event bookings
  Stream<List<EventBooking>> getUserEventBookings(String userId) {
    // Query without orderBy to avoid index requirement, then sort in memory
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final bookings = <EventBooking>[];
      for (var doc in snapshot.docs) {
        try {
          final booking = EventBooking.fromSnapshot(
            doc as DocumentSnapshot<Map<String, dynamic>>,
          );
          bookings.add(booking);
        } catch (e) {
          debugPrint('Error parsing event booking ${doc.id}: $e');
          debugPrint('Document data: ${doc.data()}');
          // Skip invalid documents
          continue;
        }
      }
      // Sort by createdAt descending (newest first)
      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return bookings;
    });
  }

  Future<bool> isHallAvailable(DateTime date) async {
    final key = _dateKey(date);
    final snapshot = await _firestore
        .collection(_collection)
        .where('eventDateKey', isEqualTo: key)
        .where('status', isNotEqualTo: EventBookingStatus.cancelled.name)
        .orderBy('status')
        .orderBy('__name__')
        .get();
    return snapshot.docs.isEmpty;
  }

  Future<String> createEventBooking({
    required String userId,
    required String userEmail,
    required EventType eventType,
    required DateTime eventDate,
    required int peopleCount,
    String? notes,
  }) async {
    final key = _dateKey(eventDate);
    final existing = await _firestore
        .collection(_collection)
        .where('eventDateKey', isEqualTo: key)
        .where('status', isNotEqualTo: EventBookingStatus.cancelled.name)
        .orderBy('status')
        .orderBy('__name__')
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('The function hall is already booked for this date.');
    }

    final doc = _firestore.collection(_collection).doc();
    final booking = EventBooking(
      id: doc.id,
      userId: userId,
      userEmail: userEmail,
      eventType: eventType,
      eventDate: DateTime(eventDate.year, eventDate.month, eventDate.day),
      peopleCount: peopleCount,
      notes: notes,
      createdAt: DateTime.now(),
    );

    await doc.set(booking.toMap());

    // Try to log audit trail and send notification, but don't fail if permissions are denied
    final profile = await _userService.getUserProfile(userId);
    if (profile != null) {
      try {
        await _auditTrail.logAction(
          userId: userId,
          userEmail: userEmail,
          userRole: profile.role,
          action: AuditAction.bookingCreated,
          resourceType: 'event_booking',
          resourceId: doc.id,
          details: {
            'eventType': eventType.name,
            'eventDate': booking.eventDate.toIso8601String(),
            'people': peopleCount,
          },
        );
      } catch (e) {
        // Silently handle audit trail errors - booking is already created
        debugPrint('Audit trail logging failed (permission issue): $e');
      }
      
      // Send notification to admin
      try {
        await _notificationService.createAdminEventBookingNotification(
          bookingId: doc.id,
          userEmail: userEmail,
          eventType: Booking.getEventTypeDisplay(eventType),
          eventDate: booking.eventDate,
          peopleCount: peopleCount,
        );
      } catch (e) {
        // Silently handle notification errors - booking is already created
        debugPrint('Admin notification creation failed (permission issue): $e');
      }
    }

    return doc.id;
  }

  // Check for conflicting event bookings (same date)
  Future<List<EventBooking>> getConflictingEventBookings({
    required DateTime eventDate,
    String? excludeBookingId,
  }) async {
    final key = _dateKey(eventDate);
    final snapshot = await _firestore
        .collection(_collection)
        .where('eventDateKey', isEqualTo: key)
        .where('status', whereIn: [EventBookingStatus.confirmed.name, EventBookingStatus.pending.name])
        .get();

    final bookings = snapshot.docs
        .map((doc) => EventBooking.fromSnapshot(doc as DocumentSnapshot<Map<String, dynamic>>))
        .where((booking) => excludeBookingId == null || booking.id != excludeBookingId)
        .toList();

    return bookings;
  }

  // Get event booking by ID
  Future<EventBooking?> getEventBookingById(String bookingId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(bookingId).get();
      if (!doc.exists) {
        return null;
      }
      return EventBooking.fromSnapshot(doc);
    } catch (e) {
      debugPrint('Error getting event booking by ID: $e');
      return null;
    }
  }

  // Accept an event booking (admin action)
  Future<void> acceptEventBooking({
    required String bookingId,
    required String callerUserId,
    bool checkConflicts = true,
  }) async {
    final doc = await _firestore.collection(_collection).doc(bookingId).get();
    if (!doc.exists) {
      throw Exception('Event booking not found');
    }

    final booking = EventBooking.fromSnapshot(doc);
    
    if (booking.status != EventBookingStatus.pending) {
      throw Exception('Only pending event bookings can be accepted');
    }

    // Check for conflicts if requested
    if (checkConflicts) {
      final conflicts = await getConflictingEventBookings(
        eventDate: booking.eventDate,
        excludeBookingId: bookingId,
      );
      
      if (conflicts.isNotEmpty) {
        throw Exception('Conflict detected: Another event booking exists for this date. Please resolve conflicts first.');
      }
    }

    await _firestore.collection(_collection).doc(bookingId).update({
      'status': EventBookingStatus.confirmed.name,
    });

    // Log audit trail
    final callerProfile = await _userService.getUserProfile(callerUserId);
    if (callerProfile != null) {
      await _auditTrail.logAction(
        userId: callerUserId,
        userEmail: callerProfile.email,
        userRole: callerProfile.role,
        action: AuditAction.bookingUpdated,
        resourceType: 'event_booking',
        resourceId: bookingId,
        details: {
          'action': 'accepted',
          'eventType': booking.eventType.name,
          'eventDate': booking.eventDate.toIso8601String(),
        },
      );
    }

    // Notify user
    await _notificationService.notifyUserBookingAccepted(
      userId: booking.userId,
      bookingId: bookingId,
      roomName: 'Function Hall',
      checkIn: booking.eventDate,
      checkOut: booking.eventDate,
      isEventBooking: true,
      eventType: Booking.getEventTypeDisplay(booking.eventType),
      eventDate: booking.eventDate,
    );
  }

  // Reject an event booking (admin action)
  Future<void> rejectEventBooking({
    required String bookingId,
    required String callerUserId,
    String? reason,
  }) async {
    final doc = await _firestore.collection(_collection).doc(bookingId).get();
    if (!doc.exists) {
      throw Exception('Event booking not found');
    }

    final booking = EventBooking.fromSnapshot(doc);
    
    if (booking.status != EventBookingStatus.pending) {
      throw Exception('Only pending event bookings can be rejected');
    }

    await _firestore.collection(_collection).doc(bookingId).update({
      'status': EventBookingStatus.rejected.name,
    });

    // Log audit trail
    final callerProfile = await _userService.getUserProfile(callerUserId);
    if (callerProfile != null) {
      await _auditTrail.logAction(
        userId: callerUserId,
        userEmail: callerProfile.email,
        userRole: callerProfile.role,
        action: AuditAction.bookingUpdated,
        resourceType: 'event_booking',
        resourceId: bookingId,
        details: {
          'action': 'rejected',
          'reason': reason,
          'eventType': booking.eventType.name,
          'eventDate': booking.eventDate.toIso8601String(),
        },
      );
    }

    // Notify user
    await _notificationService.notifyUserBookingRejected(
      userId: booking.userId,
      bookingId: bookingId,
      roomName: 'Function Hall',
      reason: reason,
      isEventBooking: true,
      eventType: Booking.getEventTypeDisplay(booking.eventType),
      eventDate: booking.eventDate,
    );
  }

  // Edit event booking (allows editing even if accepted/rejected/cancelled)
  Future<void> editEventBooking({
    required String bookingId,
    required String userId,
    DateTime? eventDate,
    int? peopleCount,
    String? notes,
    EventType? eventType,
  }) async {
    final doc = await _firestore.collection(_collection).doc(bookingId).get();
    if (!doc.exists) {
      throw Exception('Event booking not found');
    }

    final booking = EventBooking.fromSnapshot(doc);
    
    // Verify user owns the booking
    if (booking.userId != userId) {
      throw Exception('Unauthorized: You can only edit your own event bookings.');
    }

    final updateData = <String, dynamic>{};
    
    // If booking was cancelled, reactivate it to pending status when edited
    if (booking.status == EventBookingStatus.cancelled) {
      updateData['status'] = EventBookingStatus.pending.name;
    }
    
    if (eventDate != null) {
      final key = _dateKey(eventDate);
      // Check for conflicts if date changed (only check if not cancelled)
      if (booking.status != EventBookingStatus.cancelled) {
        final conflicts = await getConflictingEventBookings(
          eventDate: eventDate,
          excludeBookingId: bookingId,
        );
        if (conflicts.isNotEmpty) {
          throw Exception('The function hall is already booked for this date.');
        }
      }
      updateData['eventDate'] = Timestamp.fromDate(DateTime(eventDate.year, eventDate.month, eventDate.day));
      updateData['eventDateKey'] = key;
    }
    if (peopleCount != null) {
      updateData['peopleCount'] = peopleCount;
    }
    if (notes != null) {
      updateData['notes'] = notes;
    }
    if (eventType != null) {
      updateData['eventType'] = eventType.name;
    }

    await _firestore.collection(_collection).doc(bookingId).update(updateData);

    // Log audit trail
    final userProfile = await _userService.getUserProfile(userId);
    if (userProfile != null) {
      await _auditTrail.logAction(
        userId: userId,
        userEmail: userProfile.email,
        userRole: userProfile.role,
        action: AuditAction.bookingUpdated,
        resourceType: 'event_booking',
        resourceId: bookingId,
        details: {
          ...updateData,
          'previousStatus': booking.status.name,
        },
      );
    }
  }

  // Cancel event booking (allows canceling even if accepted/rejected)
  Future<void> cancelEventBooking({
    required String bookingId,
    required String userId,
    String? callerUserId,
  }) async {
    final doc = await _firestore.collection(_collection).doc(bookingId).get();
    if (!doc.exists) {
      throw Exception('Event booking not found');
    }

    final booking = EventBooking.fromSnapshot(doc);
    
    // If callerUserId is provided, it's admin canceling; otherwise verify user owns the booking
    if (callerUserId == null && booking.userId != userId) {
      throw Exception('Unauthorized: You can only cancel your own event bookings.');
    }

    await _firestore.collection(_collection).doc(bookingId).update({
      'status': EventBookingStatus.cancelled.name,
    });

    // Log audit trail
    final userProfile = await _userService.getUserProfile(userId);
    if (userProfile != null) {
      await _auditTrail.logAction(
        userId: userId,
        userEmail: userProfile.email,
        userRole: userProfile.role,
        action: AuditAction.bookingCancelled,
        resourceType: 'event_booking',
        resourceId: bookingId,
      );
    }
  }

  // Delete event booking (permanently removes from database)
  Future<void> deleteEventBooking({
    required String bookingId,
    required String userId,
  }) async {
    final doc = await _firestore.collection(_collection).doc(bookingId).get();
    if (!doc.exists) {
      throw Exception('Event booking not found');
    }

    final booking = EventBooking.fromSnapshot(doc);
    
    // Verify user owns the booking
    if (booking.userId != userId) {
      throw Exception('Unauthorized: You can only delete your own event bookings.');
    }

    // Delete the booking document
    await _firestore.collection(_collection).doc(bookingId).delete();

    // Log audit trail
    final userProfile = await _userService.getUserProfile(userId);
    if (userProfile != null) {
      await _auditTrail.logAction(
        userId: userId,
        userEmail: userProfile.email,
        userRole: userProfile.role,
        action: AuditAction.bookingCancelled,
        resourceType: 'event_booking',
        resourceId: bookingId,
        details: {
          'action': 'deleted',
          'eventType': booking.eventType.name,
          'eventDate': booking.eventDate.toIso8601String(),
        },
      );
    }
  }
}


