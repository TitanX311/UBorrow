import 'package:flutter/material.dart';
import '../../../home/view/widgets/item_card.dart';

class HomeScreen extends StatelessWidget {
  final items = [
    {
      "name": "Charger",
      "hostel": "Hall 3 - 219",
      "image": "https://i.imgur.com/QCNbOAo.png",
    },
    {
      "name": "Extension Board",
      "hostel": "Hall 2 - 105",
      "image": "https://i.imgur.com/aY8dFoa.png",
    },
    {
      "name": "Calculator",
      "hostel": "Hall 1 - 310",
      "image": "https://i.imgur.com/BS9xMTn.png",
    },
  ];

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Borrow Items"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, "/add"),
          ),
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, "/profile"),
          ),
        ],
      ),

      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: "Search charger, calculator...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 10),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                children: items
                    .map(
                      (item) => ItemCard(
                        item: item,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            "/item",
                            arguments: item,
                          );
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
