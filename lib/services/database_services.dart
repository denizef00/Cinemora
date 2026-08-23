import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot> getUserLists() {
    String? uid = _auth.currentUser?.uid;

    if (uid == null) return Stream.empty();

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('lists')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Future<void> addMediaToList({
    required String listId,
    required Map<String, dynamic> mediaData,
  }) async {
    String? uid = _auth.currentUser?.uid;

    if (uid == null) throw Exception('Kullanici oturum acmamis!');

    String mediaId = mediaData['id'].toString();

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('lists')
        .doc(listId)
        .collection('items')
        .doc(mediaId)
        .set({...mediaData, 'addedAt': FieldValue.serverTimestamp()});
  }

  Future<void> updateTvProgress({
    required int tvId,
    required int newSeason,
    required int newEpisode,
  }) async {
    try {
      String? uid = _auth.currentUser?.uid;

      if (uid == null) return;

      final listSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('lists')
          .where('type', isEqualTo: 'tv')
          .get();
      if (listSnapshot.docs.isEmpty) {
        print('HATA: TV Series listesi bulunamadı.');
        return;
      }

      String tvListDocId = listSnapshot.docs.first.id;

      final itemSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('lists')
          .doc(tvListDocId)
          .collection('items')
          .where('id', isEqualTo: tvId)
          .get();
      if (itemSnapshot.docs.isNotEmpty) {
        String itemDocId = itemSnapshot.docs.first.id;

        await _firestore
            .collection('users')
            .doc(uid)
            .collection('lists')
            .doc(tvListDocId)
            .collection('items')
            .doc(itemDocId)
            .update({'currentSeason': newSeason, 'currentEpisode': newEpisode});

        print("Başarıyla güncellendi: S$newSeason E$newEpisode");
      } else {
        print("HATA: $tvId ID'li dizi kütüphanede bulunamadı.");
      }
    } catch (e) {
      print("Bölüm güncellenirken hata oluştu: $e");
      rethrow;
    }
  }

  Future<void> toggleMovieWatchedStatus({
    required int movieId,
    required bool isWatched,
  }) async {
    try {
      String? uid = _auth.currentUser?.uid;
      if (uid == null) return;

      final listSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('lists')
          .where('type', isEqualTo: 'movie')
          .get();

      if (listSnapshot.docs.isEmpty) return;

      String movieListDocId = listSnapshot.docs.first.id;

      final itemSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('lists')
          .doc(movieListDocId)
          .collection('items')
          .where('id', isEqualTo: movieId)
          .get();

      if (itemSnapshot.docs.isNotEmpty) {
        String itemDocId = itemSnapshot.docs.first.id;

        await _firestore
            .collection('users')
            .doc(uid)
            .collection('lists')
            .doc(movieListDocId)
            .collection('items')
            .doc(itemDocId)
            .update({
              'isWatched': isWatched,
              'watchedAt': isWatched ? FieldValue.serverTimestamp() : null,
            });
      }
    } catch (e) {
      print("Film durumu güncellenirken hata: $e");
    }
  }

  Future<void> incrementEpisode({
    required String listId,
    required String mediaDocId,
    required int currentSeason,
    required int currentEpisode,
    required List<dynamic> seasonsData,
  }) async {
    final currentSeasonObj = seasonsData.firstWhere(
      (s) => s['season_number'] == currentSeason,
      orElse: () => null,
    );

    final int maxEpisodesInSeason = currentSeasonObj != null
        ? currentSeasonObj['episode_count']
        : 0;
    final int totalSeasons = seasonsData
        .where((s) => s['season_number'] > 0)
        .length;

    int nextEpisode = currentEpisode + 1;
    int nextSeason = currentSeason;

    if (nextEpisode > maxEpisodesInSeason) {
      if (currentSeason < totalSeasons) {
        nextSeason = currentSeason + 1;
        nextEpisode = 1;
      } else {
        nextEpisode = maxEpisodesInSeason;
      }
    }

    await FirebaseFirestore.instance
        .collection('user_lists')
        .doc(listId)
        .collection('items')
        .doc(mediaDocId)
        .update({'currentSeason': nextSeason, 'currentEpisodes': nextEpisode});
  }

  Future<bool> toggleFavorite({required Map<String, dynamic> mediaData}) async {
    try {
      String? uid = _auth.currentUser?.uid;
      if (uid == null) return false;

      final listSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('lists')
          .where('type', isEqualTo: 'fav')
          .get();

      if (listSnapshot.docs.isEmpty) return false;

      String favListDocId = listSnapshot.docs.first.id;
      String mediaId = mediaData['id'].toString();

      DocumentReference itemRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('lists')
          .doc(favListDocId)
          .collection('items')
          .doc(mediaId);

      DocumentSnapshot itemDoc = await itemRef.get();

      if (itemDoc.exists) {
        await itemRef.delete();

        return false;
      } else {
        await itemRef.set({
          ...mediaData,
          'addedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }
    } catch (e) {
      print('Favori islemi hatasi : $e');
      return false;
    }
  }

  Stream<bool> isFavoriteStream(int mediaId) {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(false);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('lists')
        .where('type', isEqualTo: 'fav')
        .snapshots()
        .asyncExpand((listSnapshot) {
          if (listSnapshot.docs.isEmpty) return Stream.value(false);

          String favListDocId = listSnapshot.docs.first.id;

          return _firestore
              .collection('users')
              .doc(uid)
              .collection('lists')
              .doc(favListDocId)
              .collection('items')
              .doc(mediaId.toString())
              .snapshots()
              .map((doc) => doc.exists);
        });
  }
}
