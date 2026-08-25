import 'package:cinemora/models/cast_model.dart';

class TvseriesModel {
  final int id;
  final String name;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final String? firstAirDate;
  final List<CastModel> cast;

  TvseriesModel({
    required this.id,
    required this.name,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    required this.voteAverage,
    this.firstAirDate,
    this.cast = const [],
  });

  factory TvseriesModel.fromJson(Map<String, dynamic> json) {
    final castData =
        (json['credits']?['cast'] ?? json['cast']) as List<dynamic>?;
    return TvseriesModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      firstAirDate: json['first_air_date'],
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
