import 'package:flutter/material.dart';
import 'dart:convert';

/// A widget that displays profile images, supporting both Base64 encoded images
/// and regular image URLs (network or data URIs)
class ProfileImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Color? backgroundColor;
  final String? fallbackText;

  const ProfileImageWidget({
    super.key,
    this.imageUrl,
    this.size = 40,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.backgroundColor,
    this.fallbackText,
  });

  /// Check if the imageUrl is a Base64 data URI
  bool _isBase64Image(String url) {
    return url.startsWith('data:image/');
  }

  /// Extract Base64 string from data URI
  String? _extractBase64(String dataUri) {
    try {
      final commaIndex = dataUri.indexOf(',');
      if (commaIndex != -1 && commaIndex < dataUri.length - 1) {
        return dataUri.substring(commaIndex + 1);
      }
    } catch (e) {
      debugPrint('Error extracting Base64: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // If no image URL, show placeholder or fallback
    if (imageUrl == null || imageUrl!.isEmpty || imageUrl!.trim().isEmpty) {
      return _buildFallback();
    }

    // Handle Base64 images
    if (_isBase64Image(imageUrl!)) {
      try {
        final base64String = _extractBase64(imageUrl!);
        if (base64String != null && base64String.isNotEmpty) {
          final bytes = base64Decode(base64String);
          if (bytes.isNotEmpty) {
            return ClipOval(
              child: Image.memory(
                bytes,
                width: size,
                height: size,
                fit: fit,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Base64 image decode error: $error');
                  return errorWidget ?? _buildFallback();
                },
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Error decoding Base64 profile image: $e');
        return errorWidget ?? _buildFallback();
      }
      // If Base64 decode failed, show fallback
      return _buildFallback();
    }

    // Handle regular network URLs
    return ClipOval(
      child: Image.network(
        imageUrl!,
        width: size,
        height: size,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ??
              Container(
                width: size,
                height: size,
                color: backgroundColor ?? Colors.grey.shade200,
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2,
                  ),
                ),
              );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Network image load error: $error');
          return errorWidget ?? _buildFallback();
        },
      ),
    );
  }

  Widget _buildFallback() {
    // Always show fallback text if provided, even if empty string
    if (fallbackText != null) {
      final displayText = fallbackText!.isNotEmpty 
          ? fallbackText![0].toUpperCase() 
          : '?';
      
      // Just show the letter without any background
      return Container(
        width: size,
        height: size,
        child: Center(
          child: Text(
            displayText,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: size * 0.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        size: size * 0.6,
        color: Colors.white,
      ),
    );
  }
}

