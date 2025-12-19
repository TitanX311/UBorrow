class MockItem {
  final String name;
  final String hostel;
  final String image;
  final String description;

  MockItem({
    required this.name,
    required this.hostel,
    required this.image,
    required this.description,
  });
}

final List<MockItem> mockItems = [
  MockItem(
    name: "Physics Book",
    hostel: "Hostel A",
    image: "https://via.placeholder.com/150",
    description: "Class 12 physics book in good condition",
  ),
  MockItem(
    name: "Calculator",
    hostel: "Hostel B",
    image: "https://via.placeholder.com/150",
    description: "Casio calculator, works perfectly",
  ),
  MockItem(
    name: "Cycle",
    hostel: "Hostel C",
    image: "https://via.placeholder.com/150",
    description: "Mountain bike available for borrowing",
  ),
  MockItem(
    name: "Laptop Stand",
    hostel: "Hostel A",
    image: "https://via.placeholder.com/150",
    description: "Adjustable laptop stand",
  ),
];
