import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uborrow/home/model/item_model.dart';
import 'package:uborrow/home/view/screens/add_item.dart';
import 'package:uborrow/home/view/screens/requests.dart';
import 'package:uborrow/home/view/widgets/item_card.dart';
import 'package:uborrow/home/view/widgets/my_nested_scroll_view.dart';
import 'package:uborrow/home/view/widgets/notification_button.dart';
import 'package:uborrow/theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _notificationCount = 0;
  final List<ItemModel> _items = [
    ItemModel(
      id: '1',
      name: "Charger",
      hostel: "Hall 3 - 219",
      image: "https://i.imgur.com/QCNbOAo.png",
    ),
    ItemModel(
      id: '2',
      name: "Extension Board",
      hostel: "Hall 2 - 105",
      image: "https://i.imgur.com/aY8dFoa.png",
    ),
    ItemModel(
      id: '3',
      name: "Calculator",
      hostel: "Hall 1 - 310",
      image: "https://i.imgur.com/BS9xMTn.png",
    ),
  ];

  void _incrementCount() {
    setState(() {
      _notificationCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MyNestedScrollView(
      title: Text(
        "uBorrow",
        style: GoogleFonts.pacifico(
          textStyle: const TextStyle(color: AppColors.blue),
        ),
      ),
      actions: [
        NotificationButton(
          onPressed: _incrementCount,
          notificationCount: _notificationCount,
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            Flexible(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                children: _items
                    .map(
                      (item) => ItemCard(
                        item: {
                          'name': item.name,
                          'hostel': item.hostel,
                          'image': item.image,
                        },
                        onTap: () {
                          Navigator.of(
                            context,
                            rootNavigator: true,
                          ).pushNamed(
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
            child: const Icon(Icons.handshake_outlined),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => const RequestsScreen())),
          ),
          FloatingActionButton(
            // shape: const CircleBorder(),
            heroTag: null,
            child: const Icon(Icons.add),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => AddItemScreen())),
          ),
        ],
      ),
    );
  }
}
