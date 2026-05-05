class UserModel {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final int contributionCount;  // places added
  final int reviewCount;        // reviews written
  final bool isSuperUser;       // earned by contributing a lot
  final List<String> savedPlaces; // IDs of pinned places

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl = '',
    this.contributionCount = 0,
    this.reviewCount = 0,
    this.isSuperUser = false,
    this.savedPlaces = const [],
  });

  // Convert Firestore document → UserModel
  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      contributionCount: data['contributionCount'] ?? 0,
      reviewCount: data['reviewCount'] ?? 0,
      isSuperUser: data['isSuperUser'] ?? false,
      savedPlaces: List<String>.from(data['savedPlaces'] ?? []),
    );
  }

  // Convert UserModel → Firestore document
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'contributionCount': contributionCount,
      'reviewCount': reviewCount,
      'isSuperUser': isSuperUser,
      'savedPlaces': savedPlaces,
    };
  }

  // Returns initials for avatar placeholder (e.g. "Sara Mohamed" → "SM")
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  // Super user logic: 5+ contributions OR 10+ reviews
  bool get qualifiesAsSuperUser {
    return contributionCount >= 5 || reviewCount >= 10;
  }
}