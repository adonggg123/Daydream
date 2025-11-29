import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/room.dart';
import '../models/booking.dart';
import 'audit_trail_service.dart';
import 'user_service.dart';
import 'notification_service.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _roomsCollection = 'rooms';
  final String _bookingsCollection = 'bookings';
  final AuditTrailService _auditTrail = AuditTrailService();
  final UserService _userService = UserService();
  final NotificationService _notificationService = NotificationService();

  // Get all rooms
  Future<List<Room>> getAllRooms() async {
    final roomsSnapshot = await _firestore.collection(_roomsCollection).get();
    return roomsSnapshot.docs
        .map((doc) => Room.fromMap(doc.id, doc.data()))
        .where((room) => room.isAvailable)
        .toList();
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
          return Booking.fromMap(doc.id, doc.data());
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
  }) async {
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
  }) async {
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

  // Force initialize rooms - clears existing and creates fresh
  Future<void> forceInitializeRooms() async {
    try {
      // Delete all existing rooms first
      final existingRooms = await _firestore.collection(_roomsCollection).get();
      for (var doc in existingRooms.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Error clearing existing rooms: $e');
    }
    
    // Now create all rooms
    await initializeSampleRooms();
  }

  // Initialize sample rooms - always updates to ensure all rooms exist
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

    // Always update/create all rooms to ensure they exist with latest data
    for (final room in sampleRooms) {
      try {
        await _firestore.collection(_roomsCollection).doc(room.id).set(room.toMap());
        debugPrint('Created room: ${room.name}');
      } catch (e) {
        debugPrint('Error creating room ${room.id}: $e');
      }
    }
    debugPrint('Total rooms created: ${sampleRooms.length}');
  }
}
