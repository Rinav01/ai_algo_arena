import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/app_theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'screens/home_screen.dart';
import 'screens/pathfinding_visualizer_screen.dart';
import 'screens/algorithm_battle_screen.dart';
import 'screens/eightpuzzle_visualizer_screen.dart';
import 'screens/nqueens_visualizer_screen.dart';
import 'screens/maze_editor_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ScreenUtil.ensureScreenSize();
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
    return ScreenUtilInit(
      designSize: const Size(430, 932), // iPhone 14 Pro Max sizing baseline
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        // Merge Google Fonts (Space Grotesk + Manrope) into our ThemeData
        final base = AppTheme.themeData();
        final theme = base.copyWith(
          textTheme: GoogleFonts.manropeTextTheme(base.textTheme).copyWith(
            displayLarge: GoogleFonts.spaceGrotesk(
              fontSize: 34.sp, fontWeight: FontWeight.w800,
              color: AppTheme.onBackground, letterSpacing: -0.6,
            ),
            displayMedium: GoogleFonts.spaceGrotesk(
              fontSize: 28.sp, fontWeight: FontWeight.w700,
              color: AppTheme.onBackground, letterSpacing: -0.4,
            ),
            headlineLarge: GoogleFonts.spaceGrotesk(
              fontSize: 24.sp, fontWeight: FontWeight.w700,
              color: AppTheme.onBackground,
            ),
            headlineMedium: GoogleFonts.spaceGrotesk(
              fontSize: 20.sp, fontWeight: FontWeight.w600,
              color: AppTheme.onBackground,
            ),
            headlineSmall: GoogleFonts.spaceGrotesk(
              fontSize: 17.sp, fontWeight: FontWeight.w600,
              color: AppTheme.onBackground,
            ),
            labelLarge: GoogleFonts.spaceGrotesk(
              fontSize: 12.sp, fontWeight: FontWeight.w700,
              color: AppTheme.onBackground, letterSpacing: 1.0,
            ),
            labelMedium: GoogleFonts.spaceGrotesk(
              fontSize: 11.sp, fontWeight: FontWeight.w600,
              color: AppTheme.accentLight, letterSpacing: 1.0,
            ),
            labelSmall: GoogleFonts.spaceGrotesk(
              fontSize: 10.sp, fontWeight: FontWeight.w600,
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
                      algorithmId: "Dijkstra", title: "Dijkstra's Visualizer"));
              case '/greedy':
                return MaterialPageRoute(
                  builder: (_) => const PathfindingVisualizerScreen(
                      algorithmId: 'Greedy', title: 'Greedy BFS Visualizer'));
              case '/astar':
                return MaterialPageRoute(
                  builder: (_) => const PathfindingVisualizerScreen(
                      algorithmId: 'A*', title: 'A* Visualizer'));
              default:
                return MaterialPageRoute(builder: (_) => const HomeScreen());
            }
          },
        );
      },
    );
  }
}
