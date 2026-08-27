import 'dart:async';

import 'package:cinemora/models/movie_model.dart';
import 'package:cinemora/models/tvseries_model.dart';
import 'package:cinemora/services/tmdb_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SearchView extends ConsumerStatefulWidget {
  const SearchView({super.key});
  @override
  ConsumerState<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<SearchView> {
  final TextEditingController _textController = TextEditingController();
  final TmdbApiService _apiService = TmdbApiService();
  int _selectedSearchTab = 0; // 0: Movies, 1: TV Series
  List<dynamic> _movieResults = [];
  List<dynamic> _tvResults = [];
  bool _isLoading = false;
  Timer? _debounce;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final trimmed = query.trim();
      if (trimmed.isEmpty) {
        setState(() {
          _movieResults = [];
          _tvResults = [];
          _isLoading = false;
        });
        return;
      }

      setState(() => _isLoading = true);

      try {
        final results = await _apiService.searchMulti(trimmed);

        final movies = results
            .where((item) => item['media_type'] == 'movie')
            .toList();
        final tvs = results
            .where((item) => item['media_type'] == 'tv')
            .toList();

        // Puana göre azalan sıralama (En yüksek puan en üstte)
        movies.sort(
          (a, b) => ((b['vote_average'] as num?)?.toDouble() ?? 0.0).compareTo(
            (a['vote_average'] as num?)?.toDouble() ?? 0.0,
          ),
        );

        tvs.sort(
          (a, b) => ((b['vote_average'] as num?)?.toDouble() ?? 0.0).compareTo(
            (a['vote_average'] as num?)?.toDouble() ?? 0.0,
          ),
        );

        setState(() {
          _movieResults = movies;
          _tvResults = tvs;
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 50),
        child: Column(
          children: [
            // Search Bar
            Container(
              height: 50,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        maxLines: 1,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.surface,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 5,
                          ),
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                          hintText: 'Search...',
                          hintStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onTertiary,
                          ),
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                    if (_textController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _textController.clear();
                          _onSearchChanged('');
                        },
                        child: Icon(
                          Icons.clear,
                          size: 20,
                          color: Theme.of(context).colorScheme.surface,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            _textController.text.trim().isNotEmpty
                ? _buildSearchResults()
                : _buildDefaultTopLists(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 50),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_movieResults.isEmpty && _tvResults.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 50),
        child: Center(child: Text('Sonuç bulunamadı')),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedSearchTab = 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: _selectedSearchTab == 0
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onTertiary,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'MOVIES (${_movieResults.length})',
                      style: TextStyle(
                        color: _selectedSearchTab == 0
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onTertiary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedSearchTab = 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: _selectedSearchTab == 1
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onTertiary,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'TV SERIES (${_tvResults.length})',
                      style: TextStyle(
                        color: _selectedSearchTab == 1
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onTertiary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        _selectedSearchTab == 0
            ? _buildResultList(_movieResults, isTv: false)
            : _buildResultList(_tvResults, isTv: true),
      ],
    );
  }

  Widget _buildResultList(List<dynamic> items, {required bool isTv}) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 50),
        child: Center(
          child: Text(
            isTv ? 'Dizi eşleşmesi bulunamadı' : 'Film eşleşmesi bulunamadı',
            style: TextStyle(color: Theme.of(context).colorScheme.onTertiary),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        final title = item['title'] ?? item['name'] ?? 'Bilinmeyen Başlık';
        final posterPath = item['poster_path'];
        final rating = ((item['vote_average'] as num?)?.toDouble() ?? 0.0) * 10;
        final year =
            (item['release_date'] ?? item['first_air_date'] ?? 'Bilinmiyor')
                .toString()
                .split('-')
                .first;

        return ListTile(
          tileColor: Theme.of(context).colorScheme.secondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: posterPath != null
                ? Image.network(
                    'https://image.tmdb.org/t/p/w200$posterPath',
                    width: 45,
                    height: 65,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 45,
                    height: 65,
                    color: Theme.of(context).colorScheme.onTertiary,
                    child: Icon(
                      Icons.movie,
                      color: Theme.of(context).colorScheme.onTertiary,
                    ),
                  ),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.surface,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            '$year • ⭐ %${rating.toInt()}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onTertiary,
              fontSize: 12,
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          onTap: () {
            final id = item['id'];
            if (isTv) {
              context.push('/tv-info/$id');
            } else {
              context.push('/movie-info/$id');
            }
          },
        );
      },
    );
  }

  Widget _buildDefaultTopLists() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(' Top TV Series For This Week'),
        const SizedBox(height: 5),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Theme.of(context).colorScheme.secondary,
          ),
          child: FutureBuilder<List<TvseriesModel>>(
            future: _apiService.getPopularTvShows(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Diziler yüklenemedi',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                );
              }

              final tvShows = snapshot.data ?? [];
              if (tvShows.isEmpty)
                return const Center(child: Text('Dizi Bulunamadi'));

              return SizedBox(
                height: 100,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: tvShows.map((tv) {
                      return _topCard(
                        context,
                        id: tv.id,
                        title: tv.name,
                        overview: tv.overview,
                        years: tv.firstAirDate ?? 'Bilinmiyor',
                        type: "Tv Series",
                        rating: "%${(tv.voteAverage * 10).toInt()}",
                        total: "1 Season",
                        status: true,
                        cast: {},
                        color: Theme.of(context).colorScheme.secondary,
                        isTvSeries: true,
                        posterUrl: tv.fullPosterPath,
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        const Text(' Top Movies For This Week'),
        const SizedBox(height: 5),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Theme.of(context).colorScheme.secondary,
          ),
          child: FutureBuilder<List<MovieModel>>(
            future: _apiService.getPopularMovies(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Filmler Yuklenemedi',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                );
              }

              final movies = snapshot.data ?? [];
              if (movies.isEmpty)
                return const Center(child: Text('Film Bulunamadi'));

              return SizedBox(
                height: 100,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: movies.map((movie) {
                      return _topCard(
                        context,
                        id: movie.id,
                        title: movie.title,
                        overview: movie.overview,
                        years: movie.releaseDate ?? 'Bilinmiyor',
                        type: "Movie",
                        rating: "%${(movie.voteAverage * 10).toInt()}",
                        total: "1h 59m",
                        status: true,
                        cast: {},
                        color: Theme.of(context).colorScheme.secondary,
                        isTvSeries: false,
                        posterUrl: movie.fullPosterPath,
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _topCard(
    BuildContext context, {
    required int id,
    required String title,
    required String overview,
    required String years,
    required String type,
    required String rating,
    required String total,
    required bool status,
    required Map<String, String> cast,
    required Color color,
    required bool isTvSeries,
    String? posterUrl,
  }) {
    return GestureDetector(
      onTap: () {
        if (isTvSeries) {
          context.push('/tv-info/$id');
        } else {
          context.push('/movie-info/$id');
        }
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          image: posterUrl != null
              ? DecorationImage(
                  image: NetworkImage(posterUrl),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
            ),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.tertiary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
