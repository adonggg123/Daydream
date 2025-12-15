import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '../models/cottage.dart';
import 'audit_trail_service.dart';
import 'user_service.dart';
import 'role_based_access_control.dart';

class CottageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'cottages';
  final AuditTrailService _auditTrail = AuditTrailService();
  final UserService _userService = UserService();

  // Stream all cottages
  Stream<List<Cottage>> streamAllCottages() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      final cottages = <Cottage>[];
      for (final doc in snapshot.docs) {
        try {
          final cottage = Cottage.fromMap(doc.id, doc.data());
          // Only include available cottages
          if (cottage.isAvailable) {
            cottages.add(cottage);
          }
        } catch (e) {
          debugPrint('Error parsing cottage ${doc.id}: $e');
          // Continue processing other cottages even if one fails
        }
      }
      return cottages;
    }).handleError((error) {
      debugPrint('Error in streamAllCottages: $error');
      // Return empty list on error instead of crashing
      return <Cottage>[];
    });
  }

  // Get all cottages (non-streaming)
  Future<List<Cottage>> getAllCottages() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final cottages = <Cottage>[];
      for (final doc in snapshot.docs) {
        try {
          final cottage = Cottage.fromMap(doc.id, doc.data());
          if (cottage.isAvailable) {
            cottages.add(cottage);
          }
        } catch (e) {
          debugPrint('Error parsing cottage ${doc.id}: $e');
        }
      }
      return cottages;
    } catch (e) {
      debugPrint('Error getting all cottages: $e');
      return [];
    }
  }

  // Get cottage by ID
  Future<Cottage?> getCottageById(String cottageId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(cottageId).get();
      if (!doc.exists) {
        return null;
      }
      return Cottage.fromMap(doc.id, doc.data()!);
    } catch (e) {
      debugPrint('Error getting cottage by ID: $e');
      return null;
    }
  }

  // Stream all cottages for admin (includes unavailable)
  Stream<List<Cottage>> streamAllCottagesForAdmin() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
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
    }).handleError((error) {
      debugPrint('Error in streamAllCottagesForAdmin: $error');
      // Return empty list on error instead of crashing
      return <Cottage>[];
    });
  }

  // Update cottage availability
  Future<void> updateCottageAvailability({
    required String cottageId,
    required bool isAvailable,
    String? userId,
  }) async {
    await _firestore.collection(_collection).doc(cottageId).update({
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
          action: AuditAction.roomUpdated,
          resourceType: 'cottage',
          resourceId: cottageId,
          details: {
            'isAvailable': isAvailable,
          },
        );
      }
    }
  }

  // Upload cottage image (converts to Base64)
  // Also accepts bytes directly for web compatibility
  Future<String> uploadCottageImage(dynamic imageFile, String cottageId, {Uint8List? imageBytes}) async {
    try {
      Uint8List bytes;
      
      // If bytes are provided directly (e.g., from XFile on web), use them
      if (imageBytes != null) {
        bytes = imageBytes;
      }
      // Handle web/desktop blob URLs and HTTP URLs
      else if (kIsWeb || 
          (imageFile is File && (imageFile.path.startsWith('blob:') || 
          imageFile.path.startsWith('http://') || 
          imageFile.path.startsWith('https://')))) {
        // For web/desktop, check if we have a blob URL
        final file = imageFile as File;
        if (file.path.startsWith('blob:')) {
          // Blob URLs cannot be read as files - bytes must be provided
          debugPrint('Cannot read blob URL as file: ${file.path}');
          throw Exception('Image bytes are required for blob URLs. Please try selecting the image again.');
        }
        
        // For http/https URLs, try to fetch them
        try {
          final response = await http.get(Uri.parse(file.path)).timeout(
            const Duration(seconds: 10),
          );
          
          if (response.statusCode != 200) {
            throw Exception('Failed to read URL: ${response.statusCode}');
          }
          
          bytes = response.bodyBytes;
        } catch (httpError) {
          debugPrint('Error fetching image from URL: $httpError');
          throw Exception('Could not read image from URL. Please try selecting the image again.');
        }
      } else {
        // For mobile/desktop with file paths, read file normally
        final file = imageFile as File;
        try {
          bytes = await file.readAsBytes();
        } catch (e) {
          // If readAsBytes fails, try reading as a file that might not exist yet
          debugPrint('Error reading file bytes: $e');
          debugPrint('File path: ${file.path}');
          
          // Try to read the file even if it doesn't "exist" (might be a temp file)
          try {
            bytes = await file.readAsBytes();
          } catch (e2) {
            debugPrint('Second attempt to read file also failed: $e2');
            throw Exception('Could not read image file. Please try selecting the image again.');
          }
        }
      }
      
      // Compress and resize image to ensure it fits within Firestore's 1MB limit
      bytes = await _compressImage(bytes);
      
      // Convert to Base64 string
      String base64String = base64Encode(bytes);
      
      // Check if Base64 string exceeds Firestore limit (1MB = 1,048,576 bytes)
      // Base64 encoding increases size by ~33%, so we check the encoded size
      const maxBase64Size = 1000000; // ~750KB raw to stay under 1MB when Base64 encoded
      if (base64String.length > maxBase64Size) {
        // Further compress if still too large
        bytes = await _compressImage(bytes, maxWidth: 800, quality: 60);
        base64String = base64Encode(bytes);
        if (base64String.length > maxBase64Size) {
          // One more attempt with even more compression
          bytes = await _compressImage(bytes, maxWidth: 600, quality: 50);
          base64String = base64Encode(bytes);
          if (base64String.length > maxBase64Size) {
            throw Exception('Image is too large even after compression. Please use a smaller image.');
          }
        }
      }
      
      // Determine image format from file extension or default to jpeg
      String imageFormat = 'jpeg';
      String fileName = '';
      if (imageFile is File) {
        fileName = imageFile.path.toLowerCase();
      }
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
      if (imageFile is File) {
        debugPrint('Image file path: ${imageFile.path}');
      }
      rethrow;
    }
  }

  // Compress and resize image to reduce file size
  Future<Uint8List> _compressImage(Uint8List imageBytes, {int maxWidth = 1200, int quality = 85}) async {
    try {
      // Decode the image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Could not decode image');
      }
      
      // Calculate new dimensions maintaining aspect ratio
      int newWidth = image.width;
      int newHeight = image.height;
      
      if (image.width > maxWidth) {
        final ratio = maxWidth / image.width;
        newWidth = maxWidth;
        newHeight = (image.height * ratio).round();
      }
      
      // Resize if needed
      img.Image resizedImage = image;
      if (newWidth != image.width || newHeight != image.height) {
        resizedImage = img.copyResize(image, width: newWidth, height: newHeight);
      }
      
      // Encode as JPEG with quality compression
      final compressedBytes = Uint8List.fromList(img.encodeJpg(resizedImage, quality: quality));
      
      return compressedBytes;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      // If compression fails, return original bytes (will fail later if too large)
      return imageBytes;
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
    // Optional service-level permission guard (if userId provided, check createRoom permission)
    if (userId != null) {
      final callerProfile = await _userService.getUserProfile(userId);
      if (callerProfile == null || !RoleBasedAccessControl.userHasPermission(callerProfile, Permission.createRoom)) {
        throw Exception('Unauthorized: caller does not have permission to create cottages.');
      }
    }
    final cottageRef = _firestore.collection(_collection).doc();
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
          action: AuditAction.roomCreated,
          resourceType: 'cottage',
          resourceId: cottageId,
          details: cottageData,
        );
      }
    }

    return cottageId;
  }

  // Update cottage details
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
    // Always update imageUrl if provided (including empty string to clear it)
    if (imageUrl != null) {
      updateData['imageUrl'] = imageUrl;
    }
    if (isAvailable != null) {
      updateData['isAvailable'] = isAvailable;
    }

    // Optional permissions guard
    if (userId != null) {
      final callerProfile = await _userService.getUserProfile(userId);
      if (callerProfile == null || !RoleBasedAccessControl.userHasPermission(callerProfile, Permission.editRoom)) {
        throw Exception('Unauthorized: caller does not have permission to edit cottages.');
      }
    }
    await _firestore.collection(_collection).doc(cottageId).update(updateData);

    // Log audit trail
    if (userId != null) {
      final userProfile = await _userService.getUserProfile(userId);
      if (userProfile != null) {
        await _auditTrail.logAction(
          userId: userId,
          userEmail: userProfile.email,
          userRole: userProfile.role,
          action: AuditAction.roomUpdated,
          resourceType: 'cottage',
          resourceId: cottageId,
          details: updateData,
        );
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
    await _firestore.collection(_collection).doc(cottageId).delete();

    // Log audit trail
    if (userId != null) {
      final userProfile = await _userService.getUserProfile(userId);
      if (userProfile != null) {
        await _auditTrail.logAction(
          userId: userId,
          userEmail: userProfile.email,
          userRole: userProfile.role,
          action: AuditAction.roomDeleted,
          resourceType: 'cottage',
          resourceId: cottageId,
        );
      }
    }
  }
}

