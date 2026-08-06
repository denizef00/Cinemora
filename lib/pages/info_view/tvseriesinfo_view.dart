import 'package:cinemora/services/tmdb_services.dart';
import 'package:flutter/material.dart';

class TvSeriesInfo extends StatefulWidget {
  final int tvId;
  const TvSeriesInfo({super.key, required this.tvId});

  @override
  State<TvSeriesInfo> createState() => _TvSeriesInfoState();
}

class _TvSeriesInfoState extends State<TvSeriesInfo> {
  late Future<Map<String, dynamic>> _tvDetailsFuture;
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

          final tv = snapshot.data!;
          final String title = tv['name'] ?? '';
          final int seasonsCount = tv['number_of_seasons'] ?? 0;
          final String totalSeason =
              '$seasonsCount Season${seasonsCount > 1 ? 's' : ''}';
          final bool isEnded = tv['status'] == 'Ended';
          final String firstAirDate = tv['first_air_date'] ?? 'Bilinmiyor';
          final double voteAverage =
              (tv['vote_average'] as num?)?.toDouble() ?? 0.0;
          final String rating = '%${(voteAverage * 10).toInt()}';
          final String overview = tv['overview'] ?? '';
          final String? backdropPath = tv['backdrop_path'];

          final genresList = tv['genres'] ?? [];

          final type = genresList.isNotEmpty
              ? genresList.map((g) => g['name']).take(2).join(', ')
              : 'Tv Series';

          final String backdropUrl =
              backdropPath != null && backdropPath.isNotEmpty
              ? 'https://image.tmdb.org/t/p/w780$backdropPath'
              : '';

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
                              color: Colors.red,
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
                        child: IconButton(
                          icon: const Icon(
                            Icons.favorite_border,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Add Fav Button')),
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
                      onPressed: () {},
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
                            rating,
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
                    Center(child: Text('Cast')),
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
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          'Episodes List',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
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
}
