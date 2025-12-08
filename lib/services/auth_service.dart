import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/foundation.dart';
import 'user_service.dart';
import 'audit_trail_service.dart';
import '../models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final UserService _userService = UserService();
  final AuditTrailService _auditTrail = AuditTrailService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Best-effort: update profile and log audit, but don't fail login if this breaks
      try {
        final user = userCredential.user;
        if (user != null) {
          await _userService.createOrUpdateUserProfile(
            userId: user.uid,
            email: user.email ?? email,
            displayName: user.displayName,
            photoUrl: user.photoURL,
          );

          final userProfile = await _userService.getUserProfile(user.uid);
          if (userProfile != null) {
            await _auditTrail.logAction(
              userId: user.uid,
              userEmail: user.email ?? email,
              userRole: userProfile.role,
              action: AuditAction.userLogin,
              resourceType: 'user',
              resourceId: user.uid,
            );
          }
        }
      } catch (e) {
        // Don't block login on audit/profile errors
        // ignore: avoid_print
        print('Non-fatal error updating user profile/audit on login: $e');
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Register with email and password
  Future<UserCredential?> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Best-effort: create profile and log audit, but don't fail registration if this breaks
      try {
        final user = userCredential.user;
        if (user != null) {
          // Check if this will be the first admin
          final hasAdmin = await _userService.hasAnyAdmin();

          await _userService.createOrUpdateUserProfile(
            userId: user.uid,
            email: user.email ?? email,
            displayName: user.displayName,
            photoUrl: user.photoURL,
            // role will be determined automatically (first user becomes admin)
          );

          // Get the actual role that was assigned
          final userProfile = await _userService.getUserProfile(user.uid);
          final assignedRole = userProfile?.role ?? UserRole.guest;

          await _auditTrail.logAction(
            userId: user.uid,
            userEmail: user.email ?? email,
            userRole: assignedRole,
            action: AuditAction.userRegister,
            resourceType: 'user',
            resourceId: user.uid,
            details: hasAdmin ? null : {'firstUser': true, 'autoAdmin': true},
          );
        }
      } catch (e) {
        // Don't block registration on audit/profile errors
        // ignore: avoid_print
        print('Non-fatal error creating user profile/audit on register: $e');
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      
      // Update user profile and log audit
      final user = userCredential.user;
      if (user != null) {
        await _userService.createOrUpdateUserProfile(
          userId: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          photoUrl: user.photoURL,
        );
        
        final userProfile = await _userService.getUserProfile(user.uid);
        if (userProfile != null) {
          await _auditTrail.logAction(
            userId: user.uid,
            userEmail: user.email ?? '',
            userRole: userProfile.role,
            action: AuditAction.userLogin,
            resourceType: 'user',
            resourceId: user.uid,
          );
        }
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error signing in with Google: ${e.toString()}';
    }
  }

  // Sign in with Facebook
  Future<UserCredential?> signInWithFacebook() async {
    try {
      // Trigger the sign-in flow
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status != LoginStatus.success) {
        throw 'Facebook sign-in was cancelled or failed.';
      }

      // Create a credential from the access token
      final OAuthCredential facebookAuthCredential =
          FacebookAuthProvider.credential(result.accessToken!.tokenString);

      // Sign in to Firebase with the Facebook credential
      final userCredential = await _auth.signInWithCredential(facebookAuthCredential);
      
      // Update user profile and log audit
      final user = userCredential.user;
      if (user != null) {
        await _userService.createOrUpdateUserProfile(
          userId: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          photoUrl: user.photoURL,
        );
        
        final userProfile = await _userService.getUserProfile(user.uid);
        if (userProfile != null) {
          await _auditTrail.logAction(
            userId: user.uid,
            userEmail: user.email ?? '',
            userRole: userProfile.role,
            action: AuditAction.userLogin,
            resourceType: 'user',
            resourceId: user.uid,
          );
        }
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error signing in with Facebook: ${e.toString()}';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      final user = _auth.currentUser;
      final userEmail = user?.email ?? '';
      final userId = user?.uid ?? '';
      
      // Get user profile for audit log
      AppUser? userProfile;
      if (userId.isNotEmpty) {
        userProfile = await _userService.getUserProfile(userId);
      }
      
      // Sign out from Firebase Auth (always try this)
      await _auth.signOut();
      
      // Log audit trail
      if (userId.isNotEmpty && userProfile != null) {
        await _auditTrail.logAction(
          userId: userId,
          userEmail: userEmail,
          userRole: userProfile.role,
          action: AuditAction.userLogout,
          resourceType: 'user',
          resourceId: userId,
        );
      }
      
      // Sign out from Google (ignore errors if not signed in with Google)
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        // Ignore Google sign-out errors
      }
      
      // Sign out from Facebook (ignore errors if not signed in with Facebook)
      try {
        await FacebookAuth.instance.logOut();
      } catch (e) {
        // Ignore Facebook sign-out errors
      }
    } catch (e) {
      // If Firebase sign-out fails, still try to sign out from other providers
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      
      try {
        await FacebookAuth.instance.logOut();
      } catch (_) {}
      
      // Re-throw the original error if Firebase sign-out failed
      throw 'Error signing out. Please try again.';
    }
  }

  // Update password
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw 'User not authenticated';
      }

      if (user.email == null) {
        throw 'Email not found. Cannot change password.';
      }

      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      
      await user.reauthenticateWithCredential(credential);
      
      // Update password
      await user.updatePassword(newPassword);
      
      // Log audit trail (best-effort)
      try {
        final userProfile = await _userService.getUserProfile(user.uid);
        if (userProfile != null) {
          await _auditTrail.logAction(
            userId: user.uid,
            userEmail: user.email ?? '',
            userRole: userProfile.role,
            action: AuditAction.passwordReset,
            resourceType: 'user',
            resourceId: user.uid,
          );
        }
      } catch (e) {
        // Don't fail password update on audit error
        debugPrint('Error logging password change audit: $e');
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw e.toString();
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }
}
