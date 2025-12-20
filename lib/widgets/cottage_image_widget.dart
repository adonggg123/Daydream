import 'package:flutter/material.dart';
import 'dart:convert';

/// A widget that displays cottage images, supporting both Base64 encoded images
/// and regular image URLs (network or data URIs)
class CottageImageWidget extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final double? width;
  final double? height;

  const CottageImageWidget({
    super.key,
    this.imageUrl,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.width,
    this.height,
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
    if (imageUrl == null || imageUrl!.isEmpty) {
      return errorWidget ??
          Container(
            color: Colors.grey.shade200,
            child: const Icon(Icons.image_not_supported, size: 40),
          );
    }

    // Handle Base64 images
    if (_isBase64Image(imageUrl!)) {
      try {
        final base64String = _extractBase64(imageUrl!);
        if (base64String != null) {
          final bytes = base64Decode(base64String);
          return Image.memory(
            bytes,
            fit: fit,
            width: width,
            height: height,
            errorBuilder: (context, error, stackTrace) {
              return errorWidget ??
                  Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_not_supported, size: 40),
                  );
            },
          );
        }
      } catch (e) {
        debugPrint('Error decoding Base64 image: $e');
        return errorWidget ??
            Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.image_not_supported, size: 40),
            );
      }
    }

    // Handle regular network URLs
    return Image.network(
      imageUrl!,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ??
            Container(
              color: Colors.grey.shade200,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ??
            Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.image_not_supported, size: 40),
            );
      },
    );
  }
}








