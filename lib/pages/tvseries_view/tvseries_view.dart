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
            const TabBar(
              tabs: [
                Tab(text: "TvSeries"),
                Tab(text: "History"),
              ],
            ),
            Expanded(
              child: currentUser == null
                  ? const Center(
                      child: Text(
                        'Kütüphanenizi görmek için lütfen giriş yapınız.',
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
                        final tvListDocId = listSnapshot.data!.docs.first.id;
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

                            final allDocs = itemsSnapshot.data?.docs ?? [];

                            // Tamamlanmamış diziler
                            final unwatchDocs = allDocs.where((doc) {
                              final data = doc.data();
                              return (data['isWatched'] ?? false) == false;
                            }).toList();

                            // History (Tamamlananlar)
                            final historyDocs = allDocs.where((doc) {
                              final data = doc.data();
                              return (data['isWatched'] ?? false) == true;
                            }).toList();

                            // 1. Currently Watching
                            final inProgressSeries = unwatchDocs.where((doc) {
                              final data = doc.data();
                              final isStopped = data['isStopped'] ?? false;
                              return !isStopped &&
                                  (data['currentEpisode'] ?? 0) > 0;
                            }).toList();

                            // 2. Watching Stopped
                            final stoppedSeries = unwatchDocs.where((doc) {
                              final data = doc.data();
                              return (data['isStopped'] ?? false) == true;
                            }).toList();

                            // 3. Not Started Yet
                            final unstartedSeries = unwatchDocs.where((doc) {
                              final data = doc.data();
                              final isStopped = data['isStopped'] ?? false;
                              return !isStopped &&
                                  (data['currentEpisode'] ?? 0) == 0;
                            }).toList();

                            if (!itemsSnapshot.hasData ||
                                itemsSnapshot.data!.docs.isEmpty) {
                              return Center(
                                child: Text(
                                  "Kütüphanenizde henüz ekli dizi bulunmuyor.",
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.tertiary,
                                  ),
                                ),
                              );
                            }

                            return TabBarView(
                              children: [
                                SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(
                                    parent: BouncingScrollPhysics(),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 15),

                                      // --- CURRENTLY WATCHING SECTION ---
                                      _buildSectionTitle(
                                        context,
                                        'Currently Watching',
                                        inProgressSeries.length,
                                      ),

                                      const SizedBox(height: 10),
                                      if (inProgressSeries.isEmpty)
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          child: Text(
                                            'Şu an izlemekte olduğunuz bir dizi yok.',
                                          ),
                                        )
                                      else
                                        ListView.separated(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          padding: EdgeInsets.zero,
                                          itemCount: inProgressSeries.length,
                                          separatorBuilder: (context, index) =>
                                              const SizedBox(height: 15),
                                          itemBuilder: (context, index) {
                                            final tvData =
                                                inProgressSeries[index].data();
                                            return _tvseriesCard(
                                              context,
                                              id: tvData['id'],
                                              season:
                                                  tvData['currentSeason'] ?? 1,
                                              episode:
                                                  tvData['currentEpisode'] ?? 1,
                                              isHistory: false,
                                            );
                                          },
                                        ),

                                      const SizedBox(height: 10),
                                      Divider(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onTertiary,
                                      ),
                                      const SizedBox(height: 10),

                                      // --- WATCHING STOPPED SECTION ---
                                      _buildSectionTitle(
                                        context,
                                        'Watching Stopped',
                                        stoppedSeries.length,
                                      ),
                                      const SizedBox(height: 10),
                                      if (stoppedSeries.isEmpty)
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          child: Text(
                                            'İzlemeyi bıraktığınız dizi bulunmuyor.',
                                          ),
                                        )
                                      else
                                        ListView.separated(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          padding: EdgeInsets.zero,
                                          itemCount: stoppedSeries.length,
                                          separatorBuilder: (context, index) =>
                                              const SizedBox(height: 15),
                                          itemBuilder: (context, index) {
                                            final tvData = stoppedSeries[index]
                                                .data();
                                            return _tvseriesCard(
                                              context,
                                              id: tvData['id'],
                                              season:
                                                  tvData['currentSeason'] ?? 1,
                                              episode:
                                                  tvData['currentEpisode'] ?? 0,
                                              isHistory: false,
                                            );
                                          },
                                        ),

                                      const SizedBox(height: 10),
                                      Divider(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onTertiary,
                                      ),
                                      const SizedBox(height: 10),

                                      // --- NOT STARTED YET SECTION ---
                                      _buildSectionTitle(
                                        context,
                                        'Not Started Yet',
                                        unstartedSeries.length,
                                      ),
                                      const SizedBox(height: 10),
                                      if (unstartedSeries.isEmpty)
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          child: Text(
                                            'Başlanmamış dizi bulunmuyor.',
                                          ),
                                        )
                                      else
                                        ListView.separated(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          padding: EdgeInsets.zero,
                                          itemCount: unstartedSeries.length,
                                          separatorBuilder: (context, index) =>
                                              const SizedBox(height: 15),
                                          itemBuilder: (context, index) {
                                            final tvData =
                                                unstartedSeries[index].data();
                                            return _tvseriesCard(
                                              context,
                                              id: tvData['id'],
                                              season:
                                                  tvData['currentSeason'] ?? 1,
                                              episode:
                                                  tvData['currentEpisode'] ?? 0,
                                              isHistory: false,
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                ),

                                // --- HISTORY TAB ---
                                historyDocs.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'Henüz tamamlanmış veya izlenmiş bir dizi yok!',
                                        ),
                                      )
                                    : ListView.separated(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        physics: const BouncingScrollPhysics(),
                                        itemCount: historyDocs.length,
                                        separatorBuilder: (context, index) =>
                                            const SizedBox(height: 15),
                                        itemBuilder: (context, index) {
                                          final tvData = historyDocs[index]
                                              .data();
                                          return _tvseriesCard(
                                            context,
                                            id: tvData['id'],
                                            season:
                                                tvData['currentSeason'] ?? 1,
                                            episode:
                                                tvData['currentEpisode'] ?? 1,
                                            isHistory: true,
                                          );
                                        },
                                      ),
                              ],
                            );
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
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
    required bool isHistory,
  }) {
    return FutureBuilder<Map<String, dynamic>>(
      future: TmdbApiService().getTvSeriesDetails(id),
      builder: (context, snapshot) {
        String title = "Loading...";
        String? backdropPath;
        List<dynamic> seasonsList = [];

        if (snapshot.hasData && snapshot.data != null) {
          title = snapshot.data!['name'] ?? 'Unknown Tv Series';
          backdropPath = snapshot.data!['backdrop_path'];
          seasonsList = snapshot.data!['seasons'] ?? [];
        }

        final String backdropUrl =
            (backdropPath != null && backdropPath.isNotEmpty)
            ? 'https://image.tmdb.org/t/p/w780$backdropPath'
            : '';

        // --- 1. ÖNCE SIRADAKİ DOĞRU SEZON VE BÖLÜMÜ HESAPLIYORUZ ---
        int displaySeason = season;
        int displayEpisode = episode + 1;

        if (seasonsList.isNotEmpty) {
          final currentSeasonData = seasonsList.firstWhere(
            (s) => s['season_number'] == season,
            orElse: () => null,
          );

          final int maxEpisodesThisSeason = currentSeasonData != null
              ? (currentSeasonData['episode_count'] ?? 0)
              : 0;

          if (maxEpisodesThisSeason > 0 && (episode >= maxEpisodesThisSeason)) {
            final totalSeasons = seasonsList
                .where((s) => (s['season_number'] ?? 0) > 0)
                .length;

            if (season < totalSeasons) {
              displaySeason = season + 1;
              displayEpisode = 1;
            } else {
              displayEpisode = maxEpisodesThisSeason;
            }
          }
        }

        // Bölüm İlerleme Fonksiyonu
        Future<void> onIncrementEpisode() async {
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
              message = '$title: Sezon $nextSeason, Bölüm 1\'e geçildi!';
            } else {
              nextEpisode = maxEpisodesThisSeason;
              message =
                  '$title dizisini tamamladınız ve History tabına taşındı!';

              await DatabaseServices().toggleTvWatchedStatus(
                tvId: id,
                isWatched: true,
              );
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
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
              ),
            );
          }
        }

        // --- 2. DOĞRU SEZON İÇİN BÖLÜM İSMİNİ ÇEKİYORUZ ---
        return FutureBuilder<Map<String, dynamic>>(
          // Yanlış olan 'season' yerine doğru hesaplanan 'displaySeason' veriyoruz:
          future: TmdbApiService().getTvSeasonDetails(id, displaySeason),
          builder: (context, seasonSnapshot) {
            String episodeTitle = '';

            if (seasonSnapshot.hasData && seasonSnapshot.data != null) {
              final episodes =
                  seasonSnapshot.data!['episodes'] as List<dynamic>? ?? [];
              final currentEpisodeData = episodes.firstWhere(
                (ep) => ep['episode_number'] == displayEpisode,
                orElse: () => null,
              );

              if (currentEpisodeData != null) {
                episodeTitle = currentEpisodeData['name'] ?? '';

                // Türkçe boş veya varsayılan "Bölüm X" gibi gelirse kontrol et
                if (episodeTitle.isEmpty ||
                    episodeTitle.startsWith('Episode ')) {
                  episodeTitle = currentEpisodeData['name'] ?? '';
                }

                // Karakter Sınırlama (18 Karakter)
                if (episodeTitle.length > 18) {
                  episodeTitle = '${episodeTitle.substring(0, 18)}...';
                }
              }
            }

            Widget buildCardWithButton() {
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
                            vertical: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              RichText(
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  children: [
                                    TextSpan(text: title),
                                    if (episodeTitle.isNotEmpty &&
                                        !isHistory) ...[
                                      const TextSpan(text: ' - '),
                                      TextSpan(
                                        text: episodeTitle,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontStyle: FontStyle.italic,
                                          fontWeight: FontWeight.normal,
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isHistory
                                    ? 'Tamamlandı'
                                    : 'Sıradaki: Sezon $displaySeason Bölüm $displayEpisode',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onTertiary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: isHistory
                        ? IconButton(
                            tooltip: "İzleneceklere geri taşı",
                            onPressed: () async {
                              await DatabaseServices().toggleTvWatchedStatus(
                                tvId: id,
                                isWatched: false,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '$title dizisi TvSeries tabına geri alındı!',
                                    ),
                                    duration: const Duration(seconds: 1),
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.errorContainer,
                                  ),
                                );
                              }
                            },
                            icon: Icon(
                              Icons.check_circle,
                              color: Theme.of(
                                context,
                              ).colorScheme.errorContainer,
                              size: 26,
                            ),
                          )
                        : IconButton(
                            tooltip: 'Bölümü izlendi işaretle',
                            onPressed: onIncrementEpisode,
                            icon: Icon(
                              Icons.add_circle_outline_outlined,
                              color: Theme.of(context).colorScheme.tertiary,
                              size: 25,
                            ),
                          ),
                  ),
                ],
              );
            }

            if (isHistory) {
              return buildCardWithButton();
            }

            return Dismissible(
              key: Key('tv_card_$id'),
              direction: DismissDirection.horizontal,
              background: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: Colors.white,
                      size: 28,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Bölümü İzle',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              secondaryBackground: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'İzlemeyi Bırak',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.pause_circle_outline,
                      color: Colors.white,
                      size: 28,
                    ),
                  ],
                ),
              ),
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.startToEnd) {
                  await onIncrementEpisode();
                  return false;
                } else if (direction == DismissDirection.endToStart) {
                  await DatabaseServices().toggleTvStoppedStatus(
                    tvId: id,
                    isStopped: true,
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '$title izlemeyi bıraktıklarınıza taşındı.',
                        ),
                        duration: const Duration(seconds: 1),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.errorContainer,
                      ),
                    );
                  }
                  return false;
                }
                return false;
              },
              child: buildCardWithButton(),
            );
          },
        );
      },
    );
  }
}
