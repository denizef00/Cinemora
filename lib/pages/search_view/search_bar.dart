import 'dart:async';

import 'package:cinemora/services/media_item.dart';
import 'package:cinemora/services/movie_service.dart';
import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<StatefulWidget> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final MediaService _mediaService = MediaService();

  List<MediaItem> _result = [];
  bool _isLoading = false;
  Timer? _debounce;

  void _onSearchChange(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (query.trim().isEmpty) {
        setState(() {
          _result = [];
          _isLoading = false;
        });
        return;
      }

      setState(() => _isLoading = true);
      try {
        final items = await _mediaService.searchMedia(query);
        setState(() {
          _result = items;
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: TextField(
          controller: _controller,
          onChanged: _onSearchChange,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Film, dizi ara...',
            hintStyle: TextStyle(color: Colors.grey),
            prefixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.search, color: Colors.grey),
                    onPressed: () {
                      _controller.clear();
                      _onSearchChange('');
                    },
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.text.isEmpty) {
      return Center(
        child: Text(
          'Aramak istedigin film veya diziyi yaz',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    if (_result.isEmpty) {
      return Center(
        child: Text('Sonuc Bulunamadi', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _result.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),

      itemBuilder: (context, index) {
        final item = _result[index];
        final posterUrl = item.posterPath != null
            ? 'https://image.tmdb.org/t/p/w200${item.posterPath}'
            : null;

        return ListTile(
          tileColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: posterUrl != null
                ? Image.network(
                    posterUrl,
                    width: 45,
                    height: 65,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 45,
                    height: 65,
                    color: Colors.grey[800],
                    child: const Icon(Icons.movie, color: Colors.grey),
                  ),
          ),
          title: Text(
            item.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            '${item.mediaType == 'movie' ? 'Film' : 'Dizi'} • ${item.releaseDate?.split('-').first ?? 'Tarih Yok'} • ⭐ ${item.voteAverage.toStringAsFixed(1)}',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            color: Colors.grey,
            size: 16,
          ),
          onTap: () {},
        );
      },
    );
  }
}
