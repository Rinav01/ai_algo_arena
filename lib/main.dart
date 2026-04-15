import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/pathfinding_visualizer_screen.dart';
import 'screens/astar_visualizer_screen.dart';
import 'screens/algorithm_battle_screen.dart';
import 'screens/eightpuzzle_visualizer_screen.dart';
import 'screens/nqueens_visualizer_screen.dart';
import 'screens/maze_editor_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const ProviderScope(child: AiAlgoApp()));
}

class AiAlgoApp extends StatelessWidget {
  const AiAlgoApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Merge Google Fonts (Space Grotesk + Manrope) into our ThemeData
    final base = AppTheme.themeData();
    final theme = base.copyWith(
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 34, fontWeight: FontWeight.w800,
          color: AppTheme.onBackground, letterSpacing: -0.6,
        ),
        displayMedium: GoogleFonts.spaceGrotesk(
          fontSize: 28, fontWeight: FontWeight.w700,
          color: AppTheme.onBackground, letterSpacing: -0.4,
        ),
        headlineLarge: GoogleFonts.spaceGrotesk(
          fontSize: 24, fontWeight: FontWeight.w700,
          color: AppTheme.onBackground,
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          fontSize: 20, fontWeight: FontWeight.w600,
          color: AppTheme.onBackground,
        ),
        headlineSmall: GoogleFonts.spaceGrotesk(
          fontSize: 17, fontWeight: FontWeight.w600,
          color: AppTheme.onBackground,
        ),
        labelLarge: GoogleFonts.spaceGrotesk(
          fontSize: 12, fontWeight: FontWeight.w700,
          color: AppTheme.onBackground, letterSpacing: 1.0,
        ),
        labelMedium: GoogleFonts.spaceGrotesk(
          fontSize: 11, fontWeight: FontWeight.w600,
          color: AppTheme.accentLight, letterSpacing: 1.0,
        ),
        labelSmall: GoogleFonts.spaceGrotesk(
          fontSize: 10, fontWeight: FontWeight.w600,
          color: AppTheme.textMuted, letterSpacing: 1.2,
        ),
      ),
    );

    return MaterialApp(
      title: 'AI Algorithm Arena',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: const HomeScreen(),
      routes: {
        '/home':      (_) => const HomeScreen(),
        '/astar':     (_) => const AStarVisualizerScreen(),
        '/battle':    (_) => const AlgorithmBattleScreen(),
        '/eightpuzzle':(_) => const EightPuzzleVisualizerScreen(),
        '/nqueens':   (_) => const NQueensVisualizerScreen(),
        '/maze':      (_) => const MazeEditorScreen(),
      },
      // Named routes that need parameters use onGenerateRoute
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/bfs':
            return MaterialPageRoute(
              builder: (_) => const PathfindingVisualizerScreen(
                  algorithmId: 'BFS', title: 'BFS Visualizer'));
          case '/dfs':
            return MaterialPageRoute(
              builder: (_) => const PathfindingVisualizerScreen(
                  algorithmId: 'DFS', title: 'DFS Visualizer'));
          case '/dijkstra':
            return MaterialPageRoute(
              builder: (_) => const PathfindingVisualizerScreen(
                  algorithmId: 'Dijkstra', title: "Dijkstra's Visualizer"));
          default:
            return MaterialPageRoute(builder: (_) => const HomeScreen());
        }
      },
    );
  }
}
