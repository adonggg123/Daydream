class Post {
  final String id;
  final String userId;
  final String userEmail;
  final String content;
  final DateTime timestamp;
  final List<String> likedBy;
  final List<Comment> comments;

  Post({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.content,
    required this.timestamp,
    this.likedBy = const [],
    this.comments = const [],
  });

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'likedBy': likedBy,
      'comments': comments.map((comment) => comment.toMap()).toList(),
    };
  }

  // Create from Firestore document
  factory Post.fromMap(String id, Map<String, dynamic> map) {
    return Post(
      id: id,
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      content: map['content'] ?? '',
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      likedBy: List<String>.from(map['likedBy'] ?? []),
      comments: (map['comments'] as List<dynamic>?)
              ?.map((comment) => Comment.fromMap(comment as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  // Check if post is liked by user
  bool isLikedBy(String userId) {
    return likedBy.contains(userId);
  }

  // Get like count
  int get likeCount => likedBy.length;

  // Get comment count
  int get commentCount => comments.length;
}

class Comment {
  final String id;
  final String userId;
  final String userEmail;
  final String content;
  final DateTime timestamp;

  Comment({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.content,
    required this.timestamp,
  });

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Create from Firestore document
  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      content: map['content'] ?? '',
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}
