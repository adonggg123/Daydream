import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/booking.dart';
import 'audit_trail_service.dart';
import 'user_service.dart';
import 'notification_service.dart';
import 'role_based_access_control.dart';

class CottageBookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'cottage_bookings';
  final AuditTrailService _auditTrail = AuditTrailService();
  final UserService _userService = UserService();
  final NotificationService _notificationService = NotificationService();

  // Create a cottage booking
  Future<String> createCottageBooking({
    required String userId,
    required String cottageId,
    required String cottageName,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
    String? specialRequests,
    required double cottagePrice,
    required double subtotal,
    required double tax,
    required double discount,
    required double total,
    String? paymentId,
    bool isPaid = false,
  }) async {
    final bookingRef = _firestore.collection(_collection).doc();
    
    final booking = Booking(
      id: bookingRef.id,
      userId: userId,
      roomId: cottageId,
      roomName: cottageName,
      checkIn: checkIn,
      checkOut: checkOut,
      guests: guests,
      eventType: EventType.none,
      eventDetails: null,
      specialRequests: specialRequests,
      roomPrice: cottagePrice,
      eventFee: 0.0,
      subtotal: subtotal,
      tax: tax,
      discount: discount,
      total: total,
      status: isPaid ? BookingStatus.confirmed : BookingStatus.pending,
      timestamp: DateTime.now(),
      paymentId: paymentId,
      isPaid: isPaid,
    );

    await bookingRef.set(booking.toMap());

    // Log audit trail & notify admins (best-effort; don't fail booking)
    try {
      final userProfile = await _userService.getUserProfile(userId);
      if (userProfile != null) {
        await _auditTrail.logAction(
          userId: userId,
          userEmail: userProfile.email,
          userRole: userProfile.role,
          action: AuditAction.bookingCreated,
          resourceType: 'cottage_booking',
          resourceId: bookingRef.id,
          details: {
            'cottageId': cottageId,
            'cottageName': cottageName,
            'checkIn': checkIn.toIso8601String(),
            'checkOut': checkOut.toIso8601String(),
            'total': total,
          },
        );
        await _notificationService.createAdminBookingNotification(
          bookingId: bookingRef.id,
          roomName: cottageName,
          userEmail: userProfile.email,
          checkIn: checkIn,
          checkOut: checkOut,
          total: total,
        );
      }
    } catch (e) {
      debugPrint('Error logging audit/notification for cottage booking: $e');
    }
    
    return bookingRef.id;
  }

  // Get cottage booking by ID
  Future<Booking?> getCottageBookingById(String bookingId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(bookingId).get();
      if (!doc.exists) {
        return null;
      }
      return Booking.fromMap(doc.id, Map<String, dynamic>.from(doc.data() as Map));
    } catch (e) {
      debugPrint('Error getting cottage booking by ID: $e');
      return null;
    }
  }

  // Get user cottage bookings
  Stream<List<Booking>> getUserCottageBookings(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final bookings = snapshot.docs.map((doc) {
        try {
          return Booking.fromMap(doc.id, Map<String, dynamic>.from(doc.data() as Map));
        } catch (e) {
          debugPrint('Error parsing cottage booking ${doc.id}: $e');
          return null;
        }
      }).whereType<Booking>().toList();
      
      // Sort by timestamp descending (most recent first)
      bookings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return bookings;
    });
  }

  // Get all cottage bookings for admin
  Stream<List<Booking>> getAllCottageBookingsForAdmin() {
    return _firestore
        .collection(_collection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      final bookings = snapshot.docs.map((doc) {
        try {
          return Booking.fromMap(doc.id, Map<String, dynamic>.from(doc.data() as Map));
        } catch (e) {
          debugPrint('Error parsing cottage booking ${doc.id}: $e');
          return null;
        }
      }).whereType<Booking>().toList();
      
      return bookings;
    });
  }

  // Edit cottage booking
  Future<void> editCottageBooking({
    required String bookingId,
    required String userId,
    DateTime? checkIn,
    DateTime? checkOut,
    int? guests,
    String? specialRequests,
  }) async {
    final doc = await _firestore.collection(_collection).doc(bookingId).get();
    if (!doc.exists) {
      throw Exception('Cottage booking not found');
    }

    final booking = Booking.fromMap(doc.id, Map<String, dynamic>.from(doc.data() as Map));
    
    // Verify user owns the booking
    if (booking.userId != userId) {
      throw Exception('Unauthorized: You can only edit your own cottage bookings.');
    }

    final updateData = <String, dynamic>{};
    
    // If booking was cancelled, reactivate it to pending status when edited
    if (booking.status == BookingStatus.cancelled) {
      updateData['status'] = BookingStatus.pending.name;
    }
    
    if (checkIn != null) {
      updateData['checkIn'] = checkIn.toIso8601String();
    }
    if (checkOut != null) {
      updateData['checkOut'] = checkOut.toIso8601String();
    }
    if (guests != null) {
      updateData['guests'] = guests;
    }
    if (specialRequests != null) {
      updateData['specialRequests'] = specialRequests;
    }

    // If dates changed, recalculate pricing (for cottages, always 1 day)
    if (checkIn != null || checkOut != null) {
      // For cottages, always 1 day
      final days = 1;
      final newSubtotal = booking.roomPrice * days;
      final newTax = newSubtotal * 0.1;
      final newTotal = newSubtotal + newTax - booking.discount;
      
      updateData['subtotal'] = newSubtotal;
      updateData['tax'] = newTax;
      updateData['total'] = newTotal;
      updateData['numberOfNights'] = days;
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
        resourceType: 'cottage_booking',
        resourceId: bookingId,
        details: {
          ...updateData,
          'previousStatus': booking.status.name,
        },
      );
    }
  }

  // Cancel cottage booking
  Future<void> cancelCottageBooking({
    required String bookingId,
    required String userId,
    String? callerUserId,
  }) async {
    final doc = await _firestore.collection(_collection).doc(bookingId).get();
    if (!doc.exists) {
      throw Exception('Cottage booking not found');
    }

    final booking = Booking.fromMap(doc.id, Map<String, dynamic>.from(doc.data() as Map));
    
    // If callerUserId is provided, it's admin canceling; otherwise verify user owns the booking
    if (callerUserId == null && booking.userId != userId) {
      throw Exception('Unauthorized: You can only cancel your own cottage bookings.');
    }

    await _firestore.collection(_collection).doc(bookingId).update({
      'status': BookingStatus.cancelled.name,
    });

    // Log audit trail
    final userProfile = await _userService.getUserProfile(userId);
    if (userProfile != null) {
      await _auditTrail.logAction(
        userId: userId,
        userEmail: userProfile.email,
        userRole: userProfile.role,
        action: AuditAction.bookingCancelled,
        resourceType: 'cottage_booking',
        resourceId: bookingId,
      );
    }
  }

  // Delete cottage booking (permanently removes from database)
  Future<void> deleteCottageBooking({
    required String bookingId,
    required String userId,
  }) async {
    final doc = await _firestore.collection(_collection).doc(bookingId).get();
    if (!doc.exists) {
      throw Exception('Cottage booking not found');
    }

    final booking = Booking.fromMap(doc.id, Map<String, dynamic>.from(doc.data() as Map));
    
    // Verify user owns the booking
    if (booking.userId != userId) {
      throw Exception('Unauthorized: You can only delete your own cottage bookings.');
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
        resourceType: 'cottage_booking',
        resourceId: bookingId,
        details: {
          'action': 'deleted',
          'cottageName': booking.roomName,
          'checkIn': booking.checkIn.toIso8601String(),
          'checkOut': booking.checkOut.toIso8601String(),
        },
      );
    }
  }

  // Accept a cottage booking (admin action)
  Future<void> acceptCottageBooking({
    required String bookingId,
    required String callerUserId,
    bool checkConflicts = true,
  }) async {
    final callerProfile = await _userService.getUserProfile(callerUserId);
    if (callerProfile == null || !RoleBasedAccessControl.userHasPermission(callerProfile, Permission.viewBookings)) {
      throw Exception('Unauthorized: caller does not have permission to accept cottage bookings.');
    }

    final doc = await _firestore.collection(_collection).doc(bookingId).get();
    if (!doc.exists) {
      throw Exception('Cottage booking not found');
    }

    final booking = Booking.fromMap(doc.id, Map<String, dynamic>.from(doc.data() as Map));
    
    if (booking.status != BookingStatus.pending) {
      throw Exception('Only pending cottage bookings can be accepted');
    }

    // Check for conflicts if requested (same date bookings for the same cottage)
    if (checkConflicts) {
      final conflicts = await getConflictingCottageBookings(
        cottageId: booking.roomId,
        checkIn: booking.checkIn,
        checkOut: booking.checkOut,
        excludeBookingId: bookingId,
      );
      
      if (conflicts.isNotEmpty) {
        throw Exception('Conflict detected: ${conflicts.length} overlapping booking(s) found. Please resolve conflicts first.');
      }
    }

    await _firestore.collection(_collection).doc(bookingId).update({
      'status': BookingStatus.confirmed.name,
    });

    // Log audit trail
    await _auditTrail.logAction(
      userId: callerUserId,
      userEmail: callerProfile.email,
      userRole: callerProfile.role,
      action: AuditAction.bookingUpdated,
      resourceType: 'cottage_booking',
      resourceId: bookingId,
      details: {
        'action': 'accepted',
        'cottageId': booking.roomId,
        'cottageName': booking.roomName,
      },
    );

    // Notify user
    await _notificationService.notifyUserBookingAccepted(
      userId: booking.userId,
      bookingId: bookingId,
      roomName: booking.roomName,
      checkIn: booking.checkIn,
      checkOut: booking.checkOut,
    );
  }

  // Reject a cottage booking (admin action)
  Future<void> rejectCottageBooking({
    required String bookingId,
    required String callerUserId,
    String? reason,
  }) async {
    final callerProfile = await _userService.getUserProfile(callerUserId);
    if (callerProfile == null || !RoleBasedAccessControl.userHasPermission(callerProfile, Permission.viewBookings)) {
      throw Exception('Unauthorized: caller does not have permission to reject cottage bookings.');
    }

    final doc = await _firestore.collection(_collection).doc(bookingId).get();
    if (!doc.exists) {
      throw Exception('Cottage booking not found');
    }

    final booking = Booking.fromMap(doc.id, Map<String, dynamic>.from(doc.data() as Map));
    
    if (booking.status != BookingStatus.pending) {
      throw Exception('Only pending cottage bookings can be rejected');
    }

    await _firestore.collection(_collection).doc(bookingId).update({
      'status': BookingStatus.rejected.name,
    });

    // Log audit trail
    await _auditTrail.logAction(
      userId: callerUserId,
      userEmail: callerProfile.email,
      userRole: callerProfile.role,
      action: AuditAction.bookingUpdated,
      resourceType: 'cottage_booking',
      resourceId: bookingId,
      details: {
        'action': 'rejected',
        'reason': reason,
        'cottageId': booking.roomId,
        'cottageName': booking.roomName,
      },
    );

    // Notify user
    await _notificationService.notifyUserBookingRejected(
      userId: booking.userId,
      bookingId: bookingId,
      roomName: booking.roomName,
      reason: reason,
    );
  }

  // Check for conflicting cottage bookings (overlapping dates for the same cottage)
  Future<List<Booking>> getConflictingCottageBookings({
    required String cottageId,
    required DateTime checkIn,
    required DateTime checkOut,
    String? excludeBookingId,
  }) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('roomId', isEqualTo: cottageId)
        .where('status', whereIn: [BookingStatus.confirmed.name, BookingStatus.pending.name])
        .get();

    return snapshot.docs
        .where((doc) {
          if (excludeBookingId != null && doc.id == excludeBookingId) {
            return false;
          }
          final bookingData = doc.data();
          final bookingCheckIn = DateTime.parse(bookingData['checkIn'] ?? '');
          final bookingCheckOut = DateTime.parse(bookingData['checkOut'] ?? '');
          // Check if booking overlaps with requested dates
          return bookingCheckOut.isAfter(checkIn) && bookingCheckIn.isBefore(checkOut);
        })
        .map((doc) => Booking.fromMap(doc.id, Map<String, dynamic>.from(doc.data() as Map)))
        .toList();
  }

  // Check if cottage is available for date
  Future<bool> isCottageAvailable({
    required String cottageId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    final conflicts = await getConflictingCottageBookings(
      cottageId: cottageId,
      checkIn: checkIn,
      checkOut: checkOut,
    );
    return conflicts.isEmpty;
  }
}

