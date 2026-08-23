import 'dart:convert';
import 'package:cinemora/services/media_item.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MediaService {
  final String _apiKey = dotenv.env['TMDB_API_KEY'] ?? '';
  final String _baseUrl =
      dotenv.env['TMDB_BASE_URL'] ?? 'https://api.themoviedb.org/3';

  Future<List<MediaItem>> searchMedia(String query) async {
    if (query.trim().isEmpty) return [];

    if (_apiKey.isEmpty) {
      throw Exception('TMDb API Key bulunamadı. .env dosyasını kontrol et.');
    }

    final url = Uri.parse(
      '$_baseUrl/search/multi?api_key=$_apiKey&query=${Uri.encodeComponent(query)}&language=tr-TR',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      return results
          .where(
            (item) =>
                item['media_type'] == 'movie' || item['media_type'] == 'tv',
          )
          .map((item) => MediaItem.fromJson(item))
          .toList();
    } else {
      throw Exception('Arama hatası: ${response.statusCode}');
    }
  }
}
