import 'package:cinemora/app/router.dart';
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
            child: Column(
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
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
                SizedBox(height: 20),
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
                _listsCard(),
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
                _listsCard(),
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
                _listsCard(),
                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _listsCard() {
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        Container(
          alignment: Alignment.centerLeft,
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _miniCard(),
                  SizedBox(width: 10),
                  _miniCard(),
                  SizedBox(width: 10),
                  _miniCard(),
                  SizedBox(width: 10),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.arrow_forward_ios_rounded, size: 30),
        ),
      ],
    );
  }

  Container _miniCard() {
    return Container(
      height: 80,
      width: 80,
      decoration: BoxDecoration(
        color: Colors.amber,
        borderRadius: BorderRadius.circular(12),
      ),
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
}
