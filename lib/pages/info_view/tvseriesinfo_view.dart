import 'package:cinemora/models/cast_model.dart';
import 'package:cinemora/models/tvseries_model.dart';
import 'package:cinemora/services/database_services.dart';
import 'package:cinemora/services/tmdb_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TvSeriesInfo extends StatefulWidget {
  final int tvId;
  const TvSeriesInfo({super.key, required this.tvId});

  @override
  State<TvSeriesInfo> createState() => _TvSeriesInfoState();
}

class _TvSeriesInfoState extends State<TvSeriesInfo> {
  late Future<Map<String, dynamic>> _tvDetailsFuture;
  final Map<int, List<dynamic>> _cachedSeasons = {};
  //final Set<int> _loadingSeasons = {};

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
          final String rating = '%${(voteAverage * 10).toInt()}';
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
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.tertiary,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$totalSeason • ${isEnded ? "Ended" : "Continues"}',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.tertiary,
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
                          icon: Icon(
                            Icons.arrow_back_ios_new,
                            color: Theme.of(context).colorScheme.tertiary,
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
                            Text(
                              'Show Details',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.tertiary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$firstAirDate • $type',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onTertiary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2.5,
                            ),
                          ),
                          child: Text(
                            rating,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.tertiary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    Divider(color: Theme.of(context).colorScheme.onTertiary),
                    GestureDetector(
                      onTap: () {
                        //silinecek bu
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

                    Divider(color: Theme.of(context).colorScheme.onTertiary),
                    const SizedBox(height: 16),
                    Text(
                      'Cast',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.tertiary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildCastSection(tvModel.cast),
                    const SizedBox(height: 20),
                    Divider(color: Theme.of(context).colorScheme.onTertiary),
                    const SizedBox(height: 16),
                    Text(
                      'Overview',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.tertiary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        overview.isNotEmpty ? overview : 'Açıklama bulunmuyor.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.tertiary,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Divider(color: Theme.of(context).colorScheme.onTertiary),
                    const SizedBox(height: 16),
                    Text(
                      'Similar Tv Series',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.tertiary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSimilarSection(widget.tvId),
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

  Widget _buildSimilarSection(int tvId) {
    return FutureBuilder<List<TvseriesModel>>(
      future: TmdbApiService().getSimilarTvSeries(tvId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Benzer dizi bulunamadi.',
              style: TextStyle(color: Theme.of(context).colorScheme.onTertiary),
            ),
          );
        }

        final List<TvseriesModel> shows = snapshot.data!;
        return SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: shows.length > 15 ? 15 : shows.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final show = shows[index];
              return GestureDetector(
                onTap: () {
                  context.push('/tv-info/${show.id}');
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 105,
                    height: 150,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          'https://image.tmdb.org/t/p/w500${show.posterPath ?? ''}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Theme.of(context).colorScheme.surface,
                                child: Icon(
                                  Icons.person,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onTertiary,
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
                                show.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.tertiary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCastSection(List<CastModel> cast) {
    if (cast.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'Oyuncu bilgisi bulunamadı.',
          style: TextStyle(color: Theme.of(context).colorScheme.onTertiary),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        //silinecek bu
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
                        color: Theme.of(context).colorScheme.surface,
                        child: Icon(
                          Icons.person,
                          color: Theme.of(context).colorScheme.onTertiary,
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
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.tertiary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            actor.character,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onTertiary,
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
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.errorContainer,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to add: $e'),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.error,
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
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'Bölüm bilgisi bulunamadı.',
            style: TextStyle(color: Theme.of(context).colorScheme.onTertiary),
          ),
        ),
      );
    }
    if (currentUser == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'Bölüm takibi için lütfen giriş yapın.',
            style: TextStyle(color: Theme.of(context).colorScheme.onTertiary),
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
          return Center(
            child: Text(
              'Dizi listeniz bulunamadı.',
              style: TextStyle(color: Theme.of(context).colorScheme.onTertiary),
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
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      collapsedIconColor: Theme.of(
                        context,
                      ).colorScheme.onTertiary,
                      iconColor: Theme.of(context).colorScheme.primary,
                      title: Text(
                        seasonName,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.tertiary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        '$episodeCount Episodes',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onTertiary,
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
                                  ? Theme.of(context).colorScheme.errorContainer
                                  : Theme.of(context).colorScheme.onTertiary,
                              size: 24,
                            ),
                            onPressed: () async {
                              if (!isItemInList) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Lütfen önce diziyi kütüphanenize ekleyin.',
                                    ),
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.error,
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
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.errorContainer,
                                  ),
                                );
                              }
                            },
                          ),
                          Icon(
                            Icons.expand_more,
                            color: Theme.of(context).colorScheme.onTertiary,
                          ),
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
                              return Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'Bölümler yüklenemedi.',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onTertiary,
                                  ),
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
                              separatorBuilder: (context, i) => Divider(
                                color: Theme.of(context).colorScheme.onTertiary,
                              ),
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
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.surface,
                                          child: stillUrl.isNotEmpty
                                              ? Image.network(
                                                  stillUrl,
                                                  fit: BoxFit.cover,
                                                )
                                              : Icon(
                                                  Icons.movie,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.onTertiary,
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
                                                    ? Theme.of(
                                                        context,
                                                      ).colorScheme.onTertiary
                                                    : Theme.of(
                                                        context,
                                                      ).colorScheme.tertiary,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            SizedBox(height: 10),
                                            Text(
                                              isThisEpWatched ? 'WATCHED' : '',
                                              style: TextStyle(
                                                color: isThisEpWatched
                                                    ? Theme.of(
                                                        context,
                                                      ).colorScheme.onTertiary
                                                    : Theme.of(
                                                        context,
                                                      ).colorScheme.tertiary,
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
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.errorContainer
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.onTertiary,
                                          size: 26,
                                        ),
                                        onPressed: () async {
                                          if (!isItemInList) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Lütfen önce diziyi kütüphanenize ekleyin.',
                                                ),
                                                backgroundColor: Theme.of(
                                                  context,
                                                ).colorScheme.error,
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
