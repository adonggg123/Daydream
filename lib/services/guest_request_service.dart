import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_service.dart';
import 'role_based_access_control.dart';

class GuestRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'guest_requests';

  Future<String> createGuestRequest({
    required String userId,
    required String subject,
    required String description,
  }) async {
    final docRef = _firestore.collection(_collection).doc();
    final data = {
      'userId': userId,
      'subject': subject,
      'description': description,
      'status': 'open',
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await docRef.set(data);
    return docRef.id;
  }

  Future<void> updateGuestRequest({
    required String requestId,
    required String callerUserId,
    String? status,
    String? response,
    String? assignedToUserId,
  }) async {
    // Permission check
    final userService = UserService();
    final callerProfile = await userService.getUserProfile(callerUserId);
    if (callerProfile == null || !RoleBasedAccessControl.userHasPermission(callerProfile, Permission.manageGuestRequests)) {
      throw Exception('Unauthorized: caller does not have permission to manage guest requests.');
    }
    final updateData = <String, dynamic>{
      if (status != null) 'status': status,
      if (response != null) 'response': response,
      if (assignedToUserId != null) 'assignedTo': assignedToUserId,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    await _firestore.collection(_collection).doc(requestId).update(updateData);
  }

  Future<List<Map<String, dynamic>>> getRequestsForUser(String userId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        ...Map<String, dynamic>.from(doc.data() as Map)
      };
    }).toList();
  }

  Stream<List<Map<String, dynamic>>> streamAllRequests({required String callerUserId}) {
    final userService = UserService();
    // We'll lazily check the permission before streaming - return a stream that will throw if unauthorized
    return Stream.fromFuture(userService.getUserProfile(callerUserId)).asyncExpand((callerProfile) {
      if (callerProfile == null || !RoleBasedAccessControl.userHasPermission(callerProfile, Permission.manageGuestRequests)) {
        throw Exception('Unauthorized: caller does not have permission to view guest requests.');
      }

      final stream = _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) {
                return {
                  'id': doc.id,
                  ...Map<String, dynamic>.from(doc.data() as Map)
                };
              }).toList());

      return stream;
    });
  }
}
