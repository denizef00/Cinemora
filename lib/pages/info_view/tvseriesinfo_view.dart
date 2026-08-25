import 'package:cinemora/models/cast_model.dart';
import 'package:cinemora/models/tvseries_model.dart';
import 'package:cinemora/services/database_services.dart';
import 'package:cinemora/services/tmdb_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TvSeriesInfo extends StatefulWidget {
  final int tvId;
  const TvSeriesInfo({super.key, required this.tvId});

  @override
  State<TvSeriesInfo> createState() => _TvSeriesInfoState();
}

class _TvSeriesInfoState extends State<TvSeriesInfo> {
  late Future<Map<String, dynamic>> _tvDetailsFuture;
  final Map<int, List<dynamic>> _cachedSeasons = {};
  final Set<int> _loadingSeasons = {};

  Future<List<dynamic>> _loadSeasonEpisodes(int tvId, int seasonNumber) async {
    if (_cachedSeasons.containsKey(seasonNumber)) {
      return _cachedSeasons[seasonNumber]!;
    }

    final data = await TmdbApiService().getSeasonDetails(tvId, seasonNumber);
    final episodes = (data['episodes'] as List<dynamic>?) ?? [];
    _cachedSeasons[seasonNumber] = episodes;
    return episodes;
  }

  int _selectedTab = 0;
  @override
  void initState() {
    super.initState();
    _tvDetailsFuture = TmdbApiService().getTvSeriesDetails(widget.tvId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _tvDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Dizi detayları yüklenemedi.'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Geri Dön'),
                  ),
                ],
              ),
            );
          }
          final tvModel = TvseriesModel.fromJson(snapshot.data!);
          final tv = snapshot.data!;
          final String title = tvModel.name;
          final String? backdropPath = tvModel.backdropPath;
          final String? posterPath = tvModel.posterPath;
          final double voteAverage = tvModel.voteAverage;
          final String firstAirDate = tvModel.firstAirDate ?? 'Bilinmiyor';
          final String overview = tvModel.overview;
          // Ham json'dan kalan alanlar:
          final int seasonsCount = snapshot.data!['number_of_seasons'] ?? 0;
          final String totalSeason =
              '$seasonsCount Season${seasonsCount > 1 ? 's' : ''}';
          final bool isEnded = snapshot.data!['status'] == 'Ended';
          final genresList = snapshot.data!['genres'] ?? [];

          final type = genresList.isNotEmpty
              ? genresList.map((g) => g['name']).take(2).join(', ')
              : 'Tv Series';

          final String backdropUrl =
              backdropPath != null && backdropPath.isNotEmpty
              ? 'https://image.tmdb.org/t/p/w780$backdropPath'
              : '';

          final Map<String, dynamic> mediaData = {
            'id': widget.tvId,
            'title': title,
            'posterPath': posterPath ?? '',
            'backdropPath': backdropPath ?? '',
            'voteAverage': voteAverage,
            'mediaType': 'tv',
            'currentSeason': 1,
            'currentEpisodes': 0,
          };
          return SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16.0),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    alignment: Alignment.topLeft,

                    children: [
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Theme.of(context).colorScheme.surface,
                              image: backdropUrl.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(backdropUrl),
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
                                    Colors.black.withOpacity(0.85),

                                    Colors.transparent,
                                    Colors.black.withOpacity(0.85),
                                  ],
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$totalSeason • ${isEnded ? "Ended" : "Continues"}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),

                      Positioned(
                        top: 8,
                        right: 8,
                        child: StreamBuilder<bool>(
                          stream: DatabaseServices().isFavoriteStream(
                            widget.tvId,
                          ),
                          builder: (context, snapshot) {
                            final isFav = snapshot.data ?? false;

                            return IconButton(
                              icon: Icon(
                                size: 28,

                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav
                                    ? Theme.of(context).colorScheme.onSecondary
                                    : Theme.of(context).colorScheme.tertiary,
                              ),
                              onPressed: () async {
                                final isAdded = await DatabaseServices()
                                    .toggleFavorite(mediaData: mediaData);

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isAdded
                                            ? 'Added to Favorites!'
                                            : 'Removed from Favorites!',
                                      ),
                                      duration: const Duration(seconds: 1),
                                      backgroundColor: isAdded
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.errorContainer
                                          : Theme.of(context).colorScheme.error,
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        showAddToListBottomSheet(context, mediaData: mediaData);
                      },
                      child: Text(
                        "Add Library",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.tertiary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 5),

                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: _selectedTab == 0
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.white24,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'DETAILS',
                                style: TextStyle(
                                  color: _selectedTab == 0
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.white60,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: _selectedTab == 1
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.white24,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'EPISODES',
                                style: TextStyle(
                                  color: _selectedTab == 1
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.white60,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_selectedTab == 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Show Details',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$firstAirDate • $type',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.redAccent,
                              width: 2.5,
                            ),
                          ),
                          child: Text(
                            voteAverage.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Divider(color: Colors.white24),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Watch Trailer")),
                        );
                      },
                      child: Container(
                        alignment: Alignment.centerLeft,
                        height: 80,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.transparent,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              Container(
                                height: 60,
                                width: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.amber,
                                ),
                                child: Icon(Icons.play_arrow_rounded),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Watch Trailer',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const Divider(color: Colors.white24),
                    const SizedBox(height: 16),
                    const Text(
                      'Cast',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildCastSection(tvModel.cast),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 16),
                    const Text(
                      'Overview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161F33),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        overview.isNotEmpty ? overview : 'Açıklama bulunmuyor.',
                        style: const TextStyle(
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ] else ...[
                    _buildEpisodesSection(
                      currentUser: FirebaseAuth.instance.currentUser,
                      tvId: widget.tvId,
                      title: title,
                      seasons: tv['seasons'] ?? [],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCastSection(List<CastModel> cast) {
    if (cast.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'Oyuncu bilgisi bulunamadı.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Actor Sitesi')));
      },
      child: SizedBox(
        height: 150,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: cast.length > 15 ? 15 : cast.length,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final actor = cast[index];
            return ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 105,
                height: 150,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      actor.fullProfilePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFF1E293B),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white54,
                          size: 36,
                        ),
                      ),
                    ),

                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.2),
                            Colors.black.withOpacity(0.9),
                          ],
                          stops: const [0.4, 0.65, 1.0],
                        ),
                      ),
                    ),

                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            actor.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            actor.character,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void showAddToListBottomSheet(
    BuildContext context, {
    required Map<String, dynamic> mediaData,
  }) {
    final DatabaseServices dbService = DatabaseServices();
    final String mediaType = mediaData['mediaType'] ?? '';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Add to Library"),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              SizedBox(height: 10),

              StreamBuilder<QuerySnapshot>(
                stream: dbService.getUserLists(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No list found. Please login or create a list.',
                      ),
                    );
                  }
                  final filteredLists = snapshot.data!.docs.where((doc) {
                    final listData = doc.data() as Map<String, dynamic>;
                    final String listType = listData['type'] ?? '';

                    if (mediaType == 'tv' && listType == 'movie') {
                      return false;
                    }

                    if (mediaType == 'movie' && listType == 'tv') {
                      return false;
                    }

                    return true;
                  }).toList();

                  if (filteredLists.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Uygun bir liste bulunamadı.'),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredLists.length,
                    itemBuilder: (context, index) {
                      final listDoc = filteredLists[index];
                      final listData = listDoc.data() as Map<String, dynamic>;
                      final listName = listData['name'] ?? 'List';

                      return ListTile(
                        leading: Icon(
                          _getIconForList(listData['type']),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(listName),
                        trailing: const Icon(Icons.add, size: 20),
                        onTap: () async {
                          try {
                            await dbService.addMediaToList(
                              listId: listDoc.id,
                              mediaData: mediaData,
                            );

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Added to "$listName" successfully!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to add: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  IconData? _getIconForList(String? type) {
    switch (type) {
      case 'tv':
        return Icons.tv;
      case 'fav':
        return Icons.favorite;
      default:
        return Icons.bookmark_border;
    }
  }

  Widget _buildEpisodesSection({
    required User? currentUser,
    required int tvId,
    required String title,
    required List<dynamic> seasons,
  }) {
    final validSeasons = seasons
        .where((s) => (s['season_number'] ?? 0) > 0)
        .toList();

    if (validSeasons.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'Bölüm bilgisi bulunamadı.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    if (currentUser == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'Bölüm takibi için lütfen giriş yapın.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('lists')
          .where('type', isEqualTo: 'tv')
          .limit(1)
          .snapshots(),
      builder: (context, listSnap) {
        if (!listSnap.hasData || listSnap.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'Dizi listeniz bulunamadı.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        final tvListDocId = listSnap.data!.docs.first.id;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .collection('lists')
              .doc(tvListDocId)
              .collection('items')
              .where('id', isEqualTo: tvId)
              .limit(1)
              .snapshots(),
          builder: (context, itemSnap) {
            final isItemInList =
                itemSnap.hasData && itemSnap.data!.docs.isNotEmpty;

            final String itemDocId = isItemInList
                ? itemSnap.data!.docs.first.id
                : '';
            final Map<String, dynamic> itemData = isItemInList
                ? itemSnap.data!.docs.first.data() as Map<String, dynamic>
                : {};

            final int currentSeason = itemData['currentSeason'] ?? 1;
            final int currentEpisode = itemData['currentEpisode'] ?? 0;
            final bool isWatchedAll = itemData['isWatched'] ?? false;

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: validSeasons.length,
              itemBuilder: (context, index) {
                final season = validSeasons[index];
                final int seasonNumber = season['season_number'] ?? 1;
                final String seasonName =
                    season['name'] ?? 'Season $seasonNumber';
                final int episodeCount = season['episode_count'] ?? 0;

                final bool isThisSeasonFullyWatched =
                    isWatchedAll ||
                    (seasonNumber < currentSeason) ||
                    (seasonNumber == currentSeason &&
                        currentEpisode >= episodeCount &&
                        episodeCount > 0);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161F33),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      collapsedIconColor: Colors.white70,
                      iconColor: Theme.of(context).colorScheme.primary,
                      title: Text(
                        seasonName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        '$episodeCount Episodes',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: isThisSeasonFullyWatched
                                ? "Sezonu izlenmedi yap"
                                : "Tüm sezonu izlendi işaretle",
                            icon: Icon(
                              isThisSeasonFullyWatched
                                  ? Icons.check_circle
                                  : Icons.check_circle_outline_outlined,
                              color: isThisSeasonFullyWatched
                                  ? Colors.greenAccent
                                  : Colors.white54,
                              size: 24,
                            ),
                            onPressed: () async {
                              if (!isItemInList) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Lütfen önce diziyi kütüphanenize ekleyin.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              final int lastSeasonNumber =
                                  validSeasons.last['season_number'] ?? 1;
                              final bool isLastSeason =
                                  seasonNumber == lastSeasonNumber;

                              int targetSeason = seasonNumber;
                              int targetEpisode = episodeCount;
                              bool targetWatched = false;

                              if (isThisSeasonFullyWatched) {
                                // Sezon zaten tamamen izlendiyse: bu sezonu sıfırla (önceki sezonun sonuna ya da 0'a çek)
                                if (seasonNumber > 1) {
                                  targetSeason = seasonNumber - 1;
                                  final prevSeason = validSeasons.firstWhere(
                                    (s) => s['season_number'] == targetSeason,
                                    orElse: () => null,
                                  );
                                  targetEpisode = prevSeason != null
                                      ? (prevSeason['episode_count'] ?? 1)
                                      : 1;
                                } else {
                                  targetSeason = 1;
                                  targetEpisode = 0;
                                }
                                targetWatched = false;
                              } else {
                                // Sezon izlendi olarak işaretleniyor
                                targetSeason = seasonNumber;
                                targetEpisode = episodeCount;
                                if (isLastSeason) {
                                  targetWatched = true;
                                }
                              }

                              await DatabaseServices().setTvProgress(
                                listId: tvListDocId,
                                mediaDocId: itemDocId,
                                targetSeason: targetSeason,
                                targetEpisode: targetEpisode,
                                isWatched: targetWatched,
                              );

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      targetWatched
                                          ? '$title tamamlandı ve History tabına taşındı!'
                                          : '$seasonName ${isThisSeasonFullyWatched ? "izlenmedi olarak güncellendi" : "tamamen izlendi olarak işaretlendi"}.',
                                    ),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                          ),
                          const Icon(Icons.expand_more, color: Colors.white70),
                        ],
                      ),
                      children: [
                        FutureBuilder<List<dynamic>>(
                          future: _loadSeasonEpisodes(tvId, seasonNumber),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.waiting &&
                                !_cachedSeasons.containsKey(seasonNumber)) {
                              return const Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final episodes =
                                _cachedSeasons[seasonNumber] ??
                                snapshot.data ??
                                [];

                            if (episodes.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'Bölümler yüklenemedi.',
                                  style: TextStyle(color: Colors.white54),
                                ),
                              );
                            }

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              itemCount: episodes.length,
                              separatorBuilder: (context, i) =>
                                  const Divider(color: Colors.white10),
                              itemBuilder: (context, epIndex) {
                                final episode = episodes[epIndex];
                                final int epNumber =
                                    episode['episode_number'] ?? (epIndex + 1);
                                final String epName =
                                    episode['name'] ?? 'Episode $epNumber';
                                final String? stillPath = episode['still_path'];
                                final String stillUrl =
                                    (stillPath != null && stillPath.isNotEmpty)
                                    ? 'https://image.tmdb.org/t/p/w300$stillPath'
                                    : '';

                                bool isThisEpWatched = false;
                                if (isWatchedAll) {
                                  isThisEpWatched = true;
                                } else if (seasonNumber < currentSeason) {
                                  isThisEpWatched = true;
                                } else if (seasonNumber == currentSeason &&
                                    epNumber <= currentEpisode) {
                                  isThisEpWatched = true;
                                }

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          width: 110,
                                          height: 65,
                                          color: Colors.black26,
                                          child: stillUrl.isNotEmpty
                                              ? Image.network(
                                                  stillUrl,
                                                  fit: BoxFit.cover,
                                                )
                                              : const Icon(
                                                  Icons.movie,
                                                  color: Colors.white24,
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '$epNumber. $epName',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: isThisEpWatched
                                                    ? Colors.white70
                                                    : Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            SizedBox(height: 10),
                                            Text(
                                              isThisEpWatched ? 'WATCHED' : '',
                                              style: TextStyle(
                                                color: isThisEpWatched
                                                    ? Colors.white70
                                                    : Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          isThisEpWatched
                                              ? Icons.check_circle
                                              : Icons
                                                    .check_circle_outline_outlined,
                                          color: isThisEpWatched
                                              ? Colors.greenAccent
                                              : Colors.white54,
                                          size: 26,
                                        ),
                                        onPressed: () async {
                                          if (!isItemInList) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Lütfen önce diziyi kütüphanenize ekleyin.',
                                                ),
                                              ),
                                            );
                                            return;
                                          }

                                          final int lastSeasonNumber =
                                              validSeasons
                                                  .last['season_number'] ??
                                              1;
                                          final int lastSeasonEpisodeCount =
                                              validSeasons
                                                  .last['episode_count'] ??
                                              0;
                                          final bool isLastEpisode =
                                              (seasonNumber ==
                                                  lastSeasonNumber) &&
                                              (epNumber >=
                                                  lastSeasonEpisodeCount);

                                          int targetSeason = seasonNumber;
                                          int targetEpisode = epNumber;
                                          bool targetWatched = false;

                                          if (isThisEpWatched) {
                                            if (epNumber > 1) {
                                              targetEpisode = epNumber - 1;
                                            } else if (seasonNumber > 1) {
                                              targetSeason = seasonNumber - 1;
                                              final prevSeason = validSeasons
                                                  .firstWhere(
                                                    (s) =>
                                                        s['season_number'] ==
                                                        targetSeason,
                                                    orElse: () => null,
                                                  );
                                              targetEpisode = prevSeason != null
                                                  ? (prevSeason['episode_count'] ??
                                                        1)
                                                  : 1;
                                            } else {
                                              targetEpisode = 0;
                                            }
                                            targetWatched = false;
                                          } else {
                                            if (isLastEpisode) {
                                              targetWatched = true;
                                            }
                                          }

                                          await DatabaseServices()
                                              .setTvProgress(
                                                listId: tvListDocId,
                                                mediaDocId: itemDocId,
                                                targetSeason: targetSeason,
                                                targetEpisode: targetEpisode,
                                                isWatched: targetWatched,
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
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
