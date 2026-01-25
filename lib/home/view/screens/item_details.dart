import 'package:flutter/material.dart';

class ItemDetailsScreen extends StatelessWidget {
  final Map item;

  const ItemDetailsScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(item["name"])),
      body: Column(
        children: [
          Image.network(item["image"], height: 250, fit: BoxFit.cover),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  item["name"],
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                if (item["description"] != "" ||
                    item["description"] != null) ...[
                  SizedBox(height: 10),
                  Text(item["description"]),
                ],
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.location_pin, color: Colors.blue),
                    Text(item["hostel"]),
                  ],
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  child: Text("Request to Borrow"),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
