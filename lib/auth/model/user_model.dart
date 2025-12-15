class UserModel {
  final String id;
  final String email;
  final String? name;
  final String? photoUrl;

  //<editor-fold desc="Data Methods">

  const UserModel({
    required this.id,
    required this.email,
    this.name,
    this.photoUrl,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          name == other.name &&
          photoUrl == other.photoUrl);

  @override
  int get hashCode =>
      id.hashCode ^ email.hashCode ^ name.hashCode ^ photoUrl.hashCode;

  @override
  String toString() {
    return 'UserModel{' +
        ' id: $id,' +
        ' email: $email,' +
        ' name: $name,' +
        ' photoUrl: $photoUrl,' +
        '}';
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': this.id,
      'email': this.email,
      'name': this.name,
      'photoUrl': this.photoUrl,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      email: map['email'] as String,
      name: map['name'] as String,
      photoUrl: map['photoUrl'] as String,
    );
  }

  //</editor-fold>
}
