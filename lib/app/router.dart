import 'package:cinemora/auth/login.dart';
import 'package:cinemora/auth/signup.dart';
import 'package:cinemora/pages/info_view/movieinfo_view.dart';
import 'package:cinemora/pages/info_view/tvseriesinfo_view.dart';
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
  static const String login = "/login";
  static const String signup = "/signup";
  static const String tvInfo = "/tv-info/:id";
  static const String movieInfo = "/movie-info/:id";
}

final router = GoRouter(
  initialLocation: AppRoutes.search,
  navigatorKey: _rooterKey,
  routes: [
    GoRoute(
      parentNavigatorKey: _rooterKey,
      path: AppRoutes.login,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      parentNavigatorKey: _rooterKey,
      path: AppRoutes.signup,
      builder: (context, state) => const SignupPage(),
    ),
    GoRoute(
      parentNavigatorKey: _rooterKey,
      path: AppRoutes.tvInfo,
      builder: (context, state) {
        final tvId = int.parse(state.pathParameters['id']!);
        return TvSeriesInfo(tvId: tvId);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rooterKey,
      path: AppRoutes.movieInfo,
      builder: (context, state) {
        final movieId = int.parse(state.pathParameters['id']!);
        return MovieInfo(movieId: movieId);
      },
    ),
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
