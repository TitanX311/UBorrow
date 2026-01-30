import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cloudinary_provider.g.dart';

/// Cloudinary configuration provider
@riverpod
CloudinaryConfig cloudinaryConfig(CloudinaryConfigRef ref) {
  return CloudinaryConfig(
    cloudName: 'dljonya6a', // Replace with your cloud name
    uploadPreset: 'ml_default', // Replace with your upload preset
  );
}

/// Cloudinary service provider
@riverpod
CloudinaryService cloudinaryService(CloudinaryServiceRef ref) {
  final config = ref.watch(cloudinaryConfigProvider);
  return CloudinaryService(config);
}

/// Configuration class for Cloudinary
class CloudinaryConfig {
  final String cloudName;
  final String uploadPreset;
  final String? apiKey;
  final String? apiSecret;

  const CloudinaryConfig({
    required this.cloudName,
    required this.uploadPreset,
    this.apiKey,
    this.apiSecret,
  });
}

/// Cloudinary service class
class CloudinaryService {
  final CloudinaryConfig config;

  CloudinaryService(this.config);

  /// Upload an image file to Cloudinary
  /// Returns the secure URL of the uploaded image
  Future<String?> uploadImage({
    required File imageFile,
    String folder = 'uborrow_items',
    Function(double)? onProgress,
  }) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/${config.cloudName}/image/upload',
      );

      final request = http.MultipartRequest('POST', url);

      request.fields['upload_preset'] = config.uploadPreset;
      request.fields['folder'] = folder;

      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final response = await request.send();

      final responseBytes = await response.stream.toBytes();
      final responseString = utf8.decode(responseBytes);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonMap = jsonDecode(responseString);
        return jsonMap['secure_url'] as String?;
      } else {
        print('Cloudinary error ${response.statusCode}: $responseString');
        return null;
      }
    } catch (e) {
      print('Cloudinary upload error: $e');
      return null;
    }
  }

  /// Upload multiple images to Cloudinary
  Future<List<String>> uploadMultipleImages({
    required List<File> imageFiles,
    String folder = 'uborrow_items',
    Function(int current, int total)? onProgress,
  }) async {
    final List<String> urls = [];

    for (int i = 0; i < imageFiles.length; i++) {
      final file = imageFiles[i];
      onProgress?.call(i + 1, imageFiles.length);

      final url = await uploadImage(imageFile: file, folder: folder);
      if (url != null) {
        urls.add(url);
      }
    }

    return urls;
  }

  /// Delete an image from Cloudinary using its public ID
  /// Note: This requires API Key and Secret for authentication
  Future<bool> deleteImage(String publicId) async {
    try {
      if (config.apiKey == null || config.apiSecret == null) {
        print('API Key and Secret required for deletion');
        return false;
      }

      // Implement signed deletion using your API credentials
      // This is a placeholder - implement based on your security requirements
      print('Delete functionality requires API credentials');
      return false;
    } catch (e) {
      print('Error deleting from Cloudinary: $e');
      return false;
    }
  }

  /// Extract public ID from Cloudinary URL
  String? getPublicIdFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      // Find the index after 'upload' and version (if exists)
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1) return null;

      // Skip version if it exists (starts with 'v')
      int startIndex = uploadIndex + 1;
      if (pathSegments[startIndex].startsWith('v')) {
        startIndex++;
      }

      // Join remaining segments and remove extension
      final publicIdWithExt = pathSegments.sublist(startIndex).join('/');
      final publicId = publicIdWithExt.substring(
        0,
        publicIdWithExt.lastIndexOf('.'),
      );

      return publicId;
    } catch (e) {
      print('Error extracting public ID: $e');
      return null;
    }
  }

  /// Generate a thumbnail URL from the original Cloudinary URL
  String getThumbnailUrl(
    String originalUrl, {
    int width = 300,
    int height = 300,
    String crop = 'fill',
  }) {
    try {
      final uri = Uri.parse(originalUrl);
      final pathSegments = uri.pathSegments.toList();

      // Find upload index
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1) return originalUrl;

      // Insert transformation after 'upload'
      pathSegments.insert(uploadIndex + 1, 'w_$width,h_$height,c_$crop');

      // Rebuild URL
      return uri.replace(pathSegments: pathSegments).toString();
    } catch (e) {
      return originalUrl;
    }
  }

  /// Generate an optimized URL with quality and format parameters
  String getOptimizedUrl(
    String originalUrl, {
    String quality = 'auto',
    String format = 'auto',
  }) {
    try {
      final uri = Uri.parse(originalUrl);
      final pathSegments = uri.pathSegments.toList();

      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1) return originalUrl;

      pathSegments.insert(uploadIndex + 1, 'q_$quality,f_$format');

      return uri.replace(pathSegments: pathSegments).toString();
    } catch (e) {
      return originalUrl;
    }
  }
}

/// Extension to make it easier to use with Image.network
extension CloudinaryUrl on String {
  String toThumbnail({int width = 300, int height = 300}) {
    try {
      final uri = Uri.parse(this);
      final pathSegments = uri.pathSegments.toList();

      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1) return this;

      pathSegments.insert(uploadIndex + 1, 'w_$width,h_$height,c_fill');

      return uri.replace(pathSegments: pathSegments).toString();
    } catch (e) {
      return this;
    }
  }

  String toOptimized({String quality = 'auto', String format = 'auto'}) {
    try {
      final uri = Uri.parse(this);
      final pathSegments = uri.pathSegments.toList();

      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1) return this;

      pathSegments.insert(uploadIndex + 1, 'q_$quality,f_$format');

      return uri.replace(pathSegments: pathSegments).toString();
    } catch (e) {
      return this;
    }
  }
}
