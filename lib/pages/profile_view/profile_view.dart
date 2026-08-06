import 'package:cinemora/auth/login.dart';
import 'package:cinemora/auth/signup.dart';
import 'package:flutter/material.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  @override
  Widget build(BuildContext context) {
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
            Text(
              'User Name',
              style: TextStyle(
                color: Theme.of(context).colorScheme.tertiary,
                fontSize: 20,
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                  child: Text('Login Test'),
                ),
                SizedBox(width: 20),

                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => SignupPage()),
                    );
                  },
                  child: Text('SignUp Test'),
                ),
              ],
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
}
