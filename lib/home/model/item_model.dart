class ItemModel {
  final String id;
  final String name;
  final String hostel;
  final String image;
  final String? description;

  ItemModel({
    required this.id,
    required this.name,
    required this.hostel,
    required this.image,
    this.description,
  });
}
