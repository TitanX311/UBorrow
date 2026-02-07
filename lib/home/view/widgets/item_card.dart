import 'package:flutter/material.dart';

class ItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const ItemCard({super.key, required this.item, required this.onTap});

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

  Widget _buildImage() {
    final imageUrl = item['image'] as String?;
    final category = item['category'] as String?;
    final available = item['available'] as bool? ?? true;

    Widget imageWidget;

    if (imageUrl == null || imageUrl.isEmpty) {
      // Show default image with category icon
      imageWidget = Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getCategoryColor(category),
              _getCategoryColor(category).withOpacity(0.7),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            _getCategoryIcon(category),
            size: 60,
            color: Colors.grey[600],
          ),
        ),
      );
    } else {
      // Show network image
      imageWidget = Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;

          return Container(
            color: _getCategoryColor(category),
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
          // Fallback to default image on error
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getCategoryColor(category),
                  _getCategoryColor(category).withOpacity(0.7),
                ],
              ),
            ),
            child: Center(
              child: Icon(
                _getCategoryIcon(category),
                size: 60,
                color: Colors.grey[600],
              ),
            ),
          );
        },
      );
    }

    // Add unavailable overlay if not available
    if (!available) {
      imageWidget = Stack(
        children: [
          imageWidget,
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.block, color: Colors.white, size: 40),
                    SizedBox(height: 8),
                    Text(
                      'Not Available',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return imageWidget;
  }

  @override
  Widget build(BuildContext context) {
    final name = item['name'] as String? ?? 'Unknown Item';
    final hostel = item['hostel'] as String? ?? 'Location not specified';
    final category = item['category'] as String?;
    final available = item['available'] as bool? ?? true;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: SizedBox(width: double.infinity, child: _buildImage()),
              ),
            ),

            // Info Section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Item Name
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Category chip (if available)
                    if (category != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(category).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            hostel,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // Availability indicator
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: available ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          available ? 'Available' : 'Not Available',
                          style: TextStyle(
                            color: available ? Colors.green : Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
