import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/room.dart';
import '../models/booking.dart';
import 'audit_trail_service.dart';
import 'user_service.dart';
import 'notification_service.dart';
import 'role_based_access_control.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _roomsCollection = 'rooms';
  final String _bookingsCollection = 'bookings';
  final AuditTrailService _auditTrail = AuditTrailService();
  final UserService _userService = UserService();
  final NotificationService _notificationService = NotificationService();

  // Convert image file to Base64 string (supports web/desktop blob URLs and regular files)
  Future<String> uploadRoomImage(File imageFile, String roomId) async {
    try {
      Uint8List bytes;
      
      // Handle web/desktop blob URLs and HTTP URLs
      if (kIsWeb || 
          imageFile.path.startsWith('blob:') || 
          imageFile.path.startsWith('http://') || 
          imageFile.path.startsWith('https://')) {
        // For web/desktop, read bytes from blob/HTTP URL using http
        try {
          final response = await http.get(Uri.parse(imageFile.path)).timeout(
            const Duration(seconds: 10),
          );
          
          if (response.statusCode != 200) {
            throw Exception('Failed to read URL: ${response.statusCode}');
          }
          
          bytes = response.bodyBytes;
        } catch (e) {
          debugPrint('Error fetching image from URL: $e');
          rethrow;
        }
      } else {
        // For mobile/desktop with file paths, read file normally
        try {
          bytes = await imageFile.readAsBytes();
        } catch (e) {
          // If readAsBytes fails, try reading as a file that might not exist yet
          debugPrint('Error reading file bytes: $e');
          debugPrint('File path: ${imageFile.path}');
          
          // Try to read the file even if it doesn't "exist" (might be a temp file)
          try {
            bytes = await imageFile.readAsBytes();
          } catch (e2) {
            debugPrint('Second attempt to read file also failed: $e2');
            rethrow;
          }
        }
      }
      
      // Convert to Base64 string
      final base64String = base64Encode(bytes);
      
      // Determine image format from file extension or default to jpeg
      String imageFormat = 'jpeg';
      final fileName = imageFile.path.toLowerCase();
      if (fileName.endsWith('.png') || fileName.contains('.png')) {
        imageFormat = 'png';
      } else if (fileName.endsWith('.gif') || fileName.contains('.gif')) {
        imageFormat = 'gif';
      } else if (fileName.endsWith('.webp') || fileName.contains('.webp')) {
        imageFormat = 'webp';
      }
      
      // Return Base64 data URI format: data:image/jpeg;base64,<base64string>
      return 'data:image/$imageFormat;base64,$base64String';
    } catch (e) {
      debugPrint('Error converting image to Base64: $e');
      debugPrint('Image file path: ${imageFile.path}');
      rethrow;
    }
  }

  // Delete image - No-op for Base64 since images are stored in Firestore
  // Kept for backward compatibility with existing code
  Future<void> deleteRoomImage(String imageUrl) async {
    try {
      // Base64 images are stored in Firestore, so no deletion needed
      // Only delete from Firebase Storage if it's a Firebase Storage URL
      if (imageUrl.isEmpty || imageUrl.startsWith('data:image')) {
        return; // Base64 image or empty, skip deletion
      }
      
      // Only attempt deletion if it's a Firebase Storage URL
      if (imageUrl.contains('firebasestorage')) {
        final Reference ref = _storage.refFromURL(imageUrl);
        await ref.delete();
      }
    } catch (e) {
      debugPrint('Error deleting image: $e');
      // Don't throw - image deletion failure shouldn't block room operations
    }
  }

  // Get all rooms (for regular users - only available rooms)
  Future<List<Room>> getAllRooms() async {
    final roomsSnapshot = await _firestore.collection(_roomsCollection).get();
    return roomsSnapshot.docs
        .map((doc) => Room.fromMap(doc.id, doc.data()))
        .where((room) => room.isAvailable)
        .toList();
  }

  // Get all rooms including unavailable ones (for admin)
  Future<List<Room>> getAllRoomsForAdmin() async {
    final roomsSnapshot = await _firestore.collection(_roomsCollection).get();
    return roomsSnapshot.docs
        .map((doc) => Room.fromMap(doc.id, doc.data()))
        .toList();
  }

  // Stream all rooms for admin (real-time updates)
  Stream<List<Room>> streamAllRoomsForAdmin() {
    return _firestore.collection(_roomsCollection).snapshots().map((snapshot) {
      final rooms = <Room>[];
      for (final doc in snapshot.docs) {
        try {
          final room = Room.fromMap(doc.id, doc.data());
          rooms.add(room);
        } catch (e) {
          debugPrint('Error parsing room ${doc.id}: $e');
          // Continue processing other rooms even if one fails
        }
      }
      return rooms;
    }).handleError((error) {
      debugPrint('Error in streamAllRoomsForAdmin: $error');
      // Return empty list on error instead of crashing
      return <Room>[];
    });
  }

  // Stream all available rooms for regular users (real-time updates)
  Stream<List<Room>> streamAllRooms() {
    return _firestore.collection(_roomsCollection).snapshots().map((snapshot) {
      final rooms = <Room>[];
      for (final doc in snapshot.docs) {
        try {
          final room = Room.fromMap(doc.id, doc.data());
          // Only include available rooms for regular users
          if (room.isAvailable) {
            rooms.add(room);
          }
        } catch (e) {
          debugPrint('Error parsing room ${doc.id}: $e');
          // Continue processing other rooms even if one fails
        }
      }
      return rooms;
    }).handleError((error) {
      debugPrint('Error in streamAllRooms: $error');
      // Return empty list on error instead of crashing
      return <Room>[];
    });
  }

  // Update room availability
  Future<void> updateRoomAvailability({
    required String roomId,
    required bool isAvailable,
    String? userId,
  }) async {
    await _firestore.collection(_roomsCollection).doc(roomId).update({
      'isAvailable': isAvailable,
    });

    // Log audit trail
    if (userId != null) {
      final userProfile = await _userService.getUserProfile(userId);
      if (userProfile != null) {
        await _auditTrail.logAction(
          userId: userId,
          userEmail: userProfile.email,
          userRole: userProfile.role,
          action: isAvailable ? AuditAction.roomUpdated : AuditAction.roomUpdated,
          resourceType: 'room',
          resourceId: roomId,
          details: {
            'isAvailable': isAvailable,
          },
        );
      }
    }
  }

  // Create a new room
  Future<String> createRoom({
    required String name,
    required String description,
    required double price,
    required int capacity,
    List<String> amenities = const [],
    String imageUrl = '',
    bool isAvailable = true,
    String? userId,
  }) async {
    // Optional service-level permission guard (if userId provided, check createRoom permission)
    if (userId != null) {
      final callerProfile = await _userService.getUserProfile(userId);
      if (callerProfile == null || !RoleBasedAccessControl.userHasPermission(callerProfile, Permission.createRoom)) {
        throw Exception('Unauthorized: caller does not have permission to create rooms.');
      }
    }
    final roomRef = _firestore.collection(_roomsCollection).doc();
    final roomId = roomRef.id;

    final roomData = {
      'name': name,
      'description': description,
      'price': price,
      'capacity': capacity,
      'amenities': amenities,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
    };

    await roomRef.set(roomData);

    // Log audit trail
    if (userId != null) {
      final userProfile = await _userService.getUserProfile(userId);
      if (userProfile != null) {
        await _auditTrail.logAction(
          userId: userId,
          userEmail: userProfile.email,
          userRole: userProfile.role,
          action: AuditAction.roomCreated,
          resourceType: 'room',
          resourceId: roomId,
          details: roomData,
        );
      }
    }

    return roomId;
  }

  // Update room details
  Future<void> updateRoom({
    required String roomId,
    required String name,
    required String description,
    required double price,
    required int capacity,
    List<String>? amenities,
    String? imageUrl,
    bool? isAvailable,
    String? userId,
  }) async {
    final updateData = <String, dynamic>{
      'name': name,
      'description': description,
      'price': price,
      'capacity': capacity,
    };

    if (amenities != null) {
      updateData['amenities'] = amenities;
    }
    // Always update imageUrl if provided (including empty string to clear it)
    if (imageUrl != null) {
      updateData['imageUrl'] = imageUrl;
    }
    if (isAvailable != null) {
      updateData['isAvailable'] = isAvailable;
    }

    // Optional permissions guard
    if (userId != null) {
      final callerProfile = await _userService.getUserProfile(userId);
      if (callerProfile == null || !RoleBasedAccessControl.userHasPermission(callerProfile, Permission.editRoom)) {
        throw Exception('Unauthorized: caller does not have permission to edit rooms.');
      }
    }
    await _firestore.collection(_roomsCollection).doc(roomId).update(updateData);

    // Log audit trail
    if (userId != null) {
      final userProfile = await _userService.getUserProfile(userId);
      if (userProfile != null) {
        await _auditTrail.logAction(
          userId: userId,
          userEmail: userProfile.email,
          userRole: userProfile.role,
          action: AuditAction.roomUpdated,
          resourceType: 'room',
          resourceId: roomId,
          details: updateData,
        );
      }
    }
  }

  // Delete a room
  Future<void> deleteRoom({
    required String roomId,
    String? userId,
  }) async {
    // Optional permissions guard
    if (userId != null) {
      final callerProfile = await _userService.getUserProfile(userId);
      if (callerProfile == null || !RoleBasedAccessControl.userHasPermission(callerProfile, Permission.deleteRoom)) {
        throw Exception('Unauthorized: caller does not have permission to delete rooms.');
      }
    }
    await _firestore.collection(_roomsCollection).doc(roomId).delete();

    // Log audit trail
    if (userId != null) {
      final userProfile = await _userService.getUserProfile(userId);
      if (userProfile != null) {
        await _auditTrail.logAction(
          userId: userId,
          userEmail: userProfile.email,
          userRole: userProfile.role,
          action: AuditAction.roomDeleted,
          resourceType: 'room',
          resourceId: roomId,
        );
      }
    }
  }

  // Get available rooms for date range
  Future<List<Room>> getAvailableRooms({
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
  }) async {
    // Get all rooms
    final roomsSnapshot = await _firestore.collection(_roomsCollection).get();
    final allRooms = roomsSnapshot.docs
        .map((doc) => Room.fromMap(doc.id, doc.data()))
        .toList();

    // Get all confirmed bookings and filter for overlapping dates
    final bookingsSnapshot = await _firestore
        .collection(_bookingsCollection)
        .where('status', isEqualTo: BookingStatus.confirmed.name)
        .get();

    // Filter bookings that overlap with requested dates
    final bookedRoomIds = bookingsSnapshot.docs
        .where((doc) {
          final bookingData = doc.data();
          final bookingCheckIn = DateTime.parse(bookingData['checkIn'] ?? '');
          final bookingCheckOut = DateTime.parse(bookingData['checkOut'] ?? '');
          // Check if booking overlaps with requested dates
          return bookingCheckOut.isAfter(checkIn) && bookingCheckIn.isBefore(checkOut);
        })
        .map((doc) => doc.data()['roomId'] as String)
        .toSet();

    // Filter available rooms
    return allRooms.where((room) {
      return room.isAvailable &&
          !bookedRoomIds.contains(room.id) &&
          room.capacity >= guests;
    }).toList();
  }

  // Create a booking
  Future<String> createBooking({
    required String userId,
    required String roomId,
    required String roomName,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
    required EventType eventType,
    String? eventDetails,
    String? specialRequests,
    required double roomPrice,
    required double eventFee,
    required double subtotal,
    required double tax,
    required double discount,
    required double total,
    String? paymentId,
    bool isPaid = false,
  }) async {
    final bookingRef = _firestore.collection(_bookingsCollection).doc();
    
    final booking = Booking(
      id: bookingRef.id,
      userId: userId,
      roomId: roomId,
      roomName: roomName,
      checkIn: checkIn,
      checkOut: checkOut,
      guests: guests,
      eventType: eventType,
      eventDetails: eventDetails,
      specialRequests: specialRequests,
      roomPrice: roomPrice,
      eventFee: eventFee,
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
          resourceType: 'booking',
          resourceId: bookingRef.id,
          details: {
            'roomId': roomId,
            'roomName': roomName,
            'checkIn': checkIn.toIso8601String(),
            'checkOut': checkOut.toIso8601String(),
            'total': total,
          },
        );
        await _notificationService.createAdminBookingNotification(
          bookingId: bookingRef.id,
          roomName: roomName,
          userEmail: userProfile.email,
          checkIn: checkIn,
          checkOut: checkOut,
          total: total,
        );
      }
    } catch (e) {
      debugPrint('Error logging audit/notification for booking: $e');
    }
    
    return bookingRef.id;
  }

  // Get booking by ID
  Future<Booking?> getBookingById(String bookingId) async {
    try {
      final doc = await _firestore.collection(_bookingsCollection).doc(bookingId).get();
      if (!doc.exists) {
        return null;
      }
      return Booking.fromMap(doc.id, Map<String, dynamic>.from(doc.data() as Map));
    } catch (e) {
      debugPrint('Error getting booking by ID: $e');
      return null;
    }
  }

  // Get user bookings
  Stream<List<Booking>> getUserBookings(String userId) {
    return _firestore
        .collection(_bookingsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final bookings = snapshot.docs.map((doc) {
        try {
          return Booking.fromMap(doc.id, Map<String, dynamic>.from(doc.data() as Map));
        } catch (e) {
          debugPrint('Error parsing booking ${doc.id}: $e');
          return null;
        }
      }).whereType<Booking>().toList();
      
      // Sort by timestamp descending (most recent first)
      bookings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return bookings;
    });
  }

  // Update booking payment status
  Future<void> updateBookingPayment({
    required String bookingId,
    required String paymentId,
    required bool isPaid,
    String? userId,
    String? callerUserId,
  }) async {
    // If callerUserId is provided, check permission
    if (callerUserId != null) {
      final callerProfile = await _userService.getUserProfile(callerUserId);
      if (callerProfile == null || !RoleBasedAccessControl.userHasPermission(callerProfile, Permission.editAllBookings)) {
        throw Exception('Unauthorized: caller does not have permission to update booking payments.');
      }
    }
    await _firestore.collection(_bookingsCollection).doc(bookingId).update({
      'paymentId': paymentId,
      'isPaid': isPaid,
      'status': isPaid ? BookingStatus.confirmed.name : BookingStatus.pending.name,
    });
    
    // Log audit trail
    if (userId != null) {
      final userProfile = await _userService.getUserProfile(userId);
      if (userProfile != null) {
        await _auditTrail.logAction(
          userId: userId,
          userEmail: userProfile.email,
          userRole: userProfile.role,
          action: isPaid ? AuditAction.bookingPaymentProcessed : AuditAction.bookingUpdated,
          resourceType: 'booking',
          resourceId: bookingId,
          details: {
            'paymentId': paymentId,
            'isPaid': isPaid,
          },
        );
      }
    }
  }
  
  // Cancel booking
  Future<void> cancelBooking({
    required String bookingId,
    required String userId,
    String? callerUserId,
  }) async {
    final doc = await _firestore.collection(_bookingsCollection).doc(bookingId).get();
    if (!doc.exists) {
      throw Exception('Booking not found');
    }

    final booking = Booking.fromMap(doc.id, Map<String, dynamic>.from(doc.data() as Map));
    
    // If callerUserId is provided, check permissions; otherwise verify user owns the booking
    if (callerUserId != null) {
      final callerProfile = await _userService.getUserProfile(callerUserId);
      if (callerProfile == null || !RoleBasedAccessControl.userHasPermission(callerProfile, Permission.cancelAllBookings)) {
        throw Exception('Unauthorized: caller does not have permission to cancel bookings.');
      }
    } else {
      // User canceling their own booking - allow even if accepted/rejected
      if (booking.userId != userId) {
        throw Exception('Unauthorized: You can only cancel your own bookings.');
      }
    }

    await _firestore.collection(_bookingsCollection).doc(bookingId).update({
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
        resourceType: 'booking',
        resourceId: bookingId,
      );
    }
  }

  // Delete booking (permanently removes from database)
  Future<void> deleteBooking({
    required String bookingId,
    required String userId,
  }) async {
    final doc = await _firestore.collection(_bookingsCollection).doc(bookingId).get();
    if (!doc.exists) {
      throw Exception('Booking not found');
    }

    final booking = Booking.fromMap(doc.id, Map<String, dynamic>.from(doc.data() as Map));
    
    // Verify user owns the booking
    if (booking.userId != userId) {
      throw Exception('Unauthorized: You can only delete your own bookings.');
    }

    // Delete the booking document
    await _firestore.collection(_bookingsCollection).doc(bookingId).delete();
    
    // Log audit trail
    final userProfile = await _userService.getUserProfile(userId);
    if (userProfile != null) {
      await _auditTrail.logAction(
        userId: userId,
        userEmail: userProfile.email,
        userRole: userProfile.role,
        action: AuditAction.bookingCancelled,
        resourceType: 'booking',
        resourceId: bookingId,
        details: {
          'action': 'deleted',
          'roomName': booking.roomName,
          'checkIn': booking.checkIn.toIso8601String(),
          'checkOut': booking.checkOut.toIso8601String(),
        },
      );
    }
  }

  // Edit booking (allows editing even if accepted/rejected/cancelled)
  Future<void> editBooking({
    required String bookingId,
    required String userId,
    DateTime? checkIn,
    DateTime? checkOut,
    int? guests,
    String? specialRequests,
    String? eventDetails,
    EventType? eventType,
  }) async {
    final doc = await _firestore.collection(_bookingsCollection).doc(bookingId).get();
    if (!doc.exists) {
      throw Exception('Booking not found');
    }

    final booking = Booking.fromMap(doc.id, Map<String, dynamic>.from(doc.data() as Map));
    
    // Verify user owns the booking
    if (booking.userId != userId) {
      throw Exception('Unauthorized: You can only edit your own bookings.');
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
    if (eventDetails != null) {
      updateData['eventDetails'] = eventDetails;
    }
    if (eventType != null) {
      updateData['eventType'] = eventType.name;
    }

    // If dates changed, recalculate pricing
    if (checkIn != null || checkOut != null) {
      final finalCheckIn = checkIn ?? booking.checkIn;
      final finalCheckOut = checkOut ?? booking.checkOut;
      final nights = finalCheckOut.difference(finalCheckIn).inDays;
      final newSubtotal = booking.roomPrice * nights;
      final newTax = newSubtotal * 0.1;
      final newTotal = newSubtotal + newTax - booking.discount;
      
      updateData['subtotal'] = newSubtotal;
      updateData['tax'] = newTax;
      updateData['total'] = newTotal;
      updateData['numberOfNights'] = nights;
    }

    await _firestore.collection(_bookingsCollection).doc(bookingId).update(updateData);

    // Log audit trail
    final userProfile = await _userService.getUserProfile(userId);
    if (userProfile != null) {
      await _auditTrail.logAction(
        userId: userId,
        userEmail: userProfile.email,
        userRole: userProfile.role,
        action: AuditAction.bookingUpdated,
        resourceType: 'booking',
        resourceId: bookingId,
        details: {
          ...updateData,
          'previousStatus': booking.status.name,
        },
      );
    }
  }

  // Check for conflicting bookings (overlapping dates for the same room)
  Future<List<Booking>> getConflictingBookings({
    required String roomId,
    required DateTime checkIn,
    required DateTime checkOut,
    String? excludeBookingId,
  }) async {
    final snapshot = await _firestore
        .collection(_bookingsCollection)
        .where('roomId', isEqualTo: roomId)
        .where('status', whereIn: [BookingStatus.confirmed.name, BookingStatus.pending.name])
        .get();

    final bookings = snapshot.docs
        .map((doc) => Booking.fromMap(doc.id, Map<String, dynamic>.from(doc.data() as Map)))
        .where((booking) {
          if (excludeBookingId != null && booking.id == excludeBookingId) {
            return false;
          }
          // Check if dates overlap
          return (booking.checkIn.isBefore(checkOut) && booking.checkOut.isAfter(checkIn));
        })
        .toList();

    return bookings;
  }

  // Accept a booking (admin action)
  Future<void> acceptBooking({
    required String bookingId,
    required String callerUserId,
    bool checkConflicts = true,
  }) async {
    final callerProfile = await _userService.getUserProfile(callerUserId);
    if (callerProfile == null || !RoleBasedAccessControl.userHasPermission(callerProfile, Permission.viewBookings)) {
      throw Exception('Unauthorized: caller does not have permission to accept bookings.');
    }

    final doc = await _firestore.collection(_bookingsCollection).doc(bookingId).get();
    if (!doc.exists) {
      throw Exception('Booking not found');
    }

    final booking = Booking.fromMap(doc.id, Map<String, dynamic>.from(doc.data() as Map));
    
    if (booking.status != BookingStatus.pending) {
      throw Exception('Only pending bookings can be accepted');
    }

    // Check for conflicts if requested
    if (checkConflicts) {
      final conflicts = await getConflictingBookings(
        roomId: booking.roomId,
        checkIn: booking.checkIn,
        checkOut: booking.checkOut,
        excludeBookingId: bookingId,
      );
      
      if (conflicts.isNotEmpty) {
        throw Exception('Conflict detected: ${conflicts.length} overlapping booking(s) found. Please resolve conflicts first.');
      }
    }

    await _firestore.collection(_bookingsCollection).doc(bookingId).update({
      'status': BookingStatus.confirmed.name,
    });

    // Log audit trail
    await _auditTrail.logAction(
      userId: callerUserId,
      userEmail: callerProfile.email,
      userRole: callerProfile.role,
      action: AuditAction.bookingUpdated,
      resourceType: 'booking',
      resourceId: bookingId,
      details: {
        'action': 'accepted',
        'roomId': booking.roomId,
        'roomName': booking.roomName,
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

  // Reject a booking (admin action)
  Future<void> rejectBooking({
    required String bookingId,
    required String callerUserId,
    String? reason,
  }) async {
    final callerProfile = await _userService.getUserProfile(callerUserId);
    if (callerProfile == null || !RoleBasedAccessControl.userHasPermission(callerProfile, Permission.viewBookings)) {
      throw Exception('Unauthorized: caller does not have permission to reject bookings.');
    }

    final doc = await _firestore.collection(_bookingsCollection).doc(bookingId).get();
    if (!doc.exists) {
      throw Exception('Booking not found');
    }

    final booking = Booking.fromMap(doc.id, Map<String, dynamic>.from(doc.data() as Map));
    
    if (booking.status != BookingStatus.pending) {
      throw Exception('Only pending bookings can be rejected');
    }

    await _firestore.collection(_bookingsCollection).doc(bookingId).update({
      'status': BookingStatus.rejected.name,
    });

    // Log audit trail
    await _auditTrail.logAction(
      userId: callerUserId,
      userEmail: callerProfile.email,
      userRole: callerProfile.role,
      action: AuditAction.bookingUpdated,
      resourceType: 'booking',
      resourceId: bookingId,
      details: {
        'action': 'rejected',
        'reason': reason,
        'roomId': booking.roomId,
        'roomName': booking.roomName,
      },
    );

    // Notify user
    await _notificationService.notifyUserBookingRejected(
      userId: booking.userId,
      bookingId: bookingId,
      roomName: booking.roomName,
      checkIn: booking.checkIn,
      checkOut: booking.checkOut,
      reason: reason,
    );
  }

  // Assign a room to an existing booking (used by receptionists/staff)
  Future<void> assignRoomToBooking({
    required String bookingId,
    required String roomId,
    required String roomName,
    required String callerUserId,
  }) async {
    // Service-level permission guard: only check if caller has assignRoom permission
    final callerProfile = await _userService.getUserProfile(callerUserId);
    if (callerProfile == null || !RoleBasedAccessControl.userHasPermission(callerProfile, Permission.assignRoom)) {
      throw Exception('Unauthorized: caller does not have permission to assign rooms.');
    }
    await _firestore.collection(_bookingsCollection).doc(bookingId).update({
      'roomId': roomId,
      'roomName': roomName,
      'status': BookingStatus.confirmed.name,
    });

    final userProfile = await _userService.getUserProfile(callerUserId);
    if (userProfile != null) {
      await _auditTrail.logAction(
        userId: callerUserId,
        userEmail: userProfile.email,
        userRole: userProfile.role,
        action: AuditAction.bookingUpdated,
        resourceType: 'booking',
        resourceId: bookingId,
        details: {
          'roomId': roomId,
          'roomName': roomName,
        },
      );
      await _notificationService.createAdminBookingNotification(
        bookingId: bookingId,
        roomName: roomName,
        userEmail: userProfile.email,
        checkIn: DateTime.now(),
        checkOut: DateTime.now(),
        total: 0.0,
      );
    }
  }

  // Generate a simple receipt map for a booking
  Future<Map<String, dynamic>?> generateReceiptForBooking(String bookingId, {required String callerUserId}) async {
    // Service-level permission guard
    final callerProfile = await _userService.getUserProfile(callerUserId);
    if (callerProfile == null || !RoleBasedAccessControl.userHasPermission(callerProfile, Permission.generateReceipt)) {
      throw Exception('Unauthorized: caller does not have permission to generate receipts.');
    }
    final doc = await _firestore.collection(_bookingsCollection).doc(bookingId).get();
    if (!doc.exists) return null;

    final booking = Booking.fromMap(doc.id, Map<String, dynamic>.from(doc.data() as Map));
    final receipt = {
      'receiptId': 'RCPT-${booking.id}',
      'bookingId': booking.id,
      'guestName': booking.userId,
      'roomName': booking.roomName,
      'checkIn': booking.checkIn.toIso8601String(),
      'checkOut': booking.checkOut.toIso8601String(),
      'total': booking.total,
      'generatedAt': DateTime.now().toIso8601String(),
    };
    return receipt;
  }

  // Force initialize rooms - updates rooms while preserving availability status
  Future<void> forceInitializeRooms() async {
    // Initialize rooms without deleting existing ones
    await initializeSampleRooms();
  }

  // Initialize sample rooms - preserves existing availability status
  Future<void> initializeSampleRooms() async {
    final sampleRooms = [
      Room(
        id: 'room1',
        name: 'Poolside Villa',
        description: 'Luxurious villa with direct pool access and stunning resort views. Features a private terrace overlooking the infinity pool and tropical gardens. Perfect for couples seeking a romantic getaway.',
        price: 349.99,
        capacity: 2,
        amenities: ['WiFi', 'TV', 'AC', 'Mini Bar', 'Pool Access', 'Private Terrace', 'Room Service'],
        imageUrl: 'https://images.unsplash.com/photo-1571896349842-33c89424de2d?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        isAvailable: true,
      ),
      Room(
        id: 'room2',
        name: 'Ocean View Suite',
        description: 'Spacious suite with breathtaking ocean views and modern amenities. Wake up to the sound of waves and enjoy stunning sunsets from your private balcony. Includes premium bedding and luxury bathroom.',
        price: 299.99,
        capacity: 2,
        amenities: ['WiFi', 'TV', 'AC', 'Ocean View', 'Balcony', 'Mini Bar', 'Room Service'],
        imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        isAvailable: true,
      ),
      Room(
        id: 'room3',
        name: 'Infinity Pool Penthouse',
        description: 'Exclusive penthouse with private infinity pool overlooking the resort. Features a spacious living area, fully equipped kitchen, and premium furnishings. Ideal for families or groups seeking ultimate luxury.',
        price: 599.99,
        capacity: 4,
        amenities: ['WiFi', 'TV', 'AC', 'Private Pool', 'Kitchen', 'Balcony', 'Living Room', 'Premium Bedding'],
        imageUrl: 'https://images.unsplash.com/photo-1611892440504-42a792e24d32?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        isAvailable: true,
      ),
      Room(
        id: 'room4',
        name: 'Tropical Garden Bungalow',
        description: 'Charming bungalow nestled in lush tropical gardens with pool access. Features traditional design with modern comforts. Perfect for those seeking tranquility and natural beauty.',
        price: 199.99,
        capacity: 2,
        amenities: ['WiFi', 'TV', 'AC', 'Garden View', 'Pool Access', 'Private Entrance', 'Outdoor Seating'],
        imageUrl: 'https://images.unsplash.com/photo-1564501049412-61c2a3083791?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        isAvailable: true,
      ),
      Room(
        id: 'room5',
        name: 'Luxury Pool Suite',
        description: 'Elegant suite with direct access to the resort\'s main pool area. Features contemporary design, premium amenities, and stunning pool views. Includes complimentary breakfast and poolside service.',
        price: 249.99,
        capacity: 2,
        amenities: ['WiFi', 'TV', 'AC', 'Pool View', 'Pool Access', 'Breakfast Included', 'Room Service', 'Mini Bar'],
        imageUrl: 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        isAvailable: true,
      ),
      Room(
        id: 'room6',
        name: 'Family Pool Villa',
        description: 'Spacious family villa with private pool and multiple bedrooms. Perfect for families with children. Features a fully equipped kitchen, living area, and direct pool access. Includes family-friendly amenities.',
        price: 449.99,
        capacity: 6,
        amenities: ['WiFi', 'TV', 'AC', 'Private Pool', 'Kitchen', 'Multiple Bedrooms', 'Living Room', 'Garden', 'Family Friendly'],
        imageUrl: 'https://images.unsplash.com/photo-1602343168117-bb8ffe3e2e9f?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        isAvailable: true,
      ),
      Room(
        id: 'room7',
        name: 'Beachfront Deluxe',
        description: 'Premium beachfront room with stunning ocean and pool views. Steps away from the beach and resort pool. Features modern design, premium bedding, and luxury bathroom with ocean view.',
        price: 279.99,
        capacity: 2,
        amenities: ['WiFi', 'TV', 'AC', 'Beach Access', 'Pool View', 'Ocean View', 'Premium Bedding', 'Luxury Bathroom'],
        imageUrl: 'https://images.unsplash.com/photo-1596394516093-501ba68a0ba6?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        isAvailable: true,
      ),
    ];

    // Create only missing rooms - preserve all existing room data
    for (final room in sampleRooms) {
      try {
        // Check if room already exists
        final roomDoc = await _firestore.collection(_roomsCollection).doc(room.id).get();
        
        if (roomDoc.exists) {
          // Room exists - skip updating to preserve all custom changes (name, description, price, etc.)
          debugPrint('Room ${room.id} already exists - skipping to preserve custom data');
        } else {
          // Room doesn't exist - create it with default data
          await _firestore.collection(_roomsCollection).doc(room.id).set(room.toMap());
          debugPrint('Created room: ${room.name}');
        }
      } catch (e) {
        debugPrint('Error creating room ${room.id}: $e');
      }
    }
    debugPrint('Total rooms processed: ${sampleRooms.length}');
  }
}
