import 'package:flutter/material.dart';
import 'package:uborrow/home/model/request_model.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  final List<RequestModel> _requests = [
    RequestModel(id: '1', item: "Calculator", from: "Amit", status: "Pending"),
    RequestModel(id: '2', item: "Helmet", from: "You", status: "Accepted"),
  ];

  // void _acceptRequest(String id) {
  //   setState(() {
  //     _requests.firstWhere((r) => r.id == id).status = "Accepted";
  //   });
  // }
  //
  // void _declineRequest(String id) {
  //   setState(() {
  //     _requests.removeWhere((r) => r.id == id);
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Borrow Requests")),
      body: ListView.builder(
        itemCount: _requests.length,
        itemBuilder: (context, i) {
          final r = _requests[i];
          return Card(
            child: ListTile(
              title: Text(r.item),
              subtitle: Text("From: ${r.from} • Status: ${r.status}"),
              trailing: r.status == "Pending"
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {},
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
