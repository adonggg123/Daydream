enum UserRole {
  guest,
  staff,
  receptionist,
  admin,
}

class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.role = UserRole.guest,
    required this.createdAt,
    this.lastLoginAt,
    this.isActive = true,
    this.metadata,
  });

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role.name,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'isActive': isActive,
      'metadata': metadata ?? {},
    };
  }

  // Create from Firestore document
  factory AppUser.fromMap(String id, Map<String, dynamic> map) {
    return AppUser(
      id: id,
      email: map['email'] ?? '',
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
      role: UserRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => UserRole.guest,
      ),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      lastLoginAt: map['lastLoginAt'] != null
          ? DateTime.parse(map['lastLoginAt'])
          : null,
      isActive: map['isActive'] ?? true,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  // Check if user is admin
  bool get isAdmin => role == UserRole.admin;

  // Check if user is staff
  bool get isStaff => role == UserRole.staff;

  // Check if user is receptionist
  bool get isReceptionist => role == UserRole.receptionist;

  // Check if user is guest
  bool get isGuest => role == UserRole.guest;

  // Check if user has admin or staff or receptionist privileges
  bool get isStaffOrAdmin =>
      role == UserRole.admin || role == UserRole.staff || role == UserRole.receptionist;

  // Copy with method for updates
  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    UserRole? role,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }
}

