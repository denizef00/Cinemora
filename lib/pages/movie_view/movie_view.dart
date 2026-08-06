import 'package:cinemora/pages/info_view/movieinfo_view.dart';
import 'package:cinemora/services/tmdb_services.dart';
import 'package:flutter/material.dart';

class MovieView extends StatelessWidget {
  const MovieView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: const EdgeInsetsGeometry.symmetric(
          horizontal: 10,
          vertical: 20,
        ),
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: "Unwatch"),
                Tab(text: "History"),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 20,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _movieCard(context, id: 634649),
                              SizedBox(width: 10),
                              _movieCard(context, id: 550),
                              SizedBox(width: 10),
                              _movieCard(context, id: 157336),
                            ],
                          ),
                          SizedBox(height: 10),

                          Row(
                            children: [
                              _movieCard(context, id: 27205),
                              SizedBox(width: 10),
                              _movieCard(context, id: 155),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Center(child: Text('History')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _movieCard(BuildContext context, {required int id}) {
    return FutureBuilder<Map<String, dynamic>>(
      future: TmdbApiService().getMovieDetails(id),
      builder: (context, snapshot) {
        String? posterPath;

        if (snapshot.hasData) {
          posterPath = snapshot.data!['poster_path'];
        }

        final String? posterUrl = posterPath != null
            ? 'https://image.tmdb.org/t/p/w500$posterPath'
            : null;

        return Stack(
          alignment: Alignment.topRight,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => MovieInfo(movieId: id),
                  ),
                );
              },
              child: Container(
                alignment: Alignment.topLeft,
                height: 200,
                width: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.red,
                  image: posterUrl != null
                      ? DecorationImage(
                          image: NetworkImage(posterUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              child: IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.check_circle_outline_outlined,
                  color: Colors.white,
                  size: 25,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
