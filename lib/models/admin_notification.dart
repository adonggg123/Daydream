enum AdminNotificationType {
  bookingCreated,
  bookingUpdated,
  bookingCancelled,
  paymentProcessed,
  system,
}

class AdminNotification {
  final String id;
  final String title;
  final String message;
  final AdminNotificationType type;
  final String? bookingId;
  final String? userId;
  final String? userEmail;
  final DateTime createdAt;
  final bool isRead;

  AdminNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.bookingId,
    this.userId,
    this.userEmail,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'type': type.name,
      'bookingId': bookingId,
      'userId': userId,
      'userEmail': userEmail,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory AdminNotification.fromMap(String id, Map<String, dynamic> map) {
    return AdminNotification(
      id: id,
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: AdminNotificationType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => AdminNotificationType.system,
      ),
      bookingId: map['bookingId'],
      userId: map['userId'],
      userEmail: map['userEmail'],
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      isRead: map['isRead'] ?? false,
    );
  }
}


