import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uborrow/core/repository/cloudinary_provider.dart';
import 'package:uborrow/home/model/request_model.dart';

class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});

  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _acceptRequest(String requestId, String itemId) async {
    try {
      // Update request status
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .update({
            'status': 'Accepted',
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Update item availability
      if (itemId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('items').doc(itemId).update(
          {'available': false},
        );
      }

      _showSnackBar('Request accepted');
    } catch (e) {
      _showSnackBar('Error accepting request: $e', isError: true);
    }
  }

  Future<void> _declineRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .update({
            'status': 'Declined',
            'updatedAt': FieldValue.serverTimestamp(),
          });

      _showSnackBar('Request declined');
    } catch (e) {
      _showSnackBar('Error declining request: $e', isError: true);
    }
  }

  Future<void> _completeRequest(String requestId, String itemId) async {
    try {
      // Update request status
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .update({
            'status': 'Completed',
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Make item available again
      if (itemId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('items').doc(itemId).update(
          {'available': true},
        );
      }

      _showSnackBar('Request marked as completed');
    } catch (e) {
      _showSnackBar('Error completing request: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Borrow Requests"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Received", icon: Icon(Icons.inbox)),
            Tab(text: "Sent", icon: Icon(Icons.send)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Received Requests (requests for items you own)
          _buildReceivedRequests(user?.uid),
          // Sent Requests (requests you made for others' items)
          _buildSentRequests(user?.uid),
        ],
      ),
    );
  }

  Widget _buildReceivedRequests(String? userId) {
    if (userId == null) {
      return const Center(child: Text("Please sign in"));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .where('ownerId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No requests received yet',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        // Sort requests manually by createdAt
        final requests = snapshot.data!.docs;
        requests.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['createdAt'] as Timestamp?;
          final bTime = bData['createdAt'] as Timestamp?;

          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime); // Descending order
        });

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final requestDoc = requests[index];
            final data = requestDoc.data() as Map<String, dynamic>;
            final requestId = requestDoc.id;

            return _buildRequestCard(
              data: data,
              requestId: requestId,
              isReceived: true,
            );
          },
        );
      },
    );
  }

  Widget _buildSentRequests(String? userId) {
    if (userId == null) {
      return const Center(child: Text("Please sign in"));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .where('requesterId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No requests sent yet',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        // Sort requests manually by createdAt
        final requests = snapshot.data!.docs;
        requests.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['createdAt'] as Timestamp?;
          final bTime = bData['createdAt'] as Timestamp?;

          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime); // Descending order
        });

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final requestDoc = requests[index];
            final data = requestDoc.data() as Map<String, dynamic>;
            final requestId = requestDoc.id;

            return _buildRequestCard(
              data: data,
              requestId: requestId,
              isReceived: false,
            );
          },
        );
      },
    );
  }

  Widget _buildRequestCard({
    required Map<String, dynamic> data,
    required String requestId,
    required bool isReceived,
  }) {
    final cloudinaryService = ref.watch(cloudinaryServiceProvider);
    final itemImageUrl = data['itemImage'] as String?;
    final status = data['status'] ?? 'Pending';
    final itemId = data['itemId'] ?? '';

    // Get thumbnail URL if image exists
    String? thumbnailUrl;
    if (itemImageUrl != null && itemImageUrl.isNotEmpty) {
      thumbnailUrl = cloudinaryService.getThumbnailUrl(
        itemImageUrl,
        width: 80,
        height: 80,
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: thumbnailUrl != null
                  ? Image.network(
                      thumbnailUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultImage();
                      },
                    )
                  : _buildDefaultImage(),
            ),
            const SizedBox(width: 12),

            // Request Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Name
                  Text(
                    data['itemName'] ?? 'Unknown Item',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // User Info
                  Row(
                    children: [
                      Icon(
                        isReceived ? Icons.person : Icons.person_outline,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          isReceived
                              ? 'From: ${data['requesterEmail'] ?? 'Unknown'}'
                              : 'To: ${data['ownerEmail'] ?? 'Unknown'}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Period
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        data['period'] ?? 'Not specified',
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Status & Message
                  Row(
                    children: [
                      // Status Chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(status),
                              size: 14,
                              color: _getStatusTextColor(status),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              status,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getStatusTextColor(status),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Show message if exists
                      if (data['message'] != null &&
                          (data['message'] as String).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Tooltip(
                            message: data['message'],
                            child: Icon(
                              Icons.message,
                              size: 16,
                              color: Colors.blue[400],
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Action Buttons for Received Requests
                  if (isReceived && status == 'Pending')
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _acceptRequest(requestId, itemId),
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Accept'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _declineRequest(requestId),
                              icon: const Icon(Icons.close, size: 18),
                              label: const Text('Decline'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Complete Button for Accepted Requests
                  if (isReceived && status == 'Accepted')
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _completeRequest(requestId, itemId),
                          icon: const Icon(Icons.done_all, size: 18),
                          label: const Text('Mark as Completed'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultImage() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[200]!, Colors.grey[300]!],
        ),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        size: 40,
        color: Colors.grey[400],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Accepted':
        return Colors.green.shade100;
      case 'Declined':
        return Colors.red.shade100;
      case 'Completed':
        return Colors.blue.shade100;
      case 'Pending':
      default:
        return Colors.orange.shade100;
    }
  }

  Color _getStatusTextColor(String? status) {
    switch (status) {
      case 'Accepted':
        return Colors.green.shade900;
      case 'Declined':
        return Colors.red.shade900;
      case 'Completed':
        return Colors.blue.shade900;
      case 'Pending':
      default:
        return Colors.orange.shade900;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'Accepted':
        return Icons.check_circle;
      case 'Declined':
        return Icons.cancel;
      case 'Completed':
        return Icons.done_all;
      case 'Pending':
      default:
        return Icons.hourglass_empty;
    }
  }
}
