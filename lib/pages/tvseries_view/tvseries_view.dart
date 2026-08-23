import 'package:cinemora/services/database_services.dart';
import 'package:cinemora/services/tmdb_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TvseriesView extends StatelessWidget {
  const TvseriesView({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
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
                    child: currentUser == null
                        ? const Center(
                            child: Text(
                              'Kutuphanenizi gormek icin lutfen giris yapiniz',
                            ),
                          )
                        : StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(currentUser.uid)
                                .collection('lists')
                                .where('type', isEqualTo: 'tv')
                                .snapshots(),
                            builder: (context, listSnapshot) {
                              if (listSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              if (!listSnapshot.hasData ||
                                  listSnapshot.data!.docs.isEmpty) {
                                return const Center(
                                  child: Text("TV Series listesi bulunamadı."),
                                );
                              }
                              final tvListDocId =
                                  listSnapshot.data!.docs.first.id;
                              return StreamBuilder(
                                stream: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(currentUser.uid)
                                    .collection('lists')
                                    .doc(tvListDocId)
                                    .collection('items')
                                    .orderBy('addedAt', descending: true)
                                    .snapshots(),
                                builder: (context, itemsSnapshot) {
                                  if (itemsSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  if (!itemsSnapshot.hasData ||
                                      itemsSnapshot.data!.docs.isEmpty) {
                                    return const Center(
                                      child: Text(
                                        "Kütüphanenizde henüz ekli dizi bulunmuyor.",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    );
                                  }

                                  final allDocs = itemsSnapshot.data!.docs;

                                  final inProgressSeries = allDocs.where((doc) {
                                    final data = doc.data();
                                    return (data['currentEpisode'] ?? 0) > 0;
                                  }).toList();

                                  final unstartedSeries = allDocs.where((doc) {
                                    final data = doc.data();
                                    return (data['currentEpisode'] ?? 0) == 0;
                                  }).toList();

                                  return SingleChildScrollView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(
                                          parent: BouncingScrollPhysics(),
                                        ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildSectionTitle(
                                          'Currently Watching',
                                          inProgressSeries.length,
                                        ),
                                        SizedBox(height: 10),

                                        if (inProgressSeries.isEmpty)
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                            child: Text(
                                              'Su an izlemekte oldugunuz bir dizi yok.',
                                            ),
                                          )
                                        else
                                          ListView.separated(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            padding: EdgeInsets.zero,
                                            itemCount: inProgressSeries.length,
                                            separatorBuilder:
                                                (context, index) =>
                                                    SizedBox(height: 15),
                                            itemBuilder: (context, index) {
                                              final tvData =
                                                  inProgressSeries[index]
                                                      .data();
                                              return _tvseriesCard(
                                                context,
                                                id: tvData['id'],
                                                season:
                                                    tvData['currentSeason'] ??
                                                    1,
                                                episode:
                                                    tvData['currentEpisode'] ??
                                                    1,
                                              );
                                            },
                                          ),
                                        SizedBox(height: 10),
                                        const Divider(color: Colors.white24),
                                        SizedBox(height: 10),

                                        _buildSectionTitle(
                                          'Not Started Yet',
                                          unstartedSeries.length,
                                        ),
                                        SizedBox(height: 10),
                                        if (unstartedSeries.isEmpty)
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                            child: Text(
                                              'Baslanmamis dizi bulunmuyor.',
                                            ),
                                          )
                                        else
                                          ListView.separated(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            padding: EdgeInsets.zero,
                                            itemCount: unstartedSeries.length,
                                            separatorBuilder:
                                                (context, index) =>
                                                    SizedBox(height: 15),
                                            itemBuilder: (context, index) {
                                              final tvData =
                                                  unstartedSeries[index].data();
                                              return _tvseriesCard(
                                                context,
                                                id: tvData['id'],
                                                season:
                                                    tvData['currentSeason'] ??
                                                    1,
                                                episode:
                                                    tvData['currentEpisode'] ??
                                                    0,
                                              );
                                            },
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
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

  Widget _buildSectionTitle(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.redAccent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
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
        String title = "Loading...";
        String? backdropPath;
        List<dynamic> seasonsList = [];
        if (snapshot.hasData) {
          title = snapshot.data!['name'] ?? 'Unknown Tv Series';
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
                context.push('/tv-info/$id');
              },
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
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
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: IconButton(
                onPressed: () async {
                  if (seasonsList.isEmpty) return;

                  final currentSeasonData = seasonsList.firstWhere(
                    (s) => s['season_number'] == season,
                    orElse: () => null,
                  );

                  final int maxEpisodesThisSeason = currentSeasonData != null
                      ? (currentSeasonData['episode_count'] ?? 0)
                      : 0;

                  final totalSeasons = seasonsList
                      .where((s) => (s['season_number'] ?? 0) > 0)
                      .length;

                  int nextSeason = season;
                  int nextEpisode = episode + 1;
                  String message = '';

                  if (nextEpisode > maxEpisodesThisSeason) {
                    if (season < totalSeasons) {
                      nextSeason = season + 1;
                      nextEpisode = 1;
                      message =
                          '$title: Sezon $nextSeason, Bölüm 1\'e geçildi!';
                    } else {
                      nextEpisode = maxEpisodesThisSeason;
                      message = '$title dizisini tamamladınız!';
                    }
                  } else {
                    message = '$title: S$nextSeason E$nextEpisode izlendi!';
                  }

                  await DatabaseServices().updateTvProgress(
                    tvId: id,
                    newSeason: nextSeason,
                    newEpisode: nextEpisode,
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
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
