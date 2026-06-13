import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/camera_screen.dart';
import '../screens/translate_screen.dart';
import '../screens/history_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/subscription_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String camera = '/camera';
  static const String translate = '/translate';
  static const String history = '/history';
  static const String favorites = '/favorites';
  static const String settings = '/settings';
  static const String subscription = '/subscription';

  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    final args = routeSettings.arguments;

    switch (routeSettings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case camera:
        return MaterialPageRoute(builder: (_) => const CameraScreen());
      case translate:
        return MaterialPageRoute(builder: (_) => TranslateScreen(args: args));
      case history:
        return MaterialPageRoute(builder: (_) => const HistoryScreen());
      case favorites:
        return MaterialPageRoute(builder: (_) => const FavoritesScreen());
      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case subscription:
        return MaterialPageRoute(builder: (_) => const SubscriptionScreen());
      default:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
    }
  }
}
