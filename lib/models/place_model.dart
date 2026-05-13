// Add this at the top of your file — the cities list
// Easy to add more later, just add to this list
const List<String> kSupportedCities = [
  'Cairo',
  'Alexandria',
  'Giza',
  'Luxor',
  'Sharm El Sheikh',
  'Hurghada',
];

class Review {
  final String reviewId;   // NEW — needed for edit/delete
  final String userId;
  final String userName;
  final double score;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.reviewId,  // NEW
    required this.userId,
    required this.userName,
    required this.score,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromMap(Map<String, dynamic> data) {
    return Review(
      reviewId: data['reviewId'] ?? '',   // NEW
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      score: (data['score'] ?? 0).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() => {
    'reviewId': reviewId,   // NEW
    'userId': userId,
    'userName': userName,
    'score': score,
    'comment': comment,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };
}

class Place {
  final String id;
  final String title;
  final String description;
  final String category;
  final String city;        // NEW
  final String localTip;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final String contributorId;
  final String contributorName;
  final bool contributorIsSuperUser;  // NEW — for ordering
  final DateTime createdAt;
  final List<String> savedBy;
  final List<Review> reviews;

  Place({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.city,              // NEW
    required this.localTip,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.contributorId,
    required this.contributorName,
    this.contributorIsSuperUser = false,  // NEW
    required this.createdAt,
    this.savedBy = const [],
    this.reviews = const [],
  });

  double get rating {
    if (reviews.isEmpty) return 0.0;
    final total = reviews.fold<double>(0.0, (s, r) => s + r.score);
    return double.parse((total / reviews.length).toStringAsFixed(2));
  }

  int get reviewCount => reviews.length;

  factory Place.fromMap(String id, Map<String, dynamic> data) {
    final rawReviews = List<dynamic>.from(data['reviews'] ?? []);
    return Place(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      city: data['city'] ?? 'Cairo',              // NEW
      localTip: data['localTip'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      contributorId: data['contributorId'] ?? '',
      contributorName: data['contributorName'] ?? '',
      contributorIsSuperUser: data['contributorIsSuperUser'] ?? false, // NEW
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
      savedBy: List<String>.from(data['savedBy'] ?? []),
      reviews: rawReviews
          .map((r) => Review.fromMap(Map<String, dynamic>.from(r)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'city': city,                              // NEW
      'localTip': localTip,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'contributorId': contributorId,
      'contributorName': contributorName,
      'contributorIsSuperUser': contributorIsSuperUser,  // NEW
      'createdAt': createdAt.millisecondsSinceEpoch,
      'savedBy': savedBy,
      'reviews': reviews.map((r) => r.toMap()).toList(),
    };
  }
}