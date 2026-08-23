class MediaItem {
  final int id;
  final String title;
  final String? posterPath;
  final String mediaType;
  final String? releaseDate;
  final double voteAverage;

  MediaItem({
    required this.id,
    required this.title,
    this.posterPath,
    required this.mediaType,
    this.releaseDate,
    required this.voteAverage,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'],
      title: json['title'] ?? json['name'] ?? 'Bilinmeyen Başlık',
      posterPath: json['poster_path'],
      mediaType: json['media_type'] ?? 'movie',
      releaseDate: json['release_date'] ?? json['first_air_date'],
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
