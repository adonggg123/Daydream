import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/cottage.dart';
import 'audit_trail_service.dart';
import 'user_service.dart';
import 'role_based_access_control.dart';

class CottageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _cottagesCollection = 'cottages';
  final AuditTrailService _auditTrail = AuditTrailService();
  final UserService _userService = UserService();

  // Convert image file to Base64 string (supports web/desktop blob URLs and regular files)
  Future<String> uploadCottageImage(File imageFile, String cottageId) async {
    try {
      Uint8List bytes;
      
      // Handle web/desktop blob URLs and HTTP URLs
      if (kIsWeb || 
          imageFile.path.startsWith('blob:') || 
          imageFile.path.startsWith('http://') || 
          imageFile.path.startsWith('https://')) {
        // For web/desktop, read bytes from blob/HTTP URL using http
        try {
          final response = await http.get(Uri.parse(imageFile.path)).timeout(
            const Duration(seconds: 10),
          );
          
          if (response.statusCode != 200) {
            throw Exception('Failed to read URL: ${response.statusCode}');
          }
          
          bytes = response.bodyBytes;
        } catch (e) {
          debugPrint('Error fetching image from URL: $e');
          rethrow;
        }
      } else {
        // For mobile/desktop with file paths, read file normally
        try {
          bytes = await imageFile.readAsBytes();
        } catch (e) {
          debugPrint('Error reading file bytes: $e');
          debugPrint('File path: ${imageFile.path}');
          rethrow;
        }
      }
      
      // Convert to Base64 string
      final base64String = base64Encode(bytes);
      
      // Determine image format from file extension or default to jpeg
      String imageFormat = 'jpeg';
      final fileName = imageFile.path.toLowerCase();
      if (fileName.endsWith('.png') || fileName.contains('.png')) {
        imageFormat = 'png';
      } else if (fileName.endsWith('.gif') || fileName.contains('.gif')) {
        imageFormat = 'gif';
      } else if (fileName.endsWith('.webp') || fileName.contains('.webp')) {
        imageFormat = 'webp';
      }
      
      // Return Base64 data URI format: data:image/jpeg;base64,<base64string>
      return 'data:image/$imageFormat;base64,$base64String';
    } catch (e) {
      debugPrint('Error converting image to Base64: $e');
      debugPrint('Image file path: ${imageFile.path}');
      rethrow;
    }
  }

  // Delete image - No-op for Base64 since images are stored in Firestore
  Future<void> deleteCottageImage(String imageUrl) async {
    try {
      // Base64 images are stored in Firestore, so no deletion needed
      // Only delete from Firebase Storage if it's a Firebase Storage URL
      if (imageUrl.isEmpty || imageUrl.startsWith('data:image')) {
        return; // Base64 image or empty, skip deletion
      }
      
      // Only attempt deletion if it's a Firebase Storage URL
      if (imageUrl.contains('firebasestorage')) {
        final Reference ref = _storage.refFromURL(imageUrl);
        await ref.delete();
      }
    } catch (e) {
      debugPrint('Error deleting image: $e');
      // Don't throw - image deletion failure shouldn't block cottage operations
    }
  }

  // Get all cottages (for regular users - only available cottages)
  Future<List<Cottage>> getAllCottages() async {
    final cottagesSnapshot = await _firestore.collection(_cottagesCollection).get();
    return cottagesSnapshot.docs
        .map((doc) => Cottage.fromMap(doc.id, doc.data()))
        .where((cottage) => cottage.isAvailable)
        .toList();
  }

  // Get all cottages including unavailable ones (for admin)
  Future<List<Cottage>> getAllCottagesForAdmin() async {
    final cottagesSnapshot = await _firestore.collection(_cottagesCollection).get();
    return cottagesSnapshot.docs
        .map((doc) => Cottage.fromMap(doc.id, doc.data()))
        .toList();
  }

  // Stream all cottages for admin (real-time updates)
  Stream<List<Cottage>> streamAllCottagesForAdmin() {
    return _firestore.collection(_cottagesCollection).snapshots().map((snapshot) {
      final cottages = <Cottage>[];
      for (final doc in snapshot.docs) {
        try {
          final cottage = Cottage.fromMap(doc.id, doc.data());
          cottages.add(cottage);
        } catch (e) {
          debugPrint('Error parsing cottage ${doc.id}: $e');
          // Continue processing other cottages even if one fails
        }
      }
      return cottages;
    });
  }

  // Stream all available cottages (for user interface)
  Stream<List<Cottage>> streamAllCottages() {
    return _firestore
        .collection(_cottagesCollection)
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final cottages = <Cottage>[];
      for (final doc in snapshot.docs) {
        try {
          final cottage = Cottage.fromMap(doc.id, doc.data());
          cottages.add(cottage);
        } catch (e) {
          debugPrint('Error parsing cottage ${doc.id}: $e');
        }
      }
      return cottages;
    });
  }

  // Update cottage availability
  Future<void> updateCottageAvailability({
    required String cottageId,
    required bool isAvailable,
    String? userId,
  }) async {
    await _firestore.collection(_cottagesCollection).doc(cottageId).update({
      'isAvailable': isAvailable,
    });

    // Log audit trail
    if (userId != null) {
      final userProfile = await _userService.getUserProfile(userId);
      if (userProfile != null) {
        await _auditTrail.logAction(
          userId: userId,
          userEmail: userProfile.email,
          userRole: userProfile.role,
          action: AuditAction.roomUpdated, // Reuse room action for now
          resourceType: 'cottage',
          resourceId: cottageId,
          details: {
            'isAvailable': isAvailable,
          },
        ).catchError((e) {
          debugPrint('Audit trail logging failed: $e');
        });
      }
    }
  }

  // Create a new cottage
  Future<String> createCottage({
    required String name,
    required String description,
    required double price,
    required int capacity,
    List<String> amenities = const [],
    String imageUrl = '',
    bool isAvailable = true,
    String? userId,
  }) async {
    // Optional service-level permission guard
    if (userId != null) {
      final callerProfile = await _userService.getUserProfile(userId);
      if (callerProfile == null || !RoleBasedAccessControl.userHasPermission(callerProfile, Permission.createRoom)) {
        throw Exception('Unauthorized: caller does not have permission to create cottages.');
      }
    }
    final cottageRef = _firestore.collection(_cottagesCollection).doc();
    final cottageId = cottageRef.id;

    final cottageData = {
      'name': name,
      'description': description,
      'price': price,
      'capacity': capacity,
      'amenities': amenities,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
    };

    await cottageRef.set(cottageData);

    // Log audit trail
    if (userId != null) {
      final userProfile = await _userService.getUserProfile(userId);
      if (userProfile != null) {
        await _auditTrail.logAction(
          userId: userId,
          userEmail: userProfile.email,
          userRole: userProfile.role,
          action: AuditAction.roomCreated, // Reuse room action for now
          resourceType: 'cottage',
          resourceId: cottageId,
        ).catchError((e) {
          debugPrint('Audit trail logging failed: $e');
        });
      }
    }

    return cottageId;
  }

  // Update an existing cottage
  Future<void> updateCottage({
    required String cottageId,
    required String name,
    required String description,
    required double price,
    required int capacity,
    List<String>? amenities,
    String? imageUrl,
    bool? isAvailable,
    String? userId,
  }) async {
    final updateData = <String, dynamic>{
      'name': name,
      'description': description,
      'price': price,
      'capacity': capacity,
    };

    if (amenities != null) {
      updateData['amenities'] = amenities;
    }
    if (imageUrl != null) {
      updateData['imageUrl'] = imageUrl;
    }
    if (isAvailable != null) {
      updateData['isAvailable'] = isAvailable;
    }

    await _firestore.collection(_cottagesCollection).doc(cottageId).update(updateData);

    // Log audit trail
    if (userId != null) {
      final userProfile = await _userService.getUserProfile(userId);
      if (userProfile != null) {
        await _auditTrail.logAction(
          userId: userId,
          userEmail: userProfile.email,
          userRole: userProfile.role,
          action: AuditAction.roomUpdated, // Reuse room action for now
          resourceType: 'cottage',
          resourceId: cottageId,
        ).catchError((e) {
          debugPrint('Audit trail logging failed: $e');
        });
      }
    }
  }

  // Delete a cottage
  Future<void> deleteCottage({
    required String cottageId,
    String? userId,
  }) async {
    // Optional permissions guard
    if (userId != null) {
      final callerProfile = await _userService.getUserProfile(userId);
      if (callerProfile == null || !RoleBasedAccessControl.userHasPermission(callerProfile, Permission.deleteRoom)) {
        throw Exception('Unauthorized: caller does not have permission to delete cottages.');
      }
    }
    await _firestore.collection(_cottagesCollection).doc(cottageId).delete();

    // Log audit trail
    if (userId != null) {
      final userProfile = await _userService.getUserProfile(userId);
      if (userProfile != null) {
        await _auditTrail.logAction(
          userId: userId,
          userEmail: userProfile.email,
          userRole: userProfile.role,
          action: AuditAction.roomDeleted, // Reuse room action for now
          resourceType: 'cottage',
          resourceId: cottageId,
        ).catchError((e) {
          debugPrint('Audit trail logging failed: $e');
        });
      }
    }
  }
}


