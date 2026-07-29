import 'package:cinemora/pages/main_page.dart';
import 'package:cinemora/pages/movie_view/movie_view.dart';
import 'package:cinemora/pages/news_view/news_view.dart';
import 'package:cinemora/pages/profile_view/profile_view.dart';
import 'package:cinemora/pages/search_view/search_view.dart';
import 'package:cinemora/pages/tvseries_view/tvseries_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final _rooterKey = GlobalKey<NavigatorState>();

class AppRoutes {
  AppRoutes._();
  static const String tvseries = "/tvseries";
  static const String movies = "/movies";
  static const String search = "/";
  static const String news = "/news";
  static const String profile = "/profile";
}

final router = GoRouter(
  initialLocation: AppRoutes.search,
  navigatorKey: _rooterKey,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainPage(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.tvseries,
              builder: (context, state) => const TvseriesView(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.movies,
              builder: (context, state) => const MovieView(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.search,
              builder: (context, state) => const SearchView(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.news,
              builder: (context, state) => const NewsView(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profile,
              builder: (context, state) => const ProfileView(),
            ),
          ],
        ),
      ],
    ),
  ],
);
