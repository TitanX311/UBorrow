// import 'package:flutter/material.dart';
// import 'package:uborrow/data/mock_items.dart';
// import 'package:uborrow/home/view/widgets/item_card.dart';
// import 'package:uborrow/home/view/widgets/my_nested_scroll_view.dart';
//
// class SearchItems extends StatefulWidget {
//   const SearchItems({super.key});
//
//   @override
//   State<SearchItems> createState() => _SearchItemsState();
// }
//
// class _SearchItemsState extends State<SearchItems> {
//   String _query = "";
//
//   @override
//   Widget build(BuildContext context) {
//     final filteredItems = mockItems.where((item) {
//       return item.name.toLowerCase().contains(_query.toLowerCase()) ||
//           item.hostel.toLowerCase().contains(_query.toLowerCase());
//     }).toList();
//
//     return MyNestedScrollView(
//       title: const Text("Search Items"),
//       body: Column(
//         children: [
//           // 🔍 Search Bar
//           Padding(
//             padding: const EdgeInsets.all(12),
//             child: TextField(
//               autofocus: true,
//               decoration: InputDecoration(
//                 hintText: "Search by item...",
//                 prefixIcon: const Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               onChanged: (value) {
//                 setState(() {
//                   _query = value;
//                 });
//               },
//             ),
//           ),
//
//           // 📦 Results
//           Expanded(
//             child: filteredItems.isEmpty
//                 ? const Center(
//                     child: Text(
//                       "No items found",
//                       style: TextStyle(fontSize: 16),
//                     ),
//                   )
//                 : GridView.builder(
//                     padding: const EdgeInsets.all(12),
//                     gridDelegate:
//                         const SliverGridDelegateWithFixedCrossAxisCount(
//                       crossAxisCount: 2,
//                       childAspectRatio: 0.8,
//                       crossAxisSpacing: 12,
//                       mainAxisSpacing: 12,
//                     ),
//                     itemCount: filteredItems.length,
//                     itemBuilder: (_, index) {
//                       final item = filteredItems[index];
//                       return ItemCard(
//                         item: {
//                           'name': item.name,
//                           'hostel': item.hostel,
//                           'image': item.image,
//                         },
//                         onTap: () {
//                           Navigator.pushNamed(
//                             context,
//                             "/item",
//                             arguments: {
//                               'name': item.name,
//                               'hostel': item.hostel,
//                               'image': item.image,
//                               'description': item.description,
//                             },
//                           );
//                         },
//                       );
//                     },
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
// }
