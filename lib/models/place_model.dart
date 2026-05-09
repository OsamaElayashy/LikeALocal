class Review {
  final String userId;
  final String userName;
  final double score; // 0-5
  final String comment;
  final DateTime createdAt;

  Review({
    required this.userId,
    required this.userName,
    required this.score,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromMap(Map<String, dynamic> data) {
    return Review(
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      score: (data['score'] ?? 0).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() => {
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
  final String localTip;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final String contributorId;
  final String contributorName;
  final DateTime createdAt;
  final List<String> savedBy; // list of user IDs who pinned this
  final List<Review> reviews;

  Place({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.localTip,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.contributorId,
    required this.contributorName,
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

  // Convert Firestore document → Place object
  factory Place.fromMap(String id, Map<String, dynamic> data) {
    final rawReviews = List<dynamic>.from(data['reviews'] ?? []);
    return Place(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      localTip: data['localTip'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      contributorId: data['contributorId'] ?? '',
      contributorName: data['contributorName'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          data['createdAt'] ?? 0),
      savedBy: List<String>.from(data['savedBy'] ?? []),
      reviews: rawReviews.map((r) => Review.fromMap(Map<String, dynamic>.from(r))).toList(),
    );
  }

  // Convert Place object → Firestore document
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'localTip': localTip,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'contributorId': contributorId,
      'contributorName': contributorName,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'savedBy': savedBy,
      'reviews': reviews.map((r) => r.toMap()).toList(),
    };
  }
}