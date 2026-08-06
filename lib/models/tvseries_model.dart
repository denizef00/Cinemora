class TvseriesModel {
  final int id;
  final String name;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final String? firstAirDate;

  TvseriesModel({
    required this.id,
    required this.name,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    required this.voteAverage,
    this.firstAirDate,
  });

  factory TvseriesModel.fromJson(Map<String, dynamic> json) {
    return TvseriesModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      firstAirDate: json['first_air_date'],
    );
  }

  String get fullPosterPath {
    if (posterPath != null && posterPath!.isNotEmpty) {
      return 'https://image.tmdb.org/t/p/w500$posterPath';
    }

    return 'https://via.placeholder.com/500x750?text=No+Image';
  }
}
