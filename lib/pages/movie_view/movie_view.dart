import 'package:cinemora/pages/info_view/movieinfo_view.dart';
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
                      horizontal: 15,
                      vertical: 20,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _movieCard(
                                context,
                                title: "The Batman",
                                overview:
                                    "In his second year of fighting crime, Batman uncovers corruption in Gotham City that connects to his own family while facing a serial killer known as the Riddler.",
                                year: "04/03/2022",
                                type: "Crime, Mystery, and Thriller",
                                rating: "%77",
                                time: "2h 57m",
                                cast: {
                                  "Robert Pattinson":
                                      "Bruce Wayne / The Batman",
                                  "Zoë Kravitz": "Selina Kyle",
                                  "Jeffrey Wright": "Lt. James Gordon",
                                  "Colin Farrell": "Oz / The Penguin",
                                  "Paul Dano": "The Riddler",
                                },
                                status: false,
                              ),
                              SizedBox(width: 10),
                              _movieCard(
                                context,
                                title: "Toy Story 5 ",
                                overview:
                                    "When Bonnie receives a Lilypad tablet as a gift and becomes obsessed, Buzz, Woody, Jessie and the rest of the gang's jobs become exponentially harder when they have to go head to head with the all-new threat to playtime.",
                                year: "19/06/2026",
                                type:
                                    "Animation, Family, Comedy, and Adventure",
                                rating: "%74",
                                time: "1h 42m",
                                cast: {
                                  "Tom Hanks": "Woody (voice)",
                                  "Tim Allen": "Buzz Lightyear (voice)",
                                  "Joan Cusack": "Jessie (voice)",
                                  "Greta Lee": "Lilypad (voice)",
                                  "Conan O'Brien": "Smarty Pants (voice)",
                                  "Craig Robinson": "Atlas (voice)",
                                },
                                status: false,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Stack _movieCard(
    BuildContext context, {
    required String title,
    required String overview,
    required String year,
    required String type,
    required String rating,
    required String time,
    required Map<String, String> cast,
    required bool status,
  }) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => MovieInfo(
                  title: title,
                  overview: overview,
                  year: year,
                  type: type,
                  rating: rating,
                  time: time,
                  cast: cast,
                  status: status,
                ),
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
  }
}
