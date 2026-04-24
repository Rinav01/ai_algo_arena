import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/pathfinding_visualizer_screen.dart';
import 'screens/algorithm_battle_screen.dart';
import 'screens/eightpuzzle_visualizer_screen.dart';
import 'screens/nqueens_visualizer_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/replay_screen.dart';
import 'screens/history_screen.dart';
import 'services/stats_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  final prefs = await SharedPreferences.getInstance();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const AlgoArenaApp(),
    ),
  );
}

class AlgoArenaApp extends StatelessWidget {
  const AlgoArenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Merge Google Fonts (Space Grotesk + Manrope) into our ThemeData
    final base = AppTheme.themeData();
    final theme = base.copyWith(
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 34.0,
          fontWeight: FontWeight.w800,
          color: AppTheme.onBackground,
          letterSpacing: -0.6,
        ),
        displayMedium: GoogleFonts.spaceGrotesk(
          fontSize: 28.0,
          fontWeight: FontWeight.w700,
          color: AppTheme.onBackground,
          letterSpacing: -0.4,
        ),
        headlineLarge: GoogleFonts.spaceGrotesk(
          fontSize: 24.0,
          fontWeight: FontWeight.w700,
          color: AppTheme.onBackground,
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          fontSize: 20.0,
          fontWeight: FontWeight.w600,
          color: AppTheme.onBackground,
        ),
        headlineSmall: GoogleFonts.spaceGrotesk(
          fontSize: 17.0,
          fontWeight: FontWeight.w600,
          color: AppTheme.onBackground,
        ),
        labelLarge: GoogleFonts.spaceGrotesk(
          fontSize: 12.0,
          fontWeight: FontWeight.w700,
          color: AppTheme.onBackground,
          letterSpacing: 1.0,
        ),
        labelMedium: GoogleFonts.spaceGrotesk(
          fontSize: 11.0,
          fontWeight: FontWeight.w600,
          color: AppTheme.accentLight,
          letterSpacing: 1.0,
        ),
        labelSmall: GoogleFonts.spaceGrotesk(
          fontSize: 10.0,
          fontWeight: FontWeight.w600,
          color: AppTheme.textMuted,
          letterSpacing: 1.2,
        ),
      ),
    );

    return MaterialApp(
      title: 'Algo Arena',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: const SplashScreen(),
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/home': (_) => const HomeScreen(),
        '/battle': (_) => const AlgorithmBattleScreen(),
        '/eightpuzzle': (_) => const EightPuzzleVisualizerScreen(),
        '/nqueens': (_) => const NQueensVisualizerScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/replay': (_) => const ReplayScreen(),
        '/history': (_) => const HistoryScreen(),
      },
      // Named routes that need parameters use onGenerateRoute
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/bfs':
            return MaterialPageRoute(
              builder: (_) => const PathfindingVisualizerScreen(
                algorithmId: 'BFS',
                title: 'BFS Visualizer',
              ),
            );
          case '/dfs':
            return MaterialPageRoute(
              builder: (_) => const PathfindingVisualizerScreen(
                algorithmId: 'DFS',
                title: 'DFS Visualizer',
              ),
            );
          case '/dijkstra':
            return MaterialPageRoute(
              builder: (_) => const PathfindingVisualizerScreen(
                algorithmId: "Dijkstra",
                title: "Dijkstra's Visualizer",
              ),
            );
          case '/greedy':
            return MaterialPageRoute(
              builder: (_) => const PathfindingVisualizerScreen(
                algorithmId: 'Greedy',
                title: 'Greedy BFS Visualizer',
              ),
            );
          case '/astar':
            return MaterialPageRoute(
              builder: (_) => const PathfindingVisualizerScreen(
                algorithmId: 'A*',
                title: 'A* Visualizer',
              ),
            );
          default:
            return MaterialPageRoute(builder: (_) => const HomeScreen());
        }
      },
      // Ensure scaling doesn't blow up font sizes on weird devices
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.of(
              context,
            ).textScaler.clamp(minScaleFactor: 0.8, maxScaleFactor: 1.25),
          ),
          child: child!,
        );
      },
    );
  }
}
