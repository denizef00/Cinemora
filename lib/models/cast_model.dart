class CastModel {
  final int id;
  final String name;
  final String character;
  final String? profilePath;

  CastModel({
    required this.id,
    required this.name,
    required this.character,
    this.profilePath,
  });

  factory CastModel.fromJson(Map<String, dynamic> json) {
    return CastModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      character: json['character'] ?? '',
      profilePath: json['profile_path'],
    );
  }

  String get fullProfilePath {
    if (profilePath != null && profilePath!.isNotEmpty) {
      return 'https://image.tmdb.org/t/p/w185$profilePath';
    }
    return 'https://via.placeholder.com/185x278?text=No+Photo';
  }
}
