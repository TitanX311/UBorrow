import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uborrow/home/model/item_model.dart';
import 'package:uborrow/home/view/screens/add_item.dart';
import 'package:uborrow/home/view/screens/item_details.dart';
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
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('items').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("nothing to show"));
            }

            final items = snapshot.data!.docs;

            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final itemDoc = items[index];
                final item = ItemModel.fromMap(
                  itemDoc.data() as Map<String, dynamic>,
                );
                final imageUrl = item.image;

                return ItemCard(
                  item: {
                    'name': item.name,
                    'hostel': item.hostel,
                    'image': imageUrl,
                  },
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            ItemDetailsScreen(item: item.toMap()),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        openButtonBuilder: RotateFloatingActionButtonBuilder(
          child: const Icon(Icons.add),
        ),
        children: [
          FloatingActionButton(
            heroTag: null,
            child: const Icon(Icons.handshake_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const RequestsScreen()),
            ),
          ),
          FloatingActionButton(
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
