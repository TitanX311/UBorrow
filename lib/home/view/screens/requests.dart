import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uborrow/utils/constants.dart';

class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});

  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen> {
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
      appBar: AppBar(title: const Text("Need Requests"), elevation: 0),

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
      final docRef = await FirebaseFirestore.instance
          .collection(AppCollections.needRequests)
          .add({
            'itemName': itemName,
            'period': period,
            'message': message,
            'requesterId': user.uid,
            'requesterEmail': user.email ?? '',
            'status': NeedRequestStatus.open,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Keep this client write simple; backend trigger handles fanout notifications.
      if (docRef.id.isEmpty) {
        _showSnackBar('Failed to post request', isError: true);
        return;
      }

      _showSnackBar('Request posted successfully');
    } catch (e) {
      _showSnackBar('Failed to post request', isError: true);
    }
  }

  /// 🔹 Main Requests Section (similar role to AddItemScreen body)
  Widget _buildRequestsSection(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppCollections.needRequests)
          .where('requesterId', isEqualTo: userId)
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

        final docs = snapshot.data!.docs.toList()
          ..sort(
            (a, b) => _compareByCreatedAtDescending(
              a.data() as Map<String, dynamic>,
              b.data() as Map<String, dynamic>,
            ),
          );

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            return _buildRequestCard(data: doc.data() as Map<String, dynamic>);
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
            'No need requests yet',
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

  Widget _buildRequestCard({required Map<String, dynamic> data}) {
    // final cloudinaryService = ref.watch(cloudinaryServiceProvider);

    final status = data['status'] ?? NeedRequestStatus.open;
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

                  const SizedBox(height: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _compareByCreatedAtDescending(
    Map<String, dynamic> left,
    Map<String, dynamic> right,
  ) {
    final leftCreatedAt = left['createdAt'];
    final rightCreatedAt = right['createdAt'];

    final leftMillis = leftCreatedAt is Timestamp
        ? leftCreatedAt.millisecondsSinceEpoch
        : 0;
    final rightMillis = rightCreatedAt is Timestamp
        ? rightCreatedAt.millisecondsSinceEpoch
        : 0;

    return rightMillis.compareTo(leftMillis);
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

  Color _getStatusColor(String status) {
    switch (status) {
      case NeedRequestStatus.fulfilled:
        return Colors.green.shade100;
      case NeedRequestStatus.closed:
        return Colors.red.shade100;
      case NeedRequestStatus.matched:
        return Colors.blue.shade100;
      case NeedRequestStatus.open:
      default:
        return Colors.orange.shade100;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case NeedRequestStatus.fulfilled:
        return Colors.green.shade900;
      case NeedRequestStatus.closed:
        return Colors.red.shade900;
      case NeedRequestStatus.matched:
        return Colors.blue.shade900;
      case NeedRequestStatus.open:
      default:
        return Colors.orange.shade900;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case NeedRequestStatus.fulfilled:
        return Icons.check_circle;
      case NeedRequestStatus.closed:
        return Icons.cancel;
      case NeedRequestStatus.matched:
        return Icons.done_all;
      case NeedRequestStatus.open:
      default:
        return Icons.hourglass_empty;
    }
  }
}
