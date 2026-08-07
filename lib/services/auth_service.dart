import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

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
      WriteBatch batch = _firestore.batch();
      CollectionReference listsRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('lists');

      List<Map<String, dynamic>> defaultLists = [
        {
          'name': 'TV Series',
          'type': 'tv',
          'isDefault': true,
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Movies',
          'type': 'movie',
          'isDefault': true,
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Favorites',
          'type': 'fav',
          'isDefault': true,
          'createdAt': FieldValue.serverTimestamp(),
        },
      ];

      for (var list in defaultLists) {
        DocumentReference newDoc = listsRef.doc();
        batch.set(newDoc, list);
      }
      await batch.commit();

      return userCredential;
    } catch (e) {
      print('Kayit hatasi : $e');
      rethrow;
    }
  }

  Future<UserCredential?> login({required email, required password}) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Giris Hatasi : $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
