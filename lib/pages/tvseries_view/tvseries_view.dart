import 'package:cinemora/pages/info_view/tvseriesinfo_view.dart';
import 'package:cinemora/services/tmdb_services.dart';
import 'package:flutter/material.dart';

class TvseriesView extends StatelessWidget {
  const TvseriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: "TvSeries"),
                Tab(text: "History"),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _tvseriesCard(
                            context,
                            id: 1402,
                            season: 1,
                            episode: 1,
                          ),
                          const SizedBox(height: 15),
                          _tvseriesCard(
                            context,
                            id: 1396,
                            season: 2,
                            episode: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Center(child: Text("HISTORY ")),
                ],
              ),
            ),
            SizedBox(height: 5),
          ],
        ),
      ),
    );
  }

  Widget _tvseriesCard(
    BuildContext context, {
    required int id,
    required int season,
    required int episode,
  }) {
    return FutureBuilder<Map<String, dynamic>>(
      future: TmdbApiService().getTvSeriesDetails(id),
      builder: (context, snapshot) {
        String title = "Yükleniyor...";
        String? backdropPath;

        if (snapshot.hasData) {
          title = snapshot.data!['name'] ?? 'Bilinmeyen Dizi';
          backdropPath = snapshot.data!['backdrop_path'];
        }

        final String backdropUrl =
            (backdropPath != null && backdropPath.isNotEmpty)
            ? 'https://image.tmdb.org/t/p/w780$backdropPath'
            : '';

        return Stack(
          alignment: Alignment.centerRight,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TvSeriesInfo(tvId: id),
                  ),
                );
              },
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(24),
                  image: backdropUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(backdropUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withOpacity(0.85),
                        Colors.black.withOpacity(0.4),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              'Season: ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              season.toString(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              " • ",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Episode: ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              episode.toString(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 100),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$title bölümü artırıldı!')),
                  );
                },
                icon: Icon(
                  Icons.add_circle_outline_outlined,
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
