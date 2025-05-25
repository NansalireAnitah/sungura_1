class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String? profileImageUrl;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.profileImageUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'user',
      profileImageUrl: data['profileImageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'profileImageUrl': profileImageUrl,
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? role,
    String? profileImageUrl,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }

  updateEmail(String trim) {}

  updatePassword(String text) {}
}