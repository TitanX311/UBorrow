import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uborrow/home/view/screens/requests.dart';
import 'package:uborrow/home/viewmodel/home_viewmodel.dart';
import '../../../home/view/widgets/item_card.dart';

class HomeScreen extends ConsumerWidget {
  HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(homeViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text("Borrow Items"),
        actions: [
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
                        item: {
                          'name': item.name,
                          'hostel': item.hostel,
                          'image': item.image,
                        },
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            "/item",
                            arguments: {
                              'name': item.name,
                              'hostel': item.hostel,
                              'image': item.image,
                              'description': item.description,
                            },
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
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
          openButtonBuilder: RotateFloatingActionButtonBuilder(
            child: const Icon(Icons.add),
          ),
          children: [
        FloatingActionButton(
          // shape: const CircleBorder(),
          heroTag: null,
          child: const Text("Request"),
          onPressed: () => Navigator.pushNamed(context, "/requests"),
        ),
        FloatingActionButton(
          // shape: const CircleBorder(),
          heroTag: null,
          child: const Text("Add"),
          onPressed: () => Navigator.pushNamed(context, "/add"),
        ),
      ]),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Courses'),
          BottomNavigationBarItem(
            icon: Icon(Icons.contact_mail),
            label: 'Mail',
          ),
        ],
      ),
    );
  }
}
