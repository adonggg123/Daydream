  import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/booking_service.dart';
import '../services/event_booking_service.dart';
import '../services/cottage_service.dart';
import '../services/cottage_booking_service.dart';
import '../models/booking.dart';
import '../models/event_booking.dart';
import '../models/user.dart';
import 'login_page.dart';
import 'theme_constants.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    
    if (user == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: Text(
            'Please sign in to view your profile',
            style: AppTheme.bodyLarge,
          ),
        ),
      );
    }

    return StreamBuilder<AppUser?>(
      stream: _userService.streamUserProfile(user.uid),
      builder: (context, snapshot) {
        final userProfile = snapshot.data;
        final displayName = userProfile?.displayName ?? '';
        String userInitial;
        if (displayName.isNotEmpty) {
          userInitial = displayName[0].toUpperCase();
        } else {
          final email = user.email ?? '';
          userInitial = email.isNotEmpty ? email[0].toUpperCase() : 'U';
        }
        final userName = userProfile?.displayName ?? user.email?.split('@').first ?? 'Guest';
        final memberSince = _getMemberSince(user.metadata.creationTime);
        final photoUrl = userProfile?.photoUrl;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            elevation: 0,
            toolbarHeight: 70,
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: ClipOval(
                    child: Transform.scale(
                      scale: 1.43, // Scale to maintain 80x80 visual size (80/56 = 1.43)
                      child: Image.asset(
                      'assets/icons/LOGO2.png',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      )
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 20, bottom: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.cardDecoration.copyWith(
                      gradient: AppTheme.primaryGradient,
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () => _showEditProfileDialog(context),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                  gradient: photoUrl == null ? AppTheme.accentGradient : null,
                                  color: photoUrl != null ? Colors.transparent : null,
                                ),
                                child: photoUrl != null && photoUrl.isNotEmpty
                                    ? ClipOval(
                                        child: Image.network(
                                          photoUrl,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                gradient: AppTheme.accentGradient,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  userInitial,
                                                  style: const TextStyle(
                                                    fontSize: 36,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          userInitial,
                                          style: const TextStyle(
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                              ),
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email ?? 'No email provided',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Member since $memberSince',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    decoration: AppTheme.cardDecoration,
                    child: Column(
                      children: [
                        _buildMenuItem(
                          icon: Icons.person_outline,
                          title: 'Edit Profile',
                          subtitle: 'Update your personal information',
                          onTap: () => _showEditProfileDialog(context),
                        ),
                        _buildMenuItem(
                          icon: Icons.hotel,
                          title: 'Room Bookings',
                          subtitle: 'View and manage your room reservations',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MyBookingsPage(userId: user.uid),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.celebration,
                          title: 'Event Bookings',
                          subtitle: 'Manage your event bookings',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MyEventBookingsPage(userId: user.uid),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.home,
                          title: 'My Cottage Bookings',
                          subtitle: 'View and manage your cottage reservations',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MyCottageBookingsPage(userId: user.uid),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.favorite_outline,
                          title: 'Favorites',
                          subtitle: 'Your saved rooms and packages',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Favorites feature coming soon'),
                                backgroundColor: AppTheme.primaryColor,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.settings_outlined,
                          title: 'Settings',
                          subtitle: 'App preferences and notifications',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Settings feature coming soon'),
                                backgroundColor: AppTheme.primaryColor,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.help_outline,
                          title: 'Help & Support',
                          subtitle: 'Get help or contact support',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Help & Support feature coming soon'),
                                backgroundColor: AppTheme.primaryColor,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.logout,
                          title: 'Sign Out',
                          subtitle: 'Log out of your account',
                          color: AppTheme.errorColor,
                          onTap: () async {
                            try {
                              await _authService.signOut();
                              if (context.mounted) {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) => const LoginPage(),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString()),
                                    backgroundColor: AppTheme.errorColor,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Future<void> _handleSaveProfile({
    required BuildContext context,
    required BuildContext dialogContext,
    required TextEditingController usernameController,
    required TextEditingController currentPasswordController,
    required TextEditingController newPasswordController,
    required TextEditingController confirmPasswordController,
    File? selectedImage,
    String? currentPhotoUrl,
    required bool canChangePassword,
  }) async {
    // Validate username
    if (usernameController.text.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a username'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Validate password if any field is filled
    final hasCurrentPassword = currentPasswordController.text.isNotEmpty;
    final hasNewPassword = newPasswordController.text.isNotEmpty;
    final hasConfirmPassword = confirmPasswordController.text.isNotEmpty;

    if (canChangePassword && (hasCurrentPassword || hasNewPassword || hasConfirmPassword)) {
      if (!hasCurrentPassword || !hasNewPassword || !hasConfirmPassword) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please fill all password fields'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (newPasswordController.text.length < 6) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password must be at least 6 characters'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (newPasswordController.text != confirmPasswordController.text) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Passwords do not match'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    // Close dialog first
    if (Navigator.of(dialogContext).canPop()) {
      Navigator.of(dialogContext).pop();
    }
    
    // Wait for dialog to close
    await Future.delayed(const Duration(milliseconds: 200));
    
    if (!context.mounted) return;
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loadingContext) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Re-check user is authenticated
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User session expired. Please log in again.');
      }

      String? newPhotoUrl = currentPhotoUrl;

      // Step 1: Upload photo if selected
      if (selectedImage != null) {
        try {
          // Delete old photo if exists (non-blocking)
          if (currentPhotoUrl != null && currentPhotoUrl.isNotEmpty) {
            try {
              await _userService.deleteProfilePicture(currentPhotoUrl);
            } catch (e) {
              debugPrint('Warning: Could not delete old photo: $e');
              // Continue even if deletion fails
            }
          }
          
          // Upload new photo
          newPhotoUrl = await _userService.uploadProfilePicture(
            selectedImage,
            currentUser.uid,
          );
        } catch (e) {
          debugPrint('Error uploading photo: $e');
          throw Exception('Failed to upload photo: ${e.toString()}');
        }
      }

      // Step 2: Update password if provided
      if (canChangePassword && hasCurrentPassword && hasNewPassword && hasConfirmPassword) {
        try {
          await _authService.updatePassword(
            currentPassword: currentPasswordController.text,
            newPassword: newPasswordController.text,
          );
        } catch (e) {
          debugPrint('Error updating password: $e');
          // Re-throw with better message
          final errorStr = e.toString().toLowerCase();
          if (errorStr.contains('wrong password') || errorStr.contains('wrong-password')) {
            throw Exception('Current password is incorrect');
          } else if (errorStr.contains('weak-password')) {
            throw Exception('Password is too weak. Use at least 6 characters.');
          } else {
            throw Exception('Failed to update password: ${e.toString()}');
          }
        }
      }

      // Step 3: Update profile
      try {
        await _userService.updateUserProfile(
          userId: currentUser.uid,
          displayName: usernameController.text.trim(),
          photoUrl: newPhotoUrl,
        );
      } catch (e) {
        debugPrint('Error updating profile: $e');
        throw Exception('Failed to update profile: ${e.toString()}');
      }

      // Success - close loading and show message
      if (context.mounted) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(); // Close loading dialog
        }
        
        await Future.delayed(const Duration(milliseconds: 100));
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                (canChangePassword && hasCurrentPassword)
                  ? 'Profile and password updated successfully!'
                  : 'Profile updated successfully!',
              ),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error in _handleSaveProfile: $e');
      
      if (context.mounted) {
        // Close loading dialog
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        
        await Future.delayed(const Duration(milliseconds: 100));
        
        if (context.mounted) {
          String errorMsg = 'Error updating profile';
          final errorStr = e.toString().toLowerCase();
          
          if (errorStr.contains('wrong password') || errorStr.contains('wrong-password')) {
            errorMsg = 'Current password is incorrect';
          } else if (errorStr.contains('weak-password')) {
            errorMsg = 'Password is too weak';
          } else if (errorStr.contains('network') || 
                     errorStr.contains('internet') || 
                     errorStr.contains('unavailable') ||
                     errorStr.contains('socketexception') ||
                     errorStr.contains('failed host lookup')) {
            errorMsg = 'Network error. Please check your internet connection and try again.';
          } else if (errorStr.contains('permission') || errorStr.contains('denied')) {
            errorMsg = 'Permission denied. Please check your account permissions.';
          } else if (errorStr.contains('session expired')) {
            errorMsg = 'Your session has expired. Please log in again.';
          } else {
            // Show the actual error message
            errorMsg = e.toString().replaceAll('Exception: ', '').replaceAll('Error: ', '');
            if (errorMsg.length > 100) {
              errorMsg = '${errorMsg.substring(0, 100)}...';
            }
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _showEditProfileDialog(BuildContext context) async {
    final user = _authService.currentUser;
    if (user == null || !mounted) return;

    // Check if user can change password (must have email/password provider)
    final canChangePassword = user.email != null && 
                              user.providerData.any((info) => info.providerId == 'password');

    // Get current profile
    final currentProfile = await _userService.getUserProfile(user.uid);
    final TextEditingController usernameController = TextEditingController(
      text: currentProfile?.displayName ?? '',
    );
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    File? selectedImage;
    String? currentPhotoUrl = currentProfile?.photoUrl;
    bool _obscureCurrentPassword = true;
    bool _obscureNewPassword = true;
    bool _obscureConfirmPassword = true;

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                constraints: const BoxConstraints(maxWidth: 400),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.edit,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Edit Profile',
                              style: AppTheme.heading2,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: GestureDetector(
                          onTap: () async {
                            try {
                              final ImagePicker picker = ImagePicker();
                              final XFile? image = await picker.pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 85,
                              );
                              if (image != null) {
                                try {
                                  final file = File(image.path);
                                  if (await file.exists()) {
                                    setDialogState(() {
                                      selectedImage = file;
                                    });
                                  } else {
                                    throw Exception('Selected image file does not exist');
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error accessing image: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error picking image: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.primaryColor,
                                    width: 3,
                                  ),
                                  gradient: selectedImage == null && currentPhotoUrl == null
                                      ? AppTheme.accentGradient
                                      : null,
                                  color: selectedImage != null || currentPhotoUrl != null
                                      ? Colors.transparent
                                      : null,
                                ),
                                child: selectedImage != null
                                    ? ClipOval(
                                        child: Image.file(
                                          selectedImage!,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : (currentPhotoUrl != null && currentPhotoUrl.isNotEmpty)
                                        ? ClipOval(
                                            child: Image.network(
                                              currentPhotoUrl,
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  decoration: BoxDecoration(
                                                    gradient: AppTheme.accentGradient,
                                                  ),
                                                  child: const Icon(
                                                    Icons.person,
                                                    size: 50,
                                                    color: Colors.white,
                                                  ),
                                                );
                                              },
                                            ),
                                          )
                                        : const Icon(
                                            Icons.person,
                                            size: 50,
                                            color: Colors.white,
                                          ),
                              ),
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Tap to change photo',
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: usernameController,
                        decoration: AppTheme.textFieldDecoration.copyWith(
                          labelText: 'Username',
                          hintText: 'Enter your username',
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                      ),
                      if (canChangePassword) ...[
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          'Change Password (Optional)',
                          style: AppTheme.heading3.copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: currentPasswordController,
                          obscureText: _obscureCurrentPassword,
                          decoration: AppTheme.textFieldDecoration.copyWith(
                            labelText: 'Current Password',
                            hintText: 'Enter your current password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureCurrentPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setDialogState(() {
                                  _obscureCurrentPassword = !_obscureCurrentPassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: newPasswordController,
                          obscureText: _obscureNewPassword,
                          decoration: AppTheme.textFieldDecoration.copyWith(
                            labelText: 'New Password',
                            hintText: 'Enter new password',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureNewPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setDialogState(() {
                                  _obscureNewPassword = !_obscureNewPassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: AppTheme.textFieldDecoration.copyWith(
                            labelText: 'Confirm New Password',
                            hintText: 'Confirm new password',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setDialogState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              style: AppTheme.secondaryButtonStyle,
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _handleSaveProfile(
                                context: context,
                                dialogContext: dialogContext,
                                usernameController: usernameController,
                                currentPasswordController: currentPasswordController,
                                newPasswordController: newPasswordController,
                                confirmPasswordController: confirmPasswordController,
                                selectedImage: selectedImage,
                                currentPhotoUrl: currentPhotoUrl,
                                canChangePassword: canChangePassword,
                              ),
                              style: AppTheme.gradientButtonStyle,
                              child: const Text('Save Changes'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    usernameController.dispose();
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade100,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (color ?? AppTheme.primaryColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color ?? AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.heading3.copyWith(
                        color: color ?? AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMemberSince(DateTime? dateTime) {
    if (dateTime == null) return 'Recently';
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
}

class MyBookingsPage extends StatefulWidget {
  final String userId;

  const MyBookingsPage({super.key, required this.userId});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  final BookingService _bookingService = BookingService();
  final CottageService _cottageService = CottageService();
  DateTime? _startDate;
  DateTime? _endDate;
  Set<String> _cottageIds = {};

  @override
  void initState() {
    super.initState();
    _loadCottageIds();
  }

  Future<void> _loadCottageIds() async {
    try {
      final cottages = await _cottageService.getAllCottages();
      setState(() {
        _cottageIds = cottages.map((c) => c.id).toSet();
      });
    } catch (e) {
      debugPrint('Error loading cottage IDs: $e');
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime initialStart = _startDate ?? now.subtract(const Duration(days: 30));
    final DateTime initialEnd = _endDate ?? now.add(const Duration(days: 30));

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select date range',
      saveText: 'Apply',
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppTheme.primaryColor,
            colorScheme: const ColorScheme.light(primary: AppTheme.primaryColor),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  List<Booking> _filterBookings(List<Booking> bookings) {
    // First, filter out cottage bookings (only show room bookings)
    final roomBookings = bookings.where((booking) => !_cottageIds.contains(booking.roomId)).toList();
    
    // Then apply date filter if set
    if (_startDate == null && _endDate == null) {
      return roomBookings;
    }

    return roomBookings.where((booking) {
      final checkInDate = DateTime(booking.checkIn.year, booking.checkIn.month, booking.checkIn.day);
      final checkOutDate = DateTime(booking.checkOut.year, booking.checkOut.month, booking.checkOut.day);
      
      if (_startDate != null && _endDate != null) {
        final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
        return (checkInDate.isBefore(end.add(const Duration(days: 1))) && 
                checkOutDate.isAfter(start.subtract(const Duration(days: 1))));
      } else if (_startDate != null) {
        final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        return checkOutDate.isAfter(start.subtract(const Duration(days: 1)));
      } else if (_endDate != null) {
        final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
        return checkInDate.isBefore(end.add(const Duration(days: 1)));
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            const SizedBox(width: 1),
            const Text(
              'My Room Bookings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.filter_alt_outlined, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    Text(
                      'Filter Bookings',
                      style: AppTheme.heading3,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _startDate == null && _endDate == null
                      ? 'Showing all bookings'
                      : _startDate != null && _endDate != null
                          ? 'From ${_formatDate(_startDate!)} to ${_formatDate(_endDate!)}'
                          : _startDate != null
                              ? 'From ${_formatDate(_startDate!)}'
                              : 'Until ${_formatDate(_endDate!)}',
                  style: AppTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => _selectDateRange(context),
                          icon: const Icon(Icons.calendar_today, size: 20),
                          label: Text(
                            (_startDate == null || _endDate == null)
                                ? 'Select Date Range'
                                : 'Change Dates',
                          ),
                          style: AppTheme.gradientButtonStyle,
                        ),
                      ),
                    ),
                    if (_startDate != null || _endDate != null) ...[
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _clearDateFilter,
                          style: AppTheme.secondaryButtonStyle,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.clear, size: 20),
                              SizedBox(width: 8),
                              Text('Clear'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Booking>>(
              stream: _bookingService.getUserBookings(widget.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }

                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final allBookings = snapshot.data!;
                final filteredBookings = _filterBookings(allBookings);
                
                if (filteredBookings.isEmpty) {
                  return _buildNoResultsState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: filteredBookings.length,
                  itemBuilder: (context, index) {
                    final booking = filteredBookings[index];
                    return _buildBookingCard(context, booking);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading your bookings...',
            style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Unable to load bookings',
              style: AppTheme.heading3.copyWith(color: AppTheme.errorColor),
            ),
            const SizedBox(height: 12),
            Text(
              'Please check your connection and try again',
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setState(() {}),
              style: AppTheme.primaryButtonStyle,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.hotel_outlined,
                size: 60,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No bookings yet',
              style: AppTheme.heading2.copyWith(color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              'Start your journey by booking a room',
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: AppTheme.gradientButtonStyle,
                child: const Text('Browse Rooms'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 50,
                color: AppTheme.warningColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No bookings found',
              style: AppTheme.heading2.copyWith(color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              _startDate != null || _endDate != null
                  ? 'Try adjusting your date range filter'
                  : 'No bookings match your current filters',
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (_startDate != null || _endDate != null)
              ElevatedButton(
                onPressed: _clearDateFilter,
                style: AppTheme.secondaryButtonStyle,
                child: const Text('Clear Filters'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Booking booking) {
    final statusColor = _getStatusColor(booking.status);
    final icon = _getStatusIcon(booking.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: statusColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.roomName,
                            style: AppTheme.heading3.copyWith(
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Booking ID: ${booking.id.substring(0, 8)}',
                            style: AppTheme.caption,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        booking.status.name.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: _buildBookingDetail(
                        icon: Icons.calendar_today,
                        label: 'Check-in',
                        value: _formatDate(booking.checkIn),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppTheme.borderColor,
                    ),
                    Expanded(
                      child: _buildBookingDetail(
                        icon: Icons.calendar_today,
                        label: 'Check-out',
                        value: _formatDate(booking.checkOut),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildBookingDetail(
                        icon: Icons.people,
                        label: 'Guests',
                        value: '${booking.guests}',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppTheme.borderColor,
                    ),
                    Expanded(
                      child: _buildBookingDetail(
                        icon: Icons.bed,
                        label: 'Nights',
                        value: '${booking.numberOfNights}',
                      ),
                    ),
                  ],
                ),

                if (booking.eventType != EventType.none) ...[
                  const SizedBox(height: 16),
                  _buildBookingDetail(
                    icon: Icons.celebration,
                    label: 'Event Type',
                    value: booking.eventTypeDisplay,
                  ),
                ],

                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        '₱${booking.total.toStringAsFixed(2)}',
                        style: AppTheme.heading2.copyWith(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _editBooking(context, booking),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppTheme.borderColor),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _cancelBooking(context, booking),
                        icon: const Icon(Icons.cancel, size: 18),
                        label: const Text('Cancel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.warningColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: AppTheme.warningColor),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _deleteBooking(context, booking),
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.errorColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: AppTheme.errorColor),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingDetail({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTheme.caption,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return AppTheme.successColor;
      case BookingStatus.pending:
        return AppTheme.warningColor;
      case BookingStatus.rejected:
        return AppTheme.errorColor;
      case BookingStatus.cancelled:
        return AppTheme.textSecondary;
      default:
        return AppTheme.infoColor;
    }
  }

  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return Icons.check_circle;
      case BookingStatus.pending:
        return Icons.access_time;
      case BookingStatus.rejected:
        return Icons.cancel;
      case BookingStatus.cancelled:
        return Icons.block;
      default:
        return Icons.info;
    }
  }

  Future<void> _editBooking(BuildContext context, Booking booking) async {
    // Keep existing edit functionality
    final checkInController = TextEditingController(
      text: '${booking.checkIn.year}-${booking.checkIn.month.toString().padLeft(2, '0')}-${booking.checkIn.day.toString().padLeft(2, '0')}',
    );
    final checkOutController = TextEditingController(
      text: '${booking.checkOut.year}-${booking.checkOut.month.toString().padLeft(2, '0')}-${booking.checkOut.day.toString().padLeft(2, '0')}',
    );
    final guestsController = TextEditingController(text: booking.guests.toString());
    final specialRequestsController = TextEditingController(text: booking.specialRequests ?? '');

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.edit,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Edit Booking',
                      style: AppTheme.heading3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: checkInController,
                decoration: AppTheme.textFieldDecoration.copyWith(
                  labelText: 'Check-in Date',
                  hintText: 'YYYY-MM-DD',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: checkOutController,
                decoration: AppTheme.textFieldDecoration.copyWith(
                  labelText: 'Check-out Date',
                  hintText: 'YYYY-MM-DD',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: guestsController,
                decoration: AppTheme.textFieldDecoration.copyWith(
                  labelText: 'Number of Guests',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: specialRequestsController,
                decoration: AppTheme.textFieldDecoration.copyWith(
                  labelText: 'Special Requests',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: AppTheme.secondaryButtonStyle,
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            DateTime? newCheckIn;
                            DateTime? newCheckOut;
                            int? newGuests;

                            if (checkInController.text.isNotEmpty) {
                              newCheckIn = DateTime.parse(checkInController.text);
                            }
                            if (checkOutController.text.isNotEmpty) {
                              newCheckOut = DateTime.parse(checkOutController.text);
                            }
                            if (guestsController.text.isNotEmpty) {
                              newGuests = int.parse(guestsController.text);
                            }

                            await _bookingService.editBooking(
                              bookingId: booking.id,
                              userId: widget.userId,
                              checkIn: newCheckIn,
                              checkOut: newCheckOut,
                              guests: newGuests,
                              specialRequests: specialRequestsController.text.isEmpty ? null : specialRequestsController.text,
                            );

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Booking updated successfully'),
                                  backgroundColor: AppTheme.successColor,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: AppTheme.errorColor,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        style: AppTheme.gradientButtonStyle,
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cancelBooking(BuildContext context, Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 40,
                  color: AppTheme.warningColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Cancel Booking',
                style: AppTheme.heading2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to cancel your booking for ${booking.roomName}?',
                style: AppTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: AppTheme.secondaryButtonStyle,
                      child: const Text('No, Keep'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.warningColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Yes, Cancel'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await _bookingService.cancelBooking(
          bookingId: booking.id,
          userId: widget.userId,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Booking cancelled successfully'),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteBooking(BuildContext context, Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_forever,
                  size: 40,
                  color: AppTheme.errorColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Delete Booking',
                style: AppTheme.heading2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'This action cannot be undone. All booking data will be permanently removed.',
                style: AppTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.errorColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: AppTheme.errorColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Booking for "${booking.roomName}" will be deleted',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.errorColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: AppTheme.secondaryButtonStyle,
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await _bookingService.deleteBooking(
          bookingId: booking.id,
          userId: widget.userId,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Booking deleted successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class MyEventBookingsPage extends StatefulWidget {
  final String userId;

  const MyEventBookingsPage({super.key, required this.userId});

  @override
  State<MyEventBookingsPage> createState() => _MyEventBookingsPageState();
}

class _MyEventBookingsPageState extends State<MyEventBookingsPage> {
  final EventBookingService _eventBookingService = EventBookingService();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            const SizedBox(width: 1),
            const Text(
              'My Event Bookings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.event, color: AppTheme.accentColor),
                    const SizedBox(width: 12),
                    Text(
                      'Filter Events',
                      style: AppTheme.heading3,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _startDate == null && _endDate == null
                      ? 'Showing all event bookings'
                      : _startDate != null && _endDate != null
                          ? 'From ${_formatDate(_startDate!)} to ${_formatDate(_endDate!)}'
                          : _startDate != null
                              ? 'From ${_formatDate(_startDate!)}'
                              : 'Until ${_formatDate(_endDate!)}',
                  style: AppTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.accentGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => _selectDateRange(context),
                          icon: const Icon(Icons.calendar_today, size: 20),
                          label: const Text('Select Date Range'),
                          style: AppTheme.gradientButtonStyle,
                        ),
                      ),
                    ),
                    if (_startDate != null || _endDate != null) ...[
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _clearDateFilter,
                          style: AppTheme.secondaryButtonStyle,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.clear, size: 20),
                              SizedBox(width: 8),
                              Text('Clear'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<EventBooking>>(
              stream: _eventBookingService.getUserEventBookings(widget.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading event bookings',
                          style: AppTheme.heading3.copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No event bookings yet',
                          style: AppTheme.heading3.copyWith(color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                  );
                }

                final allBookings = snapshot.data!;
                final filteredBookings = _filterEventBookings(allBookings);
                
                if (filteredBookings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No event bookings found',
                          style: AppTheme.heading3.copyWith(color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredBookings.length,
                  itemBuilder: (context, index) {
                    final booking = filteredBookings[index];
                    return _buildEventBookingCard(context, booking);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime initialStart = _startDate ?? now.subtract(const Duration(days: 30));
    final DateTime initialEnd = _endDate ?? now.add(const Duration(days: 30));

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select date range',
      saveText: 'Apply',
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  List<EventBooking> _filterEventBookings(List<EventBooking> bookings) {
    if (_startDate == null && _endDate == null) {
      return bookings;
    }

    return bookings.where((booking) {
      final eventDate = DateTime(booking.eventDate.year, booking.eventDate.month, booking.eventDate.day);
      
      if (_startDate != null && _endDate != null) {
        final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
        return eventDate.isAfter(start.subtract(const Duration(days: 1))) && 
               eventDate.isBefore(end.add(const Duration(days: 1)));
      } else if (_startDate != null) {
        final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        return eventDate.isAfter(start.subtract(const Duration(days: 1)));
      } else if (_endDate != null) {
        final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
        return eventDate.isBefore(end.add(const Duration(days: 1)));
      }
      return true;
    }).toList();
  }

  Widget _buildEventBookingCard(BuildContext context, EventBooking booking) {
    final statusColor = _getEventStatusColor(booking.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.celebration,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Booking.getEventTypeDisplay(booking.eventType),
                            style: AppTheme.heading3,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Event Date: ${_formatDate(booking.eventDate)}',
                            style: AppTheme.caption,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        booking.status.name.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: _buildEventDetail(
                        icon: Icons.people,
                        label: 'Guests',
                        value: '${booking.peopleCount}',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppTheme.borderColor,
                    ),
                    Expanded(
                      child: _buildEventDetail(
                        icon: Icons.date_range,
                        label: 'Date',
                        value: _formatDate(booking.eventDate),
                      ),
                    ),
                  ],
                ),

                if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.note,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            booking.notes!,
                            style: AppTheme.bodyMedium.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _editEventBooking(context, booking),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppTheme.borderColor),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _cancelEventBooking(context, booking),
                        icon: const Icon(Icons.cancel, size: 18),
                        label: const Text('Cancel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.warningColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: AppTheme.warningColor),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _deleteEventBooking(context, booking),
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventDetail({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTheme.caption,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getEventStatusColor(EventBookingStatus status) {
    switch (status) {
      case EventBookingStatus.confirmed:
        return AppTheme.successColor;
      case EventBookingStatus.pending:
        return AppTheme.warningColor;
      case EventBookingStatus.rejected:
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  Future<void> _editEventBooking(BuildContext context, EventBooking booking) async {
    // Implementation remains the same as original
    final eventDateController = TextEditingController(
      text: '${booking.eventDate.year}-${booking.eventDate.month.toString().padLeft(2, '0')}-${booking.eventDate.day.toString().padLeft(2, '0')}',
    );
    final peopleCountController = TextEditingController(text: booking.peopleCount.toString());
    final notesController = TextEditingController(text: booking.notes ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Event Booking'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: eventDateController,
                decoration: const InputDecoration(
                  labelText: 'Event Date (YYYY-MM-DD)',
                  hintText: '2024-01-15',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: peopleCountController,
                decoration: const InputDecoration(
                  labelText: 'Number of People',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                DateTime? newEventDate;
                int? newPeopleCount;

                if (eventDateController.text.isNotEmpty) {
                  newEventDate = DateTime.parse(eventDateController.text);
                }
                if (peopleCountController.text.isNotEmpty) {
                  newPeopleCount = int.parse(peopleCountController.text);
                }

                await _eventBookingService.editEventBooking(
                  bookingId: booking.id,
                  userId: widget.userId,
                  eventDate: newEventDate,
                  peopleCount: newPeopleCount,
                  notes: notesController.text.isEmpty ? null : notesController.text,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Event booking updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelEventBooking(BuildContext context, EventBooking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Event Booking'),
        content: Text('Are you sure you want to cancel your ${Booking.getEventTypeDisplay(booking.eventType)} event booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _eventBookingService.cancelEventBooking(
          bookingId: booking.id,
          userId: widget.userId,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event booking cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteEventBooking(BuildContext context, EventBooking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete_forever,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Delete Event Booking',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to permanently delete this event booking?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone. All booking data will be permanently removed.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Event Booking Details:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Event Type: ${Booking.getEventTypeDisplay(booking.eventType)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    'Event Date: ${_formatDate(booking.eventDate)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    'People: ${booking.peopleCount}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await _eventBookingService.deleteEventBooking(
          bookingId: booking.id,
          userId: widget.userId,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Event booking deleted successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class MyCottageBookingsPage extends StatefulWidget {
  final String userId;

  const MyCottageBookingsPage({super.key, required this.userId});

  @override
  State<MyCottageBookingsPage> createState() => _MyCottageBookingsPageState();
}

class _MyCottageBookingsPageState extends State<MyCottageBookingsPage> {
  final CottageBookingService _cottageBookingService = CottageBookingService();
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime initialStart = _startDate ?? now.subtract(const Duration(days: 30));
    final DateTime initialEnd = _endDate ?? now.add(const Duration(days: 30));

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select date range',
      saveText: 'Apply',
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppTheme.primaryColor,
            colorScheme: const ColorScheme.light(primary: AppTheme.primaryColor),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  List<Booking> _filterCottageBookings(List<Booking> bookings) {
    // Apply date filter if set
    if (_startDate == null && _endDate == null) {
      return bookings;
    }

    return bookings.where((booking) {
      final checkInDate = DateTime(booking.checkIn.year, booking.checkIn.month, booking.checkIn.day);
      final checkOutDate = DateTime(booking.checkOut.year, booking.checkOut.month, booking.checkOut.day);
      
      if (_startDate != null && _endDate != null) {
        final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
        return (checkInDate.isBefore(end.add(const Duration(days: 1))) && 
                checkOutDate.isAfter(start.subtract(const Duration(days: 1))));
      } else if (_startDate != null) {
        final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        return checkOutDate.isAfter(start.subtract(const Duration(days: 1)));
      } else if (_endDate != null) {
        final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
        return checkInDate.isBefore(end.add(const Duration(days: 1)));
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Row(
          children: [
            SizedBox(width: 1),
            Text(
              'My Cottage Bookings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDateRange(context),
                    icon: const Icon(Icons.date_range, size: 18),
                    label: const Text('Filter Bookings'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: BorderSide(color: AppTheme.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (_startDate != null || _endDate != null)
                  OutlinedButton(
                    onPressed: _clearDateFilter,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                    child: const Text('Clear'),
                  ),
              ],
            ),
          ),
          if (_startDate != null || _endDate != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey.shade50,
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _startDate != null && _endDate != null
                          ? 'Showing bookings from ${_formatDate(_startDate!)} to ${_formatDate(_endDate!)}'
                          : _startDate != null
                              ? 'Showing bookings from ${_formatDate(_startDate!)}'
                              : 'Showing bookings until ${_formatDate(_endDate!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<List<Booking>>(
              stream: _cottageBookingService.getUserCottageBookings(widget.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading your cottage bookings...',
                          style: AppTheme.bodyMedium.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Unable to load bookings',
                          style: AppTheme.heading3.copyWith(
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: AppTheme.bodyMedium.copyWith(
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final allBookings = snapshot.data ?? [];
                final filteredBookings = _filterCottageBookings(allBookings);

                if (filteredBookings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.home_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _startDate != null || _endDate != null
                              ? 'No cottage bookings found'
                              : 'No cottage bookings yet',
                          style: AppTheme.heading3.copyWith(
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _startDate != null || _endDate != null
                              ? 'Try adjusting your date filters'
                              : 'Start your journey by booking a cottage',
                          style: AppTheme.bodyMedium.copyWith(
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredBookings.length,
                  itemBuilder: (context, index) {
                    final booking = filteredBookings[index];
                    return _buildCottageBookingCard(context, booking);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCottageBookingCard(BuildContext context, Booking booking) {
    final statusColor = _getStatusColor(booking.status);
    final icon = _getStatusIcon(booking.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: statusColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.roomName,
                            style: AppTheme.heading3.copyWith(
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Booking ID: ${booking.id.substring(0, 8)}',
                            style: AppTheme.caption,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        booking.status.name.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildBookingDetail(
                        icon: Icons.calendar_today,
                        label: 'Booking Date',
                        value: _formatDate(booking.checkIn),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppTheme.borderColor,
                    ),
                    Expanded(
                      child: _buildBookingDetail(
                        icon: Icons.people,
                        label: 'Guests',
                        value: '${booking.guests}',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppTheme.borderColor,
                    ),
                    Expanded(
                      child: _buildBookingDetail(
                        icon: Icons.access_time,
                        label: 'Duration',
                        value: '1 day',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '₱${booking.total.toStringAsFixed(2)}',
                        style: AppTheme.heading3.copyWith(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (booking.specialRequests != null && booking.specialRequests!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.note_outlined,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            booking.specialRequests!,
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    if (booking.status == BookingStatus.pending || booking.status == BookingStatus.confirmed)
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit'),
                          onPressed: () => _editBooking(context, booking),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            side: BorderSide(color: AppTheme.primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    if (booking.status == BookingStatus.pending || booking.status == BookingStatus.confirmed) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.cancel, size: 18),
                          label: const Text('Cancel'),
                          onPressed: () => _cancelBooking(context, booking),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('Delete'),
                        onPressed: () => _deleteCottageBooking(context, booking),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingDetail({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTheme.caption,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.rejected:
        return Colors.red;
      case BookingStatus.cancelled:
        return Colors.grey;
      case BookingStatus.completed:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return Icons.check_circle;
      case BookingStatus.pending:
        return Icons.pending;
      case BookingStatus.rejected:
        return Icons.cancel;
      case BookingStatus.cancelled:
        return Icons.cancel_outlined;
      case BookingStatus.completed:
        return Icons.done_all;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  Future<void> _editBooking(BuildContext context, Booking booking) async {
    final checkInController = TextEditingController(
      text: '${booking.checkIn.year}-${booking.checkIn.month.toString().padLeft(2, '0')}-${booking.checkIn.day.toString().padLeft(2, '0')}',
    );
    final guestsController = TextEditingController(text: booking.guests.toString());
    final specialRequestsController = TextEditingController(text: booking.specialRequests ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Cottage Booking'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: checkInController,
                decoration: const InputDecoration(
                  labelText: 'Booking Date',
                  hintText: 'YYYY-MM-DD',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: booking.checkIn,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    checkInController.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: guestsController,
                decoration: const InputDecoration(
                  labelText: 'Number of Guests',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: specialRequestsController,
                decoration: const InputDecoration(
                  labelText: 'Special Requests (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      try {
        final checkIn = DateTime.parse(checkInController.text);
        final checkOut = DateTime(checkIn.year, checkIn.month, checkIn.day + 1);
        final guests = int.parse(guestsController.text);

        await _cottageBookingService.editCottageBooking(
          bookingId: booking.id,
          userId: widget.userId,
          checkIn: checkIn,
          checkOut: checkOut,
          guests: guests,
          specialRequests: specialRequestsController.text.trim().isEmpty
              ? null
              : specialRequestsController.text.trim(),
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cottage booking updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _cancelBooking(BuildContext context, Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Cottage Booking'),
        content: Text('Are you sure you want to cancel your booking for ${booking.roomName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await _cottageBookingService.cancelCottageBooking(
          bookingId: booking.id,
          userId: widget.userId,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cottage booking cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteCottageBooking(BuildContext context, Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete_forever,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Delete Cottage Booking',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to permanently delete this cottage booking?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone. All booking data will be permanently removed.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cottage Booking Details:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cottage: ${booking.roomName}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    'Booking Date: ${_formatDate(booking.checkIn)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    'Guests: ${booking.guests}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    'Total: ₱${booking.total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await _cottageBookingService.deleteCottageBooking(
          bookingId: booking.id,
          userId: widget.userId,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Cottage booking deleted successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }
}