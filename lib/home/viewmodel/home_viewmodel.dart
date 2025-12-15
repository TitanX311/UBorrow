import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/item_model.dart';

// ViewModel (Notifier)
class HomeViewModel extends Notifier<List<ItemModel>> {
  @override
  List<ItemModel> build() {
    return [
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
  }

  void addItem(ItemModel item) {
    state = [...state, item];
  }
}

// Provider
final homeViewModelProvider = NotifierProvider<HomeViewModel, List<ItemModel>>(HomeViewModel.new);
