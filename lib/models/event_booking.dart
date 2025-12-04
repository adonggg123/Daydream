import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking.dart';

enum EventBookingStatus {
  pending,
  confirmed,
  rejected,
  cancelled,
}

class EventBooking {
  final String id;
  final String userId;
  final String userEmail;
  final EventType eventType;
  final DateTime eventDate;
  final int peopleCount;
  final String? notes;
  final EventBookingStatus status;
  final DateTime createdAt;

  EventBooking({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.eventType,
    required this.eventDate,
    required this.peopleCount,
    this.notes,
    this.status = EventBookingStatus.pending,
    required this.createdAt,
  });

  String get dateKey =>
      '${eventDate.year.toString().padLeft(4, '0')}-'
      '${eventDate.month.toString().padLeft(2, '0')}-'
      '${eventDate.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'eventType': eventType.name,
      'eventDate': Timestamp.fromDate(eventDate),
      'eventDateKey': dateKey,
      'peopleCount': peopleCount,
      'notes': notes,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static EventBooking fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return EventBooking(
      id: doc.id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      eventType: EventType.values.firstWhere(
        (e) => e.name == data['eventType'],
        orElse: () => EventType.other,
      ),
      eventDate: (data['eventDate'] as Timestamp).toDate(),
      peopleCount: data['peopleCount'] ?? 0,
      notes: data['notes'],
      status: EventBookingStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => EventBookingStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}


