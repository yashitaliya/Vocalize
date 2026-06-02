/// User model for Firestore
class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final List<String> interests;
  final String? selectedLanguage;
  final String? avatarUrl;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.interests = const [],
    this.selectedLanguage,
    this.avatarUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'interests': interests,
      'selectedLanguage': selectedLanguage,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'],
      interests: List<String>.from(map['interests'] ?? []),
      selectedLanguage: map['selectedLanguage'],
      avatarUrl: map['avatarUrl'],
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  UserModel copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? phoneNumber,
    List<String>? interests,
    String? selectedLanguage,
    String? avatarUrl,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      interests: interests ?? this.interests,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
