import 'package:cinemora/app/router.dart';
import 'package:cinemora/services/media_item.dart';
import 'package:cinemora/services/tmdb_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final currentUser = snapshot.data;

        if (currentUser == null) {
          return _buildLoggedOutView(context);
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 50),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                Column(
                  children: [
                    Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.account_circle_outlined,
                        size: 60,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                    SizedBox(height: 10),
                    FutureBuilder(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUser.uid)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        }

                        String username = 'User';
                        if (userSnapshot.hasData && userSnapshot.data!.exists) {
                          final data = userSnapshot.data!.data();
                          username =
                              data?['username'] ??
                              currentUser.email?.split('@')[0] ??
                              "User";
                        } else if (currentUser.displayName != null &&
                            currentUser.displayName!.isNotEmpty) {
                          username = currentUser.displayName!;
                        }
                        return Text(
                          username,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.tertiary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                      },
                      icon: Icon(
                        Icons.logout,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      label: const Text('Sign Out'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    /*
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Your Lists',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.tertiary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    _listsCard(userId: currentUser.uid, listIdentifier: 'fav'),
*/
                    SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Tv Series',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.tertiary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    _listsCard(
                      userId: currentUser.uid,
                      listIdentifier: 'tv',
                      isTv: true,
                    ),
                    SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Movies',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.tertiary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    _listsCard(
                      userId: currentUser.uid,
                      listIdentifier: 'movie',
                      isTv: false,
                    ),
                    SizedBox(height: 20),
                  ],
                ),
                GestureDetector(
                  //silinecek bu
                  onTap: () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('SETTINGS')));
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.settings,
                      color: Theme.of(context).colorScheme.primary,
                      size: 25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _listsCard({
    required String userId,
    required String listIdentifier,
    required bool isTv,
  }) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: StreamBuilder<List<MediaItem>>(
        stream: getProfilePreview(userId: userId, listName: listIdentifier),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!;

          return Row(
            children: [
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text(
                          'Henuz ekleme yapilmadi.',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.tertiary.withOpacity(0.6),
                            fontSize: 13,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(10),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) =>
                            _miniCard(items[index], isTv: isTv),
                      ),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.arrow_forward_ios_rounded, size: 24),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _miniCard(MediaItem item, {required bool isTv}) {
    final int mediaId = item.id;

    return FutureBuilder<Map<String, dynamic>>(
      // Dizi ise getTvDetails, film ise getMovieDetails çağrılır
      future: isTv
          ? TmdbApiService().getTvSeriesDetails(mediaId)
          : TmdbApiService().getMovieDetails(mediaId),
      builder: (context, snapshot) {
        String? posterPath;

        if (snapshot.hasData && snapshot.data != null) {
          posterPath = snapshot.data!['poster_path'];
        }

        final String? posterUrl = (posterPath != null && posterPath.isNotEmpty)
            ? 'https://image.tmdb.org/t/p/w500$posterPath'
            : null;

        return GestureDetector(
          onTap: () {
            if (isTv) {
              context.push('/tv-info/${snapshot.data!['id']}');
            } else {
              context.push('/movie-info/${snapshot.data!['id']}');
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 100,
              width: 70,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                image: posterUrl != null
                    ? DecorationImage(
                        image: NetworkImage(posterUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: (snapshot.connectionState == ConnectionState.waiting)
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : (posterUrl == null ? _errorPlaceholder() : null),
            ),
          ),
        );
      },
    );
  }

  Widget _errorPlaceholder() {
    return Container(
      color: Colors.grey[800],
      child: const Icon(Icons.movie, color: Colors.white54, size: 28),
    );
  }

  Widget _buildLoggedOutView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 80, color: Colors.amber),
            SizedBox(height: 16),
            Text('Giris Yapilmis Kullanici Bulunamadi'),
            SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () {
                    context.push(AppRoutes.login);
                  },
                  child: Text('Login'),
                ),
                SizedBox(width: 20),

                OutlinedButton(
                  onPressed: () async {
                    context.push(AppRoutes.signup);
                  },
                  child: Text('SignUp'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Stream<List<MediaItem>> getProfilePreview({
    required String userId,
    required String listName,
  }) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('lists')
        .where('type', isEqualTo: listName)
        .limit(1)
        .snapshots()
        .asyncMap((listSnapshot) async {
          if (listSnapshot.docs.isEmpty) return <MediaItem>[];

          final listDocId = listSnapshot.docs.first.id;

          final itemsSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('lists')
              .doc(listDocId)
              .collection('items')
              .limit(10)
              .get();

          return itemsSnapshot.docs
              .map((doc) => MediaItem.fromJson(doc.data()))
              .toList();
        });
  }
}
