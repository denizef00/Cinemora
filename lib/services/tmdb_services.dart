import 'dart:convert';

import 'package:cinemora/models/movie_model.dart';
import 'package:cinemora/models/tvseries_model.dart';
import 'package:cinemora/services/api_constant.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

class TmdbApiService {
  late final Dio _dio;

  TmdbApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        queryParameters: {'language': 'tr-TR'},
        headers: {
          'Authorization': 'Bearer ${ApiConstants.accessToken}',
          'accept': 'application/json',
        },
      ),
    );
  }

  Future<List<MovieModel>> getPopularMovies() async {
    try {
      final response = await _dio.get('/movie/popular');
      final List<dynamic> results = response.data['results'];
      return results.map((json) => MovieModel.fromJson(json)).toList();
    } catch (e) {
      print('Popüler filmler getirilirken hata oluştu: $e');
      rethrow;
    }
  }

  Future<List<TvseriesModel>> getPopularTvShows() async {
    try {
      final response = await _dio.get('/tv/popular');
      final List<dynamic> results = response.data['results'];

      return results.map((json) => TvseriesModel.fromJson(json)).toList();
    } catch (e) {
      print('Popüler diziler çekilirken hata: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMovieDetails(int movieId) async {
    try {
      final response = await _dio.get('/movie/$movieId');
      return response.data;
    } catch (e) {
      print('Film detaylarini cekerken hata : $e ');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTvSeriesDetails(int tvId) async {
    try {
      final response = await _dio.get('/tv/$tvId');
      return response.data;
    } catch (e) {
      print('Dizi detaylarini cekerken hata : $e ');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSeasonDetails(
    int tvId,
    int seasonNumber,
  ) async {
    final String apiKey = dotenv.env['TMDB_API_KEY'] ?? '';
    final String baseUrl =
        dotenv.env['TMDB_BASE_URL'] ?? 'https://api.themoviedb.org/3';

    final url = Uri.parse(
      '$baseUrl/tv/$tvId/season/$seasonNumber?api_key=$apiKey&language=tr-TR',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return {};
  }

  Future<List<dynamic>> searchMulti(String query) async {
    final String apiKey = dotenv.env['TMDB_API_KEY'] ?? '';
    final String baseUrl =
        dotenv.env['TMDB_BASE_URL'] ?? 'https://api.themoviedb.org/3';
    if (apiKey.isEmpty) {
      throw Exception('TMDB_API_KEY .env dosyasında bulunamadı.');
    }

    final url = Uri.parse(
      '$baseUrl/search/multi?api_key=$apiKey&query=${Uri.encodeComponent(query)}&language=tr-TR',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'] ?? [];
      return results
          .where(
            (item) =>
                item['media_type'] == 'movie' || item['media_type'] == 'tv',
          )
          .toList();
    }
    return [];
  }
}
