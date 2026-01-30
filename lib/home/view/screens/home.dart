import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uborrow/home/model/item_model.dart';
import 'package:uborrow/home/view/screens/add_item.dart';
import 'package:uborrow/home/view/screens/item_details.dart';
import 'package:uborrow/home/view/screens/notifications_screen.dart';
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
  String _searchQuery = '';
  String? _selectedCategory;

  final List<String> _categories = [
    'All',
    'Electronics',
    'Books',
    'Sports Equipment',
    'Musical Instruments',
    'Tools',
    'Kitchen Items',
    'Other',
  ];

  void _buildPopUpMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),

              // Drag handle (optional but feels premium)
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 16),

              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text("Add"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AddItemScreen(),
                    ),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.request_page_outlined),
                title: const Text("Request"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const RequestsScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MyNestedScrollView(
      title: Row(
        children: [
          IconButton(
            onPressed: () => _buildPopUpMenu(context),
            icon: Icon(Icons.add),
          ),
          Spacer(),
          Text(
            "uBorrow",
            style: GoogleFonts.pacifico(
              textStyle: const TextStyle(color: AppColors.blue),
            ),
          ),
          Spacer(),
        ],
      ),
      actions: [
        NotificationButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            );
          },
          notificationCount: _notificationCount,
        ),
      ],
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search items...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),

          // Category Filter
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected =
                    _selectedCategory == category ||
                    (category == 'All' && _selectedCategory == null);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category == 'All' ? null : category;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          // Items Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('items')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No items available yet',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  // Filter items based on search and category
                  final items = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['name'] ?? '').toLowerCase();
                    final category = data['category'] ?? '';

                    final matchesSearch =
                        _searchQuery.isEmpty || name.contains(_searchQuery);
                    final matchesCategory =
                        _selectedCategory == null ||
                        category == _selectedCategory;

                    return matchesSearch && matchesCategory;
                  }).toList();

                  if (items.isEmpty) {
                    return const Center(
                      child: Text(
                        'No items match your search',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                        ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final itemDoc = items[index];
                      final itemData = itemDoc.data() as Map<String, dynamic>;

                      // Create ItemModel with document ID
                      final item = ItemModel.fromMap(
                        itemData,
                        documentId: itemDoc.id,
                      );

                      // Use default image if image URL is empty
                      final imageUrl = item.image.isEmpty
                          ? 'https://via.placeholder.com/400x400.png?text=No+Image'
                          : item.image;

                      return ItemCard(
                        item: {
                          'name': item.name,
                          'hostel': item.hostel,
                          'image': imageUrl,
                          'category': item.category,
                          'available': item.available,
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
          ),
        ],
      ),
      // floatingActionButtonLocation: ExpandableFab.location,
      // floatingActionButton: ExpandableFab(
      //   openButtonBuilder: RotateFloatingActionButtonBuilder(
      //     child: const Icon(Icons.add),
      //   ),
      //   children: [
      //     FloatingActionButton(
      //       heroTag: null,
      //       child: const Icon(Icons.handshake_outlined),
      //       onPressed: () => Navigator.of(context).push(
      //         MaterialPageRoute(builder: (context) => const RequestsScreen()),
      //       ),
      //     ),
      //     FloatingActionButton(
      //       heroTag: null,
      //       child: const Icon(Icons.add),
      //       onPressed: () => Navigator.of(context).push(
      //         MaterialPageRoute(builder: (context) => const AddItemScreen()),
      //       ),
      //     ),
      //   ],
      // ),
    );
  }
}
