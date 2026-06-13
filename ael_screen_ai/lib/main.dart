import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/history_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/subscription_screen.dart';
import 'services/overlay_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Listen for Android overlay bubble tap events
  OverlayService.onBubbleTap((event) {
    // When floating bubble is tapped from any app,
    // the native side will re-open the app.
    // Navigation is handled by the native overlay service.
  });

  runApp(
    const ProviderScope(
      child: AelScreenAIApp(),
    ),
  );
}

class AelScreenAIApp extends StatelessWidget {
  const AelScreenAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AEL Screen AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
        Locale('ja', 'JP'),
        Locale('ko', 'KR'),
      ],
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/camera': (_) => const CameraScreen(),
        '/history': (_) => const HistoryScreen(),
        '/favorites': (_) => const FavoritesScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/subscription': (_) => const SubscriptionScreen(),
      },
    );
  }
}
