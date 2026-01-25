class ItemModel {
  final String id;
  final String name;
  final String hostel;
  final String image;
  final String? description;

  //<editor-fold desc="Data Methods">
  const ItemModel({
    required this.id,
    required this.name,
    required this.hostel,
    required this.image,
    this.description,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          hostel == other.hostel &&
          image == other.image &&
          description == other.description);

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      hostel.hashCode ^
      image.hashCode ^
      description.hashCode;

  @override
  String toString() {
    return 'ItemModel{' +
        ' id: $id,' +
        ' name: $name,' +
        ' hostel: $hostel,' +
        ' image: $image,' +
        ' description: $description,' +
        '}';
  }

  ItemModel copyWith({
    String? id,
    String? name,
    String? hostel,
    String? image,
    String? description,
  }) {
    return ItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      hostel: hostel ?? this.hostel,
      image: image ?? this.image,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': this.id,
      'name': this.name,
      'hostel': this.hostel,
      'image': this.image,
      'description': this.description,
    };
  }

  factory ItemModel.fromMap(Map<String, dynamic> map) {
    return ItemModel(
      id: map['id'] as String,
      name: map['name'] as String,
      hostel: map['hostel'] as String,
      image: map['image'] as String,
      description: map['description'] as String,
    );
  }

  //</editor-fold>
}
