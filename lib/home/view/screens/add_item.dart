import 'package:flutter/material.dart';

class AddItemScreen extends StatelessWidget {
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  AddItemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Item")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: "Item Name", border: OutlineInputBorder()),
            ),
            SizedBox(height: 15),
            TextField(
              controller: descCtrl,
              decoration: InputDecoration(labelText: "Description", border: OutlineInputBorder()),
              maxLines: 3,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text("Add Item"),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
