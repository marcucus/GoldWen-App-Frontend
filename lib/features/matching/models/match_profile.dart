class MatchProfile {
  final String id;
  final String name;
  final int age;
  final String bio;
  final List<String> photos;
  final List<String> prompts;
  final double compatibilityScore;

  MatchProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.bio,
    required this.photos,
    required this.prompts,
    required this.compatibilityScore,
  });

  factory MatchProfile.fromJson(Map<String, dynamic> json) {
    return MatchProfile(
      id: json['id'],
      name: json['name'],
      age: json['age'],
      bio: json['bio'],
      photos: List<String>.from(json['photos']),
      prompts: List<String>.from(json['prompts']),
      compatibilityScore: json['compatibilityScore'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'bio': bio,
      'photos': photos,
      'prompts': prompts,
      'compatibilityScore': compatibilityScore,
    };
  }
}