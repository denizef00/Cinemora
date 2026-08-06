import 'package:cinemora/models/movie_model.dart';
import 'package:cinemora/models/tvseries_model.dart';
import 'package:cinemora/services/api_constant.dart';
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
}
