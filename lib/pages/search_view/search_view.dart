import 'package:cinemora/auth/login.dart';
import 'package:cinemora/pages/info_view/movieinfo_view.dart';
import 'package:cinemora/pages/info_view/tvseriesinfo_view.dart';
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 50),
      child: Column(
        children: [
          OutlinedButton(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (context) => LoginPage()));
            },
            child: Text('Login Test'),
          ),
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
                        border: OutlineInputBorder(borderSide: BorderSide.none),
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
              Text('    Top TV Series For This Week'),
              SizedBox(height: 5),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Theme.of(context).colorScheme.secondary,
                ),
                child: SizedBox(
                  height: 100,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _topCard(
                          context,
                          title: "Tv Series 1",
                          overview: "TVSERIES INFO 1",
                          years: "2026-2027",
                          type: "Comedy",
                          rating: "%100",
                          total: "10",
                          status: true,
                          cast: {"Actor 1": "Char 1"},
                          color: Colors.red,
                          isTvSeries: true,
                        ),
                        _topCard(
                          context,
                          title: "Tv Series 2",
                          overview: "TVSERIES INFO 2",
                          years: "2026-2027",
                          type: "Comedy",
                          rating: "%100",
                          total: "10",
                          status: true,
                          cast: {"Actor 1": "Char 1"},
                          color: Colors.red,
                          isTvSeries: true,
                        ),
                        _topCard(
                          context,
                          title: "Tv Series 3",
                          overview: "TVSERIES INFO 3",
                          years: "2026-2027",
                          type: "Comedy",
                          rating: "%100",
                          total: "10",
                          status: true,
                          cast: {"Actor 1": "Char 1"},
                          color: Colors.red,
                          isTvSeries: true,
                        ),
                        _topCard(
                          context,
                          title: "Tv Series 4",
                          overview: "TVSERIES INFO 4",
                          years: "2026-2027",
                          type: "Comedy",
                          rating: "%100",
                          total: "10",
                          status: true,
                          cast: {"Actor 1": "Char 1"},
                          color: Colors.red,
                          isTvSeries: true,
                        ),
                        _topCard(
                          context,
                          title: "Tv Series 5",
                          overview: "TVSERIES INFO 5",
                          years: "2026-2027",
                          type: "Comedy",
                          rating: "%100",
                          total: "10",
                          status: true,
                          cast: {"Actor 1": "Char 1"},
                          color: Colors.red,
                          isTvSeries: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),

              //top movies
              Text('    Top Movies For This Week'),
              SizedBox(height: 5),

              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Theme.of(context).colorScheme.secondary,
                ),
                child: SizedBox(
                  height: 100,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _topCard(
                          context,
                          title: "Movie 1",
                          overview: "MOVIE INFO 1",
                          years: "2026-2027",
                          type: "Comedy",
                          rating: "%100",
                          total: "1h 59m",
                          status: true,
                          cast: {"Actor 1": "Char 1"},
                          color: Colors.red,
                          isTvSeries: false,
                        ),
                        _topCard(
                          context,
                          title: "Movie 2",
                          overview: "MOVIE INFO 2",
                          years: "2026-2027",
                          type: "Comedy",
                          rating: "%100",
                          total: "1h 59m",
                          status: true,
                          cast: {"Actor 1": "Char 1"},
                          color: Colors.red,
                          isTvSeries: false,
                        ),
                        _topCard(
                          context,
                          title: "Movie 3",
                          overview: "MOVIE INFO 3",
                          years: "2026-2027",
                          type: "Comedy",
                          rating: "%100",
                          total: "1h 59m",
                          status: true,
                          cast: {"Actor 1": "Char 1"},
                          color: Colors.red,
                          isTvSeries: false,
                        ),
                        _topCard(
                          context,
                          title: "Movie 4",
                          overview: "MOVIE INFO 4",
                          years: "2026-2027",
                          type: "Comedy",
                          rating: "%100",
                          total: "1h 59m",
                          status: true,
                          cast: {"Actor 1": "Char 1"},
                          color: Colors.red,
                          isTvSeries: false,
                        ),
                        _topCard(
                          context,
                          title: "Movie 5",
                          overview: "MOVIE INFO 5",
                          years: "2026-2027",
                          type: "Comedy",
                          rating: "%100",
                          total: "1h 59m",
                          status: true,
                          cast: {"Actor 1": "Char 1"},
                          color: Colors.red,
                          isTvSeries: false,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          //for you
        ],
      ),
    );
  }

  Widget _topCard(
    BuildContext context, {
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
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => isTvSeries
                ? TvSeriesInfo(
                    title: title,
                    overview: overview,
                    years: years,
                    type: type,
                    rating: rating,
                    totalSeason: total,
                    cast: cast,
                    status: status,
                  )
                : MovieInfo(
                    title: title,
                    overview: overview,
                    year: years,
                    type: type,
                    rating: rating,
                    time: total,
                    cast: cast,
                    status: status,
                  ),
          ),
        );
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
