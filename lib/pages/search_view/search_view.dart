import 'dart:async';

import 'package:cinemora/models/movie_model.dart';
import 'package:cinemora/models/tvseries_model.dart';
import 'package:cinemora/services/database_services.dart';
import 'package:cinemora/services/tmdb_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  @override
  void dispose() {
    _textController.dispose();
    _debounce?.cancel();
    super.dispose();
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
                          border: InputBorder.none,
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

  void _showAddToLibraryBottomSheet({
    required BuildContext context,
    required int itemId,
    required bool isTvSeries,
  }) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen önce giriş yapınız.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add to Library',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser.uid)
                    .collection('lists')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final allLists = snapshot.data?.docs ?? [];

                  // İçerik türüne göre filtreleme yapıyoruz:
                  final userLists = allLists.where((listDoc) {
                    final listData =
                        listDoc.data() as Map<String, dynamic>? ?? {};
                    final listType = listData['type'] ?? 'custom';

                    if (isTvSeries) {
                      return listType != 'movie'; // Dizi için filmleri gizle
                    } else {
                      return listType != 'tv'; // Film için dizileri gizle
                    }
                  }).toList();

                  if (userLists.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text('Uygun kütüphane listesi bulunamadı.'),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: userLists.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final listDoc = userLists[index];
                      final listData =
                          listDoc.data() as Map<String, dynamic>? ?? {};

                      final listName = listData['name'] ?? 'Liste';
                      final listType = listData['type'] ?? 'custom';

                      IconData iconData = Icons.bookmark_border;
                      Color iconColor = Theme.of(context).colorScheme.primary;

                      if (listType == 'tv') {
                        iconData = Icons.tv;
                        iconColor = Colors.redAccent;
                      } else if (listType == 'favorites' ||
                          listName.toString().toLowerCase().contains(
                            'favorite',
                          )) {
                        iconData = Icons.favorite;
                        iconColor = Colors.pinkAccent;
                      } else if (listType == 'movie') {
                        iconData = Icons.movie;
                        iconColor = Colors.blueAccent;
                      }

                      return ListTile(
                        leading: Icon(iconData, color: iconColor),
                        title: Text(
                          listName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () async {
                            Navigator.pop(context);

                            await DatabaseServices().addItemToList(
                              listId: listDoc.id,
                              itemId: itemId,
                              isTvSeries: isTvSeries,
                            );

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Added to "$listName" successfully!',
                                  ),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.errorContainer,
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
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
          // Arama listesindeki sağ buton: Kütüphaneye Ekle
          trailing: IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 22),
            onPressed: () {
              _showAddToLibraryBottomSheet(
                context: context,
                itemId: item['id'],
                isTvSeries: isTv,
              );
            },
          ),
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
        const Text(
          ' Top TV Series For This Week',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 190,
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
              if (tvShows.isEmpty) {
                return const Center(child: Text('Dizi Bulunamadı'));
              }
              final limitedTvShows = tvShows.take(10).toList();
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: limitedTvShows.map((tv) {
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
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          ' Top Movies For This Week',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 190,
          child: FutureBuilder<List<MovieModel>>(
            future: _apiService.getPopularMovies(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Filmler Yüklenemedi',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                );
              }

              final movies = snapshot.data ?? [];
              if (movies.isEmpty) {
                return const Center(child: Text('Film Bulunamadı'));
              }
              final limitedMovies = movies.take(10).toList();
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: limitedMovies.map((movie) {
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
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Sağ Üst Köşesinde Kütüphaneye Ekle Butonu Bulunan Kart ---
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
        height: 180,
        margin: const EdgeInsets.only(right: 12),
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
        child: Stack(
          children: [
            // Arka Plan Karartma Gradyanı ve Başlık
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

            // Sağ Üst Köşedeki Kütüphaneye Ekle (+) Butonu
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: () {
                  _showAddToLibraryBottomSheet(
                    context: context,
                    itemId: id,
                    isTvSeries: isTvSeries,
                  );
                },
                child: Icon(
                  Icons.add_circle_outline_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
