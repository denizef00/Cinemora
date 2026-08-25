import 'package:cinemora/models/cast_model.dart';

class MovieModel {
  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final String? releaseDate;
  final List<CastModel> cast;

  MovieModel({
    required this.id,
    required this.title,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    required this.voteAverage,
    this.releaseDate,
    this.cast = const [],
  });

  factory MovieModel.fromJson(Map<String, dynamic> json) {
    final castData =
        (json['credits']?['cast'] ?? json['cast']) as List<dynamic>?;
    return MovieModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      releaseDate: json['release_date'],
      cast: castData != null
          ? castData.map((e) => CastModel.fromJson(e)).toList()
          : [],
    );
  }

  String get fullPosterPath {
    if (posterPath != null && posterPath!.isNotEmpty) {
      return 'https://image.tmdb.org/t/p/w500$posterPath';
    }

    return 'https://via.placeholder.com/500x750?text=No+Image';
  }
}
