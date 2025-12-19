import 'package:flutter/material.dart';

class ItemCard extends StatelessWidget {
  final Map item;
  final VoidCallback onTap;

  const ItemCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.all(8),
        elevation: 2,
        child: Column(
          children: [
            Expanded(
              // child: Image.network(item["image"], fit: BoxFit.cover),
              child: Placeholder(),
            ),
            SizedBox(height: 6),
            Text(item["name"], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(item["hostel"], style: TextStyle(fontSize: 12)),
            SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
