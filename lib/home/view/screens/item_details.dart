import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:uborrow/home/model/borrow_request_model.dart';
import 'package:uborrow/utils/constants.dart';

class ItemDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const ItemDetailsScreen({super.key, required this.item});

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  final _periodController = TextEditingController();
  final _messageController = TextEditingController();
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  bool _isLoading = false;

  @override
  void dispose() {
    _periodController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendBorrowRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('Please sign in to send requests', isError: true);
      return;
    }

    // Check if user is trying to borrow their own item
    if (widget.item['ownerId'] == user.uid) {
      _showSnackBar('You cannot borrow your own item', isError: true);
      return;
    }

    final period = _periodController.text.trim();
    if (period.isEmpty) {
      _showSnackBar('Please enter borrowing period', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final ownerId = widget.item['ownerId'] as String? ?? '';
      final itemId = widget.item['id'] as String? ?? '';
      final itemName = widget.item['name'] as String? ?? 'Unknown Item';
      final ownerEmail = widget.item['ownerEmail'] as String? ?? '';

      if (ownerId.isEmpty) {
        throw Exception('Item owner not found');
      }

      final request = BorrowRequestModel(
        id: '',
        itemId: itemId,
        itemName: itemName,
        itemImage: widget.item['image'] ?? '',
        ownerId: ownerId,
        ownerEmail: ownerEmail,
        requesterId: user.uid,
        requesterEmail: user.email ?? '',
        period: period,
        message: _messageController.text.trim(),
        status: BorrowRequestStatus.pending,
      );

      final callable = _functions.httpsCallable('createBorrowRequest');
      await callable.call({...request.toMap()});

      _showSnackBar('Borrow request sent successfully!');
      Navigator.of(context).pop();
    } catch (e) {
      _showSnackBar('Error sending request: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showBorrowDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request to Borrow'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _periodController,
              decoration: const InputDecoration(
                labelText: 'Borrowing Period',
                hintText: 'e.g., 2 days, 1 week',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message (Optional)',
                hintText: 'Add a message to the owner',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _sendBorrowRequest();
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isOwner = user?.uid == widget.item['ownerId'];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background:
                  widget.item['image'] != null &&
                      widget.item['image'].isNotEmpty
                  ? Image.network(
                      widget.item['image'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, size: 64),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.inventory_2, size: 64),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Name
                  Text(
                    widget.item['name'] ?? 'Unknown Item',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Category Chip
                  if (widget.item['category'] != null)
                    Chip(
                      label: Text(widget.item['category']),
                      avatar: const Icon(Icons.category, size: 18),
                    ),
                  const SizedBox(height: 16),

                  // Availability Status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: (widget.item['available'] ?? true)
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (widget.item['available'] ?? true)
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          (widget.item['available'] ?? true)
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: (widget.item['available'] ?? true)
                              ? Colors.green
                              : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          (widget.item['available'] ?? true)
                              ? 'Available'
                              : 'Not Available',
                          style: TextStyle(
                            color: (widget.item['available'] ?? true)
                                ? Colors.green.shade900
                                : Colors.red.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Location
                  _buildInfoRow(
                    Icons.location_on,
                    'Location',
                    widget.item['hostel'] ?? 'Not specified',
                  ),
                  const SizedBox(height: 16),

                  // Owner
                  _buildInfoRow(
                    Icons.person,
                    'Owner',
                    widget.item['ownerEmail'] ?? 'Unknown',
                  ),
                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.item['description'] ?? 'No description available',
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 100), // Space for FAB
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: !isOwner && (widget.item['available'] ?? true)
          ? FloatingActionButton.extended(
              onPressed: _isLoading ? null : _showBorrowDialog,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.handshake),
              label: const Text('Request to Borrow'),
            )
          : null,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[700]),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }
}
