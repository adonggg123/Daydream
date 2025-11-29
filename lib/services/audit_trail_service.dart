import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

enum AuditAction {
  // Authentication actions
  userLogin,
  userLogout,
  userRegister,
  passwordReset,
  
  // Booking actions
  bookingCreated,
  bookingUpdated,
  bookingCancelled,
  bookingConfirmed,
  bookingPaymentProcessed,
  
  // Room actions
  roomCreated,
  roomUpdated,
  roomDeleted,
  roomAvailabilityChanged,
  
  // User management actions
  userRoleChanged,
  userActivated,
  userDeactivated,
  userProfileUpdated,
  userDeleted,
  
  // Post/Social actions
  postCreated,
  postUpdated,
  postDeleted,
  postLiked,
  commentAdded,
  commentDeleted,
  
  // System actions
  systemSettingsUpdated,
  auditTrailViewed,
  reportGenerated,
  dataExported,
}

class AuditLog {
  final String id;
  final String userId;
  final String userEmail;
  final UserRole userRole;
  final AuditAction action;
  final String resourceType; // e.g., 'booking', 'room', 'user'
  final String? resourceId;
  final Map<String, dynamic>? details;
  final DateTime timestamp;
  final String? ipAddress;
  final String? userAgent;

  AuditLog({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userRole,
    required this.action,
    required this.resourceType,
    this.resourceId,
    this.details,
    required this.timestamp,
    this.ipAddress,
    this.userAgent,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'userRole': userRole.name,
      'action': action.name,
      'resourceType': resourceType,
      'resourceId': resourceId,
      'details': details ?? {},
      'timestamp': timestamp.toIso8601String(),
      'ipAddress': ipAddress,
      'userAgent': userAgent,
    };
  }

  factory AuditLog.fromMap(String id, Map<String, dynamic> map) {
    return AuditLog(
      id: id,
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      userRole: UserRole.values.firstWhere(
        (r) => r.name == map['userRole'],
        orElse: () => UserRole.guest,
      ),
      action: AuditAction.values.firstWhere(
        (a) => a.name == map['action'],
        orElse: () => AuditAction.userLogin,
      ),
      resourceType: map['resourceType'] ?? '',
      resourceId: map['resourceId'],
      details: map['details'] != null 
          ? Map<String, dynamic>.from(map['details'] as Map)
          : null,
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      ipAddress: map['ipAddress'],
      userAgent: map['userAgent'],
    );
  }
}

class AuditTrailService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _auditCollection = 'audit_logs';

  // Log an action
  Future<void> logAction({
    required String userId,
    required String userEmail,
    required UserRole userRole,
    required AuditAction action,
    required String resourceType,
    String? resourceId,
    Map<String, dynamic>? details,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      final logRef = _firestore.collection(_auditCollection).doc();
      
      final auditLog = AuditLog(
        id: logRef.id,
        userId: userId,
        userEmail: userEmail,
        userRole: userRole,
        action: action,
        resourceType: resourceType,
        resourceId: resourceId,
        details: details,
        timestamp: DateTime.now(),
        ipAddress: ipAddress,
        userAgent: userAgent,
      );

      await logRef.set(auditLog.toMap());
    } catch (e) {
      // Log error but don't throw - audit trail failures shouldn't break the app
      print('Error logging audit trail: $e');
    }
  }

  // Get audit logs with filters
  Stream<List<AuditLog>> getAuditLogs({
    String? userId,
    AuditAction? action,
    String? resourceType,
    String? resourceId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) {
    Query query = _firestore.collection(_auditCollection);

    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }

    if (action != null) {
      query = query.where('action', isEqualTo: action.name);
    }

    if (resourceType != null) {
      query = query.where('resourceType', isEqualTo: resourceType);
    }

    if (resourceId != null) {
      query = query.where('resourceId', isEqualTo: resourceId);
    }

    if (startDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: startDate.toIso8601String());
    }

    if (endDate != null) {
      query = query.where('timestamp', isLessThanOrEqualTo: endDate.toIso8601String());
    }

    query = query.orderBy('timestamp', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AuditLog.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Get audit logs for a specific resource
  Future<List<AuditLog>> getResourceAuditLogs(
    String resourceType,
    String resourceId,
  ) async {
    final snapshot = await _firestore
        .collection(_auditCollection)
        .where('resourceType', isEqualTo: resourceType)
        .where('resourceId', isEqualTo: resourceId)
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => AuditLog.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Get user activity logs
  Stream<List<AuditLog>> getUserActivityLogs(String userId) {
    return _firestore
        .collection(_auditCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AuditLog.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // Delete old audit logs (admin only - for cleanup)
  Future<void> deleteOldLogs(DateTime beforeDate) async {
    final snapshot = await _firestore
        .collection(_auditCollection)
        .where('timestamp', isLessThan: beforeDate.toIso8601String())
        .get();

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

