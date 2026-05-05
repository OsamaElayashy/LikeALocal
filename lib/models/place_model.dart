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
  final List<String> savedBy;   // list of user IDs who pinned this
  double rating;
  int reviewCount;

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
    this.rating = 0.0,
    this.reviewCount = 0,
  });

  // Convert Firestore document → Place object
  factory Place.fromMap(String id, Map<String, dynamic> data) {
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
      rating: (data['rating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
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
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }
}