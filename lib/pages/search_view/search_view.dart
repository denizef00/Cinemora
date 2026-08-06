import 'package:cinemora/models/movie_model.dart';
import 'package:cinemora/models/tvseries_model.dart';
import 'package:cinemora/pages/info_view/movieinfo_view.dart';
import 'package:cinemora/pages/info_view/tvseriesinfo_view.dart';
import 'package:cinemora/services/tmdb_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchView extends ConsumerStatefulWidget {
  const SearchView({super.key});
  @override
  ConsumerState<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<SearchView> {
  final TextEditingController _textController = TextEditingController();

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
            //searchbar
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

                    Expanded(
                      child: TextField(
                        controller: _textController,
                        maxLines: 1,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.surface,
                          fontSize: 20,
                        ),
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
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
                        onChanged: (value) {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //top tv series
                Text(' Top TV Series For This Week'),
                SizedBox(height: 5),
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  child: FutureBuilder<List<TvseriesModel>>(
                    future: TmdbApiService().getPopularTvShows(),
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
                        return const Center(child: Text('Dizi Bulunamadi'));
                      }

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
                                color: Colors.red,
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
                SizedBox(height: 20),

                //top movies
                Text(' Top Movies For This Week'),
                SizedBox(height: 5),

                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  child: FutureBuilder<List<MovieModel>>(
                    future: TmdbApiService().getPopularMovies(),
                    builder: ((context, snapshot) {
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

                      if (movies.isEmpty) {
                        return const Center(child: Text('Film Bulunamadi'));
                      }

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
                                color: Colors.red,
                                isTvSeries: false,
                                posterUrl: movie.fullPosterPath,
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),

            //for you
          ],
        ),
      ),
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
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                isTvSeries ? TvSeriesInfo(tvId: id) : MovieInfo(movieId: id),
          ),
        );
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
      ),
    );
  }
}
