import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  final List<Map<String, dynamic>> _defaultList = [
    {'name': 'TV Series', 'type': 'tv', 'isDefault': true},
    {'name': 'Movies', 'type': 'movie', 'isDefault': true},
    {'name': 'Favorites', 'type': 'fav', 'isDefault': true},
  ];

  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      String uid = userCredential.user!.uid;

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'username': username,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _createDefaultListsIfMissing(uid);

      return userCredential;
    } catch (e) {
      print('Kayit hatasi: $e');
      rethrow;
    }
  }

  Future<UserCredential?> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await _createDefaultListsIfMissing(userCredential.user!.uid);
      }

      return userCredential;
    } catch (e) {
      print('Giris Hatasi : $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> _createDefaultListsIfMissing(String uid) async {
    CollectionReference listRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('lists');
    QuerySnapshot existingLists = await listRef.get();

    Set<String> existingTypes = existingLists.docs
        .map(
          (doc) =>
              (doc.data() as Map<String, dynamic>)['type']?.toString() ?? '',
        )
        .toSet();

    WriteBatch batch = _firestore.batch();
    bool hasMissing = false;

    for (var list in _defaultList) {
      if (!existingTypes.contains(list['type'])) {
        hasMissing = true;
        DocumentReference newDoc = listRef.doc();
        batch.set(newDoc, {...list, 'createdAt': FieldValue.serverTimestamp()});
      }
    }

    if (hasMissing) {
      await batch.commit();
    }
  }
}
