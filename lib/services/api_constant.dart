import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static const String baseUrl = 'https://api.themoviedb.org/3';
  static const String imageBaseUrl = 'https://image.tmdb.org/3/t/p/w500';

  static String get apiKey => dotenv.env['TMDB_API_KEY'] ?? '';
  static String get accessToken => dotenv.env['TMDB_ACCESS_TOKEN'] ?? '';
}
