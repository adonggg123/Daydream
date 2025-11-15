enum EventType {
  none,
  birthday,
  wedding,
  anniversary,
  corporate,
  graduation,
  other,
}

enum BookingStatus {
  pending,
  confirmed,
  cancelled,
  completed,
}

class Booking {
  final String id;
  final String userId;
  final String roomId;
  final String roomName;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;
  final EventType eventType;
  final String? eventDetails;
  final String? specialRequests;
  final double roomPrice;
  final double eventFee;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final BookingStatus status;
  final DateTime timestamp;
  final String? paymentId;
  final bool isPaid;

  Booking({
    required this.id,
    required this.userId,
    required this.roomId,
    required this.roomName,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    this.eventType = EventType.none,
    this.eventDetails,
    this.specialRequests,
    required this.roomPrice,
    this.eventFee = 0.0,
    required this.subtotal,
    required this.tax,
    this.discount = 0.0,
    required this.total,
    this.status = BookingStatus.pending,
    required this.timestamp,
    this.paymentId,
    this.isPaid = false,
  });

  // Calculate number of nights
  int get numberOfNights {
    return checkOut.difference(checkIn).inDays;
  }

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'roomId': roomId,
      'roomName': roomName,
      'checkIn': checkIn.toIso8601String(),
      'checkOut': checkOut.toIso8601String(),
      'guests': guests,
      'eventType': eventType.name,
      'eventDetails': eventDetails,
      'specialRequests': specialRequests,
      'roomPrice': roomPrice,
      'eventFee': eventFee,
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'total': total,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'paymentId': paymentId,
      'isPaid': isPaid,
      'numberOfNights': numberOfNights,
    };
  }

  // Create from Firestore document
  factory Booking.fromMap(String id, Map<String, dynamic> map) {
    return Booking(
      id: id,
      userId: map['userId'] ?? '',
      roomId: map['roomId'] ?? '',
      roomName: map['roomName'] ?? '',
      checkIn: DateTime.parse(map['checkIn'] ?? DateTime.now().toIso8601String()),
      checkOut: DateTime.parse(map['checkOut'] ?? DateTime.now().toIso8601String()),
      guests: map['guests'] ?? 1,
      eventType: EventType.values.firstWhere(
        (e) => e.name == map['eventType'],
        orElse: () => EventType.none,
      ),
      eventDetails: map['eventDetails'],
      specialRequests: map['specialRequests'],
      roomPrice: (map['roomPrice'] ?? 0.0).toDouble(),
      eventFee: (map['eventFee'] ?? 0.0).toDouble(),
      subtotal: (map['subtotal'] ?? 0.0).toDouble(),
      tax: (map['tax'] ?? 0.0).toDouble(),
      discount: (map['discount'] ?? 0.0).toDouble(),
      total: (map['total'] ?? 0.0).toDouble(),
      status: BookingStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => BookingStatus.pending,
      ),
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      paymentId: map['paymentId'],
      isPaid: map['isPaid'] ?? false,
    );
  }

  // Get event type display name (static method for use in widgets)
  static String getEventTypeDisplay(EventType eventType) {
    switch (eventType) {
      case EventType.none:
        return 'No Event';
      case EventType.birthday:
        return 'Birthday';
      case EventType.wedding:
        return 'Wedding';
      case EventType.anniversary:
        return 'Anniversary';
      case EventType.corporate:
        return 'Corporate';
      case EventType.graduation:
        return 'Graduation';
      case EventType.other:
        return 'Other Event';
    }
  }

  // Instance method
  String get eventTypeDisplay => Booking.getEventTypeDisplay(eventType);
}
