import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
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

  // Upload image to Firebase Storage
  Future<String> uploadRoomImage(File imageFile, String roomId) async {
    try {
      final String fileName = 'rooms/$roomId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage.ref().child(fileName);
      
      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow;
    }
  }

  // Delete image from Firebase Storage
  Future<void> deleteRoomImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty || !imageUrl.contains('firebasestorage')) {
        return; // Not a Firebase Storage URL, skip deletion
      }
      
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
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
      return snapshot.docs
          .map((doc) => Room.fromMap(doc.id, doc.data()))
          .toList();
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
    if (callerUserId != null) {
      final callerProfile = await _userService.getUserProfile(callerUserId);
      if (callerProfile == null || !RoleBasedAccessControl.userHasPermission(callerProfile, Permission.cancelAllBookings)) {
        throw Exception('Unauthorized: caller does not have permission to cancel bookings.');
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

    // Update/create all rooms while preserving existing availability status
    for (final room in sampleRooms) {
      try {
        // Check if room already exists
        final roomDoc = await _firestore.collection(_roomsCollection).doc(room.id).get();
        
        if (roomDoc.exists) {
          // Room exists - preserve the existing isAvailable status
          final existingData = roomDoc.data();
          final existingIsAvailable = existingData?['isAvailable'] ?? true;
          
          // Update room data but preserve availability status
          final roomData = room.toMap();
          roomData['isAvailable'] = existingIsAvailable;
          
          await _firestore.collection(_roomsCollection).doc(room.id).update(roomData);
          debugPrint('Updated room: ${room.name} (preserved availability: $existingIsAvailable)');
        } else {
          // Room doesn't exist - create it with default availability
          await _firestore.collection(_roomsCollection).doc(room.id).set(room.toMap());
          debugPrint('Created room: ${room.name}');
        }
      } catch (e) {
        debugPrint('Error updating/creating room ${room.id}: $e');
      }
    }
    debugPrint('Total rooms processed: ${sampleRooms.length}');
  }
}
