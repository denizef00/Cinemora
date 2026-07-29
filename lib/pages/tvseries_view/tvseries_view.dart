import 'package:cinemora/pages/info_view/tvseriesinfo_view.dart';
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
                            title: "The Mentalist",
                            overview:
                                "Patrick Jane, a former celebrity psychic medium, uses his razor sharp skills of observation and expertise at 'reading' people to solve serious crimes with the California Bureau of Investigation.",
                            years: "2009 - 2014",
                            type: "Crime, Drama, and Mystery",
                            rating: "%84",
                            totalSeason: "7",
                            cast: {
                              "Simon Baker": "Patrick Jane",
                              "Robin Tunney": "Teresa Lisbon",
                              "Tim Kang": "Kimball Cho",
                              "Owain Yeoman": "Wayne Rigsby",
                              "Amanda Righetti": "Grace Van Pelt",
                            },
                            status: false,
                            season: 1,
                            episode: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text("HISTORY VIEW"),
                ],
              ),
            ),
            SizedBox(height: 5),
          ],
        ),
      ),
    );
  }

  Stack _tvseriesCard(
    BuildContext context, {
    required String title,
    required String overview,
    required String years,
    required String type,
    required String rating,
    required String totalSeason,
    required Map<String, String> cast,
    required bool status,
    required int season,
    required int episode,
  }) {
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => TvSeriesInfo(
                  title: title,
                  overview: overview,
                  years: years,
                  type: type,
                  rating: rating,
                  totalSeason: totalSeason,
                  cast: cast,
                  status: status,
                ),
              ),
            );
          },
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
        SizedBox(width: 100),
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: IconButton(
            onPressed: () {
              episode = episode + 1;
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
  }
}
