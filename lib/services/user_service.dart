import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _usersCollection = 'users';

  // Get current user profile
  Future<AppUser?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    return getUserProfile(user.uid);
  }

  // Get user profile by ID
  Future<AppUser?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(userId).get();
      if (!doc.exists) return null;
      return AppUser.fromMap(doc.id, doc.data()!);
    } catch (e) {
      return null;
    }
  }

  // Stream user profile
  Stream<AppUser?> streamUserProfile(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromMap(doc.id, doc.data()!);
    });
  }

  // Check if any admin exists
  Future<bool> hasAnyAdmin() async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .where('role', isEqualTo: UserRole.admin.name)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Create or update user profile
  Future<void> createOrUpdateUserProfile({
    required String userId,
    required String email,
    String? displayName,
    String? photoUrl,
    UserRole? role,
  }) async {
    final userDoc = _firestore.collection(_usersCollection).doc(userId);
    final existingUser = await userDoc.get();

    if (existingUser.exists) {
      // Update existing user
      final updates = <String, dynamic>{
        'email': email,
        'lastLoginAt': DateTime.now().toIso8601String(),
      };
      
      if (displayName != null) updates['displayName'] = displayName;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      if (role != null) updates['role'] = role.name;

      await userDoc.update(updates);
    } else {
      // Create new user
      // Check if this is the first user - make them admin if no admin exists
      final hasAdmin = await hasAnyAdmin();
      final userRole = role ?? (hasAdmin ? UserRole.guest : UserRole.admin);
      
      final newUser = AppUser(
        id: userId,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        role: userRole,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isActive: true,
      );

      await userDoc.set(newUser.toMap());
    }
  }

  // Update user role (admin only)
  Future<void> updateUserRole(String userId, UserRole newRole) async {
    await _firestore.collection(_usersCollection).doc(userId).update({
      'role': newRole.name,
    });
  }

  // Update user active status
  Future<void> updateUserActiveStatus(String userId, bool isActive) async {
    await _firestore.collection(_usersCollection).doc(userId).update({
      'isActive': isActive,
    });
  }

  // Get all users (admin/staff only)
  Stream<List<AppUser>> getAllUsers() {
    return _firestore
        .collection(_usersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AppUser.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // Search users by email
  Future<List<AppUser>> searchUsersByEmail(String emailQuery) async {
    final snapshot = await _firestore
        .collection(_usersCollection)
        .where('email', isGreaterThanOrEqualTo: emailQuery)
        .where('email', isLessThanOrEqualTo: '$emailQuery\uf8ff')
        .get();

    return snapshot.docs
        .map((doc) => AppUser.fromMap(doc.id, doc.data()))
        .toList();
  }

  // Delete user profile
  Future<void> deleteUserProfile(String userId) async {
    await _firestore.collection(_usersCollection).doc(userId).delete();
  }
}

