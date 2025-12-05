import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/post.dart';
import 'audit_trail_service.dart';
import 'user_service.dart';
import 'notification_service.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'posts';
  final AuditTrailService _auditTrail = AuditTrailService();
  final UserService _userService = UserService();
  final NotificationService _notificationService = NotificationService();

  // Create a new post
  Future<Post> createPost({
    required String userId,
    required String userEmail,
    required String content,
  }) async {
    final postRef = _firestore.collection(_collection).doc();
    final post = Post(
      id: postRef.id,
      userId: userId,
      userEmail: userEmail,
      content: content,
      timestamp: DateTime.now(),
    );

    await postRef.set(post.toMap());
    
    // Log audit trail
    final userProfile = await _userService.getUserProfile(userId);
    if (userProfile != null) {
      await _auditTrail.logAction(
        userId: userId,
        userEmail: userEmail,
        userRole: userProfile.role,
        action: AuditAction.postCreated,
        resourceType: 'post',
        resourceId: postRef.id,
      );
    }
    
    return post;
  }

  // Get all posts
  Stream<List<Post>> getPosts() {
    return _firestore
        .collection(_collection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Post.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Like or unlike a post
  Future<void> toggleLike(String postId, String userId) async {
    final postRef = _firestore.collection(_collection).doc(postId);
    final postDoc = await postRef.get();

    if (!postDoc.exists) return;

    final post = Post.fromMap(postId, postDoc.data()!);
    final List<String> likedBy = List<String>.from(post.likedBy);
    final bool wasLiked = likedBy.contains(userId);

    if (wasLiked) {
      likedBy.remove(userId);
    } else {
      likedBy.add(userId);
    }

    await postRef.update({'likedBy': likedBy});
    
    // Log audit trail
    final userProfile = await _userService.getUserProfile(userId);
    if (userProfile != null) {
      await _auditTrail.logAction(
        userId: userId,
        userEmail: userProfile.email,
        userRole: userProfile.role,
        action: AuditAction.postLiked,
        resourceType: 'post',
        resourceId: postId,
      );
      
      // Send notification to post owner if post was liked (not unliked)
      if (!wasLiked && post.userId != userId) {
        try {
          await _notificationService.notifyPostLiked(
            postOwnerId: post.userId,
            postId: postId,
            likerEmail: userProfile.email,
            postContent: post.content,
          );
        } catch (e) {
          debugPrint('Error sending like notification: $e');
        }
      }
    }
  }

  // Add a comment to a post
  Future<void> addComment({
    required String postId,
    required String userId,
    required String userEmail,
    required String content,
  }) async {
    final postRef = _firestore.collection(_collection).doc(postId);
    final postDoc = await postRef.get();

    if (!postDoc.exists) return;

    final data = postDoc.data()!;
    final existingComments = data['comments'] as List<dynamic>? ?? [];
    final postOwnerId = data['userId'] as String?;
    final postContent = data['content'] as String? ?? '';
    
    final newComment = {
      'id': '${DateTime.now().millisecondsSinceEpoch}_$userId',
      'userId': userId,
      'userEmail': userEmail,
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
    };

    existingComments.add(newComment);
    await postRef.update({'comments': existingComments});
    
    // Log audit trail
    final userProfile = await _userService.getUserProfile(userId);
    if (userProfile != null) {
      await _auditTrail.logAction(
        userId: userId,
        userEmail: userEmail,
        userRole: userProfile.role,
        action: AuditAction.commentAdded,
        resourceType: 'post',
        resourceId: postId,
      );
      
      // Send notification to post owner if commenter is not the post owner
      if (postOwnerId != null && postOwnerId != userId) {
        try {
          await _notificationService.notifyPostCommented(
            postOwnerId: postOwnerId,
            postId: postId,
            commenterEmail: userEmail,
            commentContent: content,
            postContent: postContent,
          );
        } catch (e) {
          debugPrint('Error sending comment notification: $e');
        }
      }
    }
  }

  // Delete a post
  Future<void> deletePost(String postId, String userId) async {
    final postRef = _firestore.collection(_collection).doc(postId);
    final postDoc = await postRef.get();

    if (!postDoc.exists) return;

    final post = Post.fromMap(postId, postDoc.data()!);
    if (post.userId == userId) {
      await postRef.delete();
      
      // Log audit trail
      final userProfile = await _userService.getUserProfile(userId);
      if (userProfile != null) {
        await _auditTrail.logAction(
          userId: userId,
          userEmail: userProfile.email,
          userRole: userProfile.role,
          action: AuditAction.postDeleted,
          resourceType: 'post',
          resourceId: postId,
        );
      }
    }
  }
}
