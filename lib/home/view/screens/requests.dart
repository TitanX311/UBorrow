import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodel/requests_viewmodel.dart';

class RequestsScreen extends ConsumerWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(requestsViewModelProvider);
    final requestsViewModel = ref.read(requestsViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text("Borrow Requests")),
      body: ListView.builder(
        itemCount: requests.length,
        itemBuilder: (context, i) {
          final r = requests[i];
          return Card(
            child: ListTile(
              title: Text(r.item),
              subtitle: Text("From: ${r.from} • Status: ${r.status}"),
              trailing: r.status == "Pending"
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.check),
                          onPressed: () {
                            requestsViewModel.acceptRequest(r.id);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () {
                            requestsViewModel.declineRequest(r.id);
                          },
                        ),
                      ],
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
