import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uborrow/home/view/screens/add_item.dart';
import 'package:uborrow/home/view/screens/item_details.dart';
import 'package:uborrow/home/view/screens/notifications_screen.dart';
import 'package:uborrow/home/view/screens/requests.dart';
import 'package:uborrow/home/view/widgets/item_card.dart';
import 'package:uborrow/home/view/widgets/my_nested_scroll_view.dart';
import 'package:uborrow/home/view/widgets/notification_button.dart';
import 'package:uborrow/home/viewmodel/home_view_model.dart';
import 'package:uborrow/theme/app_colors.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _notificationCount = 0;
  String _searchQuery = '';
  String? _selectedCategory;

  final ScrollController _scrollController = ScrollController();

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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when 200px from bottom
      ref.read(homeViewModelProvider.notifier).loadMoreItems();
    }
  }

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
    final homeViewModel = ref.watch(homeViewModelProvider);
    final homeViewModelNotifier = ref.read(homeViewModelProvider.notifier);

    return MyNestedScrollView(
      // floatingActionButton: FloatingActionButton.extended(
      //   backgroundColor: Colors.redAccent,
      //   icon: const Icon(Icons.bug_report),
      //   label: const Text('Add 50 Debug Items'),
      //   onPressed: () {
      //     ref
      //         .read(homeViewModelProvider.notifier)
      //         .generateAndUploadDebugItems();
      //   },
      // ),
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
            child: homeViewModel.when(
              data: (items) {
                if (items.isEmpty) {
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

                final filteredItems = items.where((item) {
                  final matchesSearch =
                      _searchQuery.isEmpty ||
                      item.name.toLowerCase().contains(_searchQuery);
                  final matchesCategory =
                      _selectedCategory == null ||
                      item.category == _selectedCategory;

                  return matchesSearch && matchesCategory;
                }).toList();

                if (filteredItems.isEmpty) {
                  return const Center(
                    child: Text(
                      'No items match your search',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => homeViewModelNotifier.refresh(),
                  child: GridView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                        ),
                    itemCount:
                        filteredItems.length +
                        (homeViewModelNotifier.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == filteredItems.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final item = filteredItems[index];
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
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}
