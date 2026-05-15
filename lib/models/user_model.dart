class UserModel {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final int contributionCount;
  final int reviewCount;
  final bool isSuperUser;
  final List<String> savedPlaces;
  final bool chatPrivacyEnabled;  // NEW — false = anyone can chat, true = no one can
  final int pinCount;             // NEW — for monetization (free limit)

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl = '',
    this.contributionCount = 0,
    this.reviewCount = 0,
    this.isSuperUser = false,
    this.savedPlaces = const [],
    this.chatPrivacyEnabled = false,  // NEW — chat open by default
    this.pinCount = 0,                // NEW
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    final resolvedName =
        (data['name'] ?? data['fullName'] ?? data['displayName'] ?? data['username'] ?? data['userName'] ?? '')
            .toString();
    final resolvedEmail =
        (data['email'] ?? data['mail'] ?? data['userEmail'] ?? '').toString();
    final resolvedAvatar = (data['avatarUrl'] ?? data['photoUrl'] ?? '').toString();

    return UserModel(
      id: id,
      name: resolvedName,
      email: resolvedEmail,
      avatarUrl: resolvedAvatar,
      contributionCount: data['contributionCount'] ?? 0,
      reviewCount: data['reviewCount'] ?? 0,
      isSuperUser: data['isSuperUser'] ?? false,
      savedPlaces: List<String>.from(data['savedPlaces'] ?? []),
      chatPrivacyEnabled: data['chatPrivacyEnabled'] ?? false,  // NEW
      pinCount: data['pinCount'] ?? 0,                          // NEW
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'contributionCount': contributionCount,
      'reviewCount': reviewCount,
      'isSuperUser': isSuperUser,
      'savedPlaces': savedPlaces,
      'chatPrivacyEnabled': chatPrivacyEnabled,  // NEW
      'pinCount': pinCount,                      // NEW
    };
  }

  // Initials for avatar
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  // Super user rule: 5+ contributions OR 10+ reviews
  bool get qualifiesAsSuperUser {
    return contributionCount >= 5 || reviewCount >= 10;
  }

  // Monetization: free users get 10 pins max
  static const int kFreePinLimit = 10;
  bool get hasReachedPinLimit => pinCount >= kFreePinLimit;
}
