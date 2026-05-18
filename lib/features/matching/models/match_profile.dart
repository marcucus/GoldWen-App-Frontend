import '../../../core/models/profile.dart';

class MatchProfile {
  final String id;
  final String name;
  final int age;
  final String bio;
  final List<String> photos;
  final List<MediaFile> mediaFiles;
  final List<String> prompts;
  final double compatibilityScore;
  final Map<String, double>? compatibilityDetails;
  final List<String> sharedInterests;
  final String? favoriteSong;

  MatchProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.bio,
    required this.photos,
    this.mediaFiles = const [],
    required this.prompts,
    required this.compatibilityScore,
    this.compatibilityDetails,
    this.sharedInterests = const [],
    required this.favoriteSong,
  });

  factory MatchProfile.fromJson(Map<String, dynamic> json) {
    return MatchProfile(
      id: json['id'],
      name: json['name'],
      age: json['age'],
      bio: json['bio'],
      photos: List<String>.from(json['photos']),
      mediaFiles: (json['mediaFiles'] as List<dynamic>?)
              ?.map((e) => MediaFile.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      prompts: List<String>.from(json['prompts']),
      compatibilityScore: json['compatibilityScore'].toDouble(),
      compatibilityDetails: (json['compatibilityDetails'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, (v as num).toDouble())),
      sharedInterests: (json['sharedInterests'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      favoriteSong: json['favoriteSong'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'bio': bio,
      'photos': photos,
      'mediaFiles': mediaFiles.map((m) => m.toJson()).toList(),
      'prompts': prompts,
      'compatibilityScore': compatibilityScore,
    };
  }
}