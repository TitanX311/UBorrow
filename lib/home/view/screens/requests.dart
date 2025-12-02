import 'package:flutter/material.dart';

class RequestsScreen extends StatelessWidget {
  final requests = [
    {"item": "Calculator", "from": "Amit", "status": "Pending"},
    {"item": "Helmet", "from": "You", "status": "Accepted"},
  ];

  RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Borrow Requests")),
      body: ListView.builder(
        itemCount: requests.length,
        itemBuilder: (context, i) {
          final r = requests[i];
          return Card(
            child: ListTile(
              title: Text(r["item"]!),
              subtitle: Text("From: ${r["from"]} • Status: ${r["status"]}"),
              trailing: r["status"] == "Pending"
                  ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: Icon(Icons.check), onPressed: () {}),
                  IconButton(icon: Icon(Icons.close), onPressed: () {}),
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
