import '../models/user.dart';

enum Permission {
  // Booking permissions
  viewBookings,
  createBooking,
  editOwnBooking,
  cancelOwnBooking,
  viewAllBookings,
  editAllBookings,
  cancelAllBookings,
  
  // Room permissions
  viewRooms,
  createRoom,
  editRoom,
  deleteRoom,
  
  // User management permissions
  viewUsers,
  editUsers,
  deleteUsers,
  changeUserRoles,
  
  // Post/Social permissions
  viewPosts,
  createPost,
  editOwnPost,
  deleteOwnPost,
  editAllPosts,
  deleteAllPosts,
  
  // System permissions
  viewAuditTrail,
  viewSystemSettings,
  editSystemSettings,
  viewReports,
}

class RoleBasedAccessControl {
  // Define permissions for each role
  static final Map<UserRole, Set<Permission>> _rolePermissions = {
    UserRole.guest: {
      Permission.viewBookings,
      Permission.createBooking,
      Permission.editOwnBooking,
      Permission.cancelOwnBooking,
      Permission.viewRooms,
      Permission.viewPosts,
      Permission.createPost,
      Permission.editOwnPost,
      Permission.deleteOwnPost,
    },
    UserRole.staff: {
      Permission.viewBookings,
      Permission.createBooking,
      Permission.editOwnBooking,
      Permission.cancelOwnBooking,
      Permission.viewAllBookings,
      Permission.editAllBookings,
      Permission.cancelAllBookings,
      Permission.viewRooms,
      Permission.createRoom,
      Permission.editRoom,
      Permission.viewUsers,
      Permission.viewPosts,
      Permission.createPost,
      Permission.editOwnPost,
      Permission.deleteOwnPost,
      Permission.editAllPosts,
      Permission.deleteAllPosts,
    },
    UserRole.admin: {
      // Admins have all permissions
      ...Permission.values.toSet(),
    },
  };

  // Check if a role has a specific permission
  static bool hasPermission(UserRole role, Permission permission) {
    return _rolePermissions[role]?.contains(permission) ?? false;
  }

  // Check if user has permission
  static bool userHasPermission(AppUser? user, Permission permission) {
    if (user == null || !user.isActive) return false;
    return hasPermission(user.role, permission);
  }

  // Check if user can perform action on resource
  static bool canPerformAction(
    AppUser? user,
    Permission permission, {
    String? resourceOwnerId,
  }) {
    if (user == null || !user.isActive) return false;

    // Admins can do everything
    if (user.isAdmin) return true;

    // Check basic permission
    if (!hasPermission(user.role, permission)) return false;

    // For own resource permissions, check ownership
    if (resourceOwnerId != null && user.id == resourceOwnerId) {
      return true;
    }

    // For staff/admin permissions that don't require ownership
    if (user.isStaffOrAdmin) {
      // Check if permission allows all resources
      switch (permission) {
        case Permission.viewAllBookings:
        case Permission.editAllBookings:
        case Permission.cancelAllBookings:
        case Permission.editAllPosts:
        case Permission.deleteAllPosts:
          return true;
        default:
          break;
      }
    }

    return false;
  }

  // Get all permissions for a role
  static Set<Permission> getRolePermissions(UserRole role) {
    return _rolePermissions[role] ?? {};
  }

  // Check if user can access admin features
  static bool canAccessAdminFeatures(AppUser? user) {
    return user?.isAdmin ?? false;
  }

  // Check if user can access staff features
  static bool canAccessStaffFeatures(AppUser? user) {
    return user?.isStaffOrAdmin ?? false;
  }
}

