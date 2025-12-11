import 'package:flutter/material.dart';
import 'dart:convert';

/// A widget that displays cottage images, supporting both Base64 encoded images
/// and regular image URLs (network or data URIs)
class CottageImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CottageImageWidget({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
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
    // If no image URL, show placeholder or error widget
    if (imageUrl == null || imageUrl!.isEmpty || imageUrl!.trim().isEmpty) {
      return errorWidget ??
          Container(
            width: width,
            height: height,
            color: Colors.grey.shade200,
            child: const Icon(Icons.home, size: 40, color: Colors.grey),
          );
    }

    // Handle Base64 images
    if (_isBase64Image(imageUrl!)) {
      try {
        final base64String = _extractBase64(imageUrl!);
        if (base64String != null && base64String.isNotEmpty) {
          final bytes = base64Decode(base64String);
          if (bytes.isNotEmpty) {
            return Image.memory(
              bytes,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (context, error, stackTrace) {
                return errorWidget ??
                    Container(
                      width: width,
                      height: height,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.home, size: 40, color: Colors.grey),
                    );
              },
            );
          }
        }
      } catch (e) {
        debugPrint('Error decoding Base64 cottage image: $e');
      }
      // If Base64 decode failed, show error widget
      return errorWidget ??
          Container(
            width: width,
            height: height,
            color: Colors.grey.shade200,
            child: const Icon(Icons.home, size: 40, color: Colors.grey),
          );
    }

    // Handle regular network URLs
    return Image.network(
      imageUrl!,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ??
            Container(
              width: width,
              height: height,
              color: Colors.grey.shade200,
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
        return errorWidget ??
            Container(
              width: width,
              height: height,
              color: Colors.grey.shade200,
              child: const Icon(Icons.home, size: 40, color: Colors.grey),
            );
      },
    );
  }
}


