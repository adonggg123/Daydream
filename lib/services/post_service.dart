import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'posts';

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

    if (likedBy.contains(userId)) {
      likedBy.remove(userId);
    } else {
      likedBy.add(userId);
    }

    await postRef.update({'likedBy': likedBy});
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
    
    final newComment = {
      'id': '${DateTime.now().millisecondsSinceEpoch}_$userId',
      'userId': userId,
      'userEmail': userEmail,
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
    };

    existingComments.add(newComment);
    await postRef.update({'comments': existingComments});
  }

  // Delete a post
  Future<void> deletePost(String postId, String userId) async {
    final postRef = _firestore.collection(_collection).doc(postId);
    final postDoc = await postRef.get();

    if (!postDoc.exists) return;

    final post = Post.fromMap(postId, postDoc.data()!);
    if (post.userId == userId) {
      await postRef.delete();
    }
  }
}
