import 'package:flutter/material.dart';

class DefaultImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData defaultIcon;
  final Color? defaultBackgroundColor;
  final Color? defaultIconColor;

  const DefaultImageWidget({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.defaultIcon = Icons.inventory_2_outlined,
    this.defaultBackgroundColor,
    this.defaultIconColor,
  });

  @override
  Widget build(BuildContext context) {
    // Check if image URL is null or empty
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildDefaultImage(context);
    }

    // Show network image with error fallback
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;

          return Container(
            width: width,
            height: height,
            color: defaultBackgroundColor ?? Colors.grey[200],
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
          return _buildDefaultImage(context);
        },
      ),
    );
  }

  Widget _buildDefaultImage(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: defaultBackgroundColor ?? Colors.grey[200],
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (defaultBackgroundColor ?? Colors.grey[200])!,
            (defaultBackgroundColor ?? Colors.grey[300])!,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          defaultIcon,
          size: (width != null && height != null) ? (width! + height!) / 8 : 50,
          color: defaultIconColor ?? Colors.grey[400],
        ),
      ),
    );
  }
}

/// Alternative: Default image with category-specific icons
class CategoryDefaultImage extends StatelessWidget {
  final String? imageUrl;
  final String? category;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const CategoryDefaultImage({
    super.key,
    this.imageUrl,
    this.category,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'electronics':
        return Icons.devices;
      case 'books':
        return Icons.menu_book;
      case 'sports equipment':
        return Icons.sports_basketball;
      case 'musical instruments':
        return Icons.music_note;
      case 'tools':
        return Icons.build;
      case 'kitchen items':
        return Icons.kitchen;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'electronics':
        return Colors.blue.shade100;
      case 'books':
        return Colors.orange.shade100;
      case 'sports equipment':
        return Colors.green.shade100;
      case 'musical instruments':
        return Colors.purple.shade100;
      case 'tools':
        return Colors.grey.shade300;
      case 'kitchen items':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: _getCategoryColor(category),
          borderRadius: borderRadius,
        ),
        child: Center(
          child: Icon(
            _getCategoryIcon(category),
            size: (width != null && height != null)
                ? (width! + height!) / 8
                : 50,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;

          return Container(
            width: width,
            height: height,
            color: _getCategoryColor(category),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: _getCategoryColor(category),
              borderRadius: borderRadius,
            ),
            child: Center(
              child: Icon(
                _getCategoryIcon(category),
                size: (width != null && height != null)
                    ? (width! + height!) / 8
                    : 50,
                color: Colors.grey[600],
              ),
            ),
          );
        },
      ),
    );
  }
}
