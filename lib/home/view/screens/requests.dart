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

class _RequestsScreenState extends ConsumerState<RequestsScreen> {
  Future<void> _acceptRequest(String requestId, String itemId) async {
    try {
      await FirebaseFirestore.instance
          .collection('item_requests')
          .doc(requestId)
          .update({
            'status': 'Accepted',
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (itemId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('items').doc(itemId).update(
          {'available': false},
        );
      }

      _showSnackBar('Request accepted');
    } catch (e) {
      _showSnackBar('Failed to accept request', isError: true);
    }
  }

  Future<void> _declineRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('item_requests')
          .doc(requestId)
          .update({
            'status': 'Declined',
            'updatedAt': FieldValue.serverTimestamp(),
          });

      _showSnackBar('Request declined');
    } catch (e) {
      _showSnackBar('Failed to decline request', isError: true);
    }
  }

  Future<void> _completeRequest(String requestId, String itemId) async {
    try {
      await FirebaseFirestore.instance
          .collection('item_requests')
          .doc(requestId)
          .update({
            'status': 'Completed',
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (itemId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('items').doc(itemId).update(
          {'available': true},
        );
      }

      _showSnackBar('Request marked as completed');
    } catch (e) {
      _showSnackBar('Failed to complete request', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

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

    return Scaffold(
      appBar: AppBar(title: const Text("Borrow Requests"), elevation: 0),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddNeedRequestSheet,
        icon: const Icon(Icons.add),
        label: const Text("Request Item"),
      ),

      body: user == null
          ? const Center(child: Text("Please sign in"))
          : _buildRequestsSection(user.uid),
    );
  }

  void _showAddNeedRequestSheet() {
    final itemCtrl = TextEditingController();
    final periodCtrl = TextEditingController();
    final messageCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Request an Item",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: itemCtrl,
                decoration: const InputDecoration(
                  labelText: "Item name",
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: periodCtrl,
                decoration: const InputDecoration(
                  labelText: "Required period",
                  hintText: "e.g. 2 days",
                  prefixIcon: Icon(Icons.access_time),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: messageCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Message (optional)",
                  prefixIcon: Icon(Icons.message_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () async {
                  if (itemCtrl.text.trim().isEmpty ||
                      periodCtrl.text.trim().isEmpty) {
                    _showSnackBar("Please fill required fields", isError: true);
                    return;
                  }

                  Navigator.pop(context);
                  await _createNeedRequest(
                    itemCtrl.text.trim(),
                    periodCtrl.text.trim(),
                    messageCtrl.text.trim(),
                  );
                },
                child: const Text("Post Request"),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createNeedRequest(
    String itemName,
    String period,
    String message,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('item_requests').add({
        'itemName': itemName,
        'period': period,
        'message': message,
        'requesterId': user.uid,
        'requesterEmail': user.email ?? '',
        'status': 'Open', // Open → Matched → Fulfilled
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showSnackBar('Request posted successfully');
    } catch (e) {
      _showSnackBar('Failed to post request', isError: true);
    }
  }

  /// 🔹 Main Requests Section (similar role to AddItemScreen body)
  Widget _buildRequestsSection(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('item_requests')
          .where('requesterId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _errorState(snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _emptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            return _buildRequestCard(
              data: doc.data() as Map<String, dynamic>,
              requestId: doc.id,
            );
          },
        );
      },
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No borrow requests yet',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _errorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(error),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard({
    required Map<String, dynamic> data,
    required String requestId,
  }) {
    // final cloudinaryService = ref.watch(cloudinaryServiceProvider);

    final status = data['status'] ?? 'Pending';
    final itemId = data['itemId'] ?? '';
    // final itemImageUrl = data['itemImage'] as String?;

    // String? thumbnailUrl;
    // if (itemImageUrl != null && itemImageUrl.isNotEmpty) {
    //   thumbnailUrl = cloudinaryService.getThumbnailUrl(
    //     itemImageUrl,
    //     width: 80,
    //     height: 80,
    //   );
    // }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item name
                  Text(
                    data['itemName'] ?? 'Unknown Item',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Requester
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          data['requesterEmail'] ?? 'Unknown requester',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

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
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Status chip + message
                  Row(
                    children: [
                      _statusChip(status),
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

                  // Actions
                  if (status == 'Pending')
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

                  if (status == 'Accepted')
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

  Widget _statusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    );
  }

  Widget _buildDefaultImage() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        size: 40,
        color: Colors.grey[400],
      ),
    );
  }

  Color _getStatusColor(String status) {
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

  Color _getStatusTextColor(String status) {
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

  IconData _getStatusIcon(String status) {
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
