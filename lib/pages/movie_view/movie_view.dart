import 'package:cinemora/services/database_services.dart';
import 'package:cinemora/services/tmdb_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MovieView extends StatelessWidget {
  const MovieView({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
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
              child: currentUser == null
                  ? const Center(
                      child: Text(
                        "Kütüphanenizi görmek için lütfen giriş yapın.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUser.uid)
                          .collection('lists')
                          .where('type', isEqualTo: 'movie')
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
                            child: Text("Movies listesi bulunamadı."),
                          );
                        }
                        final movieListDocId = listSnapshot.data!.docs.first.id;

                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(currentUser.uid)
                              .collection('lists')
                              .doc(movieListDocId)
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

                            final allMovieDocs = itemsSnapshot.data?.docs ?? [];

                            final unwatchMovies = allMovieDocs.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return (data['isWatched'] ?? false) == false;
                            }).toList();

                            final historyMovies = allMovieDocs.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return (data['isWatched'] ?? false) == true;
                            }).toList();
                            return TabBarView(
                              children: [
                                _buildMovieGrid(
                                  context,
                                  movies: unwatchMovies,
                                  emptyMessage: "İzlenecek film bulunmuyor.",
                                  isHistoryTab: false,
                                ),

                                _buildMovieGrid(
                                  context,
                                  movies: historyMovies,
                                  emptyMessage: "Henüz izlenen bir film yok.",
                                  isHistoryTab: true,
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
            ),
            Center(child: Text('History')),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieGrid(
    BuildContext context, {
    required List<QueryDocumentSnapshot> movies,
    required String emptyMessage,
    required bool isHistoryTab,
  }) {
    if (movies.isEmpty) {
      return Center(
        child: Text(emptyMessage, style: const TextStyle(color: Colors.grey)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 20),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 120 / 200,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movieData = movies[index].data() as Map<String, dynamic>;
          final int id = movieData['id'];

          return _movieCard(context, id: id, isWatched: isHistoryTab);
        },
      ),
    );
  }

  Widget _movieCard(
    BuildContext context, {
    required int id,
    required bool isWatched,
  }) {
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
                context.push('/movie-info/$id');
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
                onPressed: () async {
                  final newStatus = !isWatched;

                  await DatabaseServices().toggleMovieWatchedStatus(
                    movieId: id,
                    isWatched: newStatus,
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          newStatus
                              ? 'Film History (İzlenenler) tabına taşındı!'
                              : 'Film Unwatch (İzlenecekler) tabına geri alındı!',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                },
                icon: Icon(
                  isWatched
                      ? Icons.check_circle
                      : Icons.check_circle_outline_outlined,
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
