import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uborrow/utils/constants.dart';
import '../../model/item_model.dart';
import '../../viewmodel/home_viewmodel.dart';

class AddItemScreen extends ConsumerWidget {
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  AddItemScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                    final newItem = ItemModel(
                        id: DateTime.now().toString(),
                        name: nameCtrl.text,
                        hostel: "My Hostel", // Ideally from user profile
                        image: AppConstants.placeholderImage, 
                        description: descCtrl.text,
                    );
                    ref.read(homeViewModelProvider.notifier).addItem(newItem);
                    Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
