# Algo Arena - Project Guide & Implementation Report

Welcome to the **Algo Arena** documentation. This document provides a high-level overview of the project, a detailed report of implemented features, and a file-by-file explanation of the codebase.

---

## Project Overview

**Algo Arena** is a premium Flutter-based visualization tool designed to help users understand complex search algorithms and AI problem-solving techniques. It features real-time visualizations, interactive board manipulations, and a "Battle Mode" for comparing algorithm efficiency.

The app prioritizes:
- **Visual Excellence**: Modern typography (Space Grotesk & Manrope), glassmorphism, and smooth animations.
- **Responsiveness**: Fully adaptive UI using `flutter_screenutil` and `responsive_builder`.
- **Educational Value**: Step-by-step evaluation of explored nodes and final paths.

---

## Implementation Report

### Search Algorithms
The following generic search algorithms are implemented and can be applied to any defined `Problem`:
- **Breadth-First Search (BFS)**: Guarantees the shortest path on unweighted graphs.
- **Depth-First Search (DFS)**: Navigates deep into branches; useful for exhaustive search.
- **Dijkstra's Algorithm**: Finds the shortest path in weighted environments using actual movement costs.
- **A* Search**: Optimized informed search using heuristics (Manhattan/Euclidean).
- **Greedy Best-First Search**: Highly efficient informed search that prioritizes nodes closest to the goal based solely on heuristics.

### Visualizers & Problems
- **Grid Pathfinding**: Interactive grid where users can place start/end points, draw walls, and paint **Weighted Terrain** (lowering/raising movement cost).
- **Algorithm Battle Mode**: Benchmarking arena that runs two algorithms in parallel on identical grid states, providing a synchronized comparison of efficiency and speed.
- **8-Puzzle**: State-space search visualization showing how tiles move to reach a goal.
- **Water Jug Visualizer**: Interactive state-space exploration with a live-updating coordinate-mapped graph representing volume transitions.
- **N-Queens**: Backtracking visualization for placing queens on dynamically sized boards without conflict.
- **High-Fidelity Animations**: A dual-phase animation system (Pulse/Shake for Solving, Shimmer/Breathe for Victory) built with `flutter_animate` that provides real-time visual feedback.
- **Maze Generator**: Recursive Division and Randomized Prim's algorithms for generating complex solvable mazes.
- **Path Analytics**: Real-time performance chart (using `fl_chart`) and a 5-Engine Rule-Based system that generates context-aware insights from run data.
- **Map Persistence**: Export custom grids to JSON strings and import them back to share or reuse map layouts.

---

## File-by-File Explanation

### Root Directory
- **[main.dart](file:///d:/Flutter%20Projects/Personal/ai_algo/lib/main.dart)**: Entry point. Configures standard UI styles, initializes `ScreenUtil`, and defines the global routing table.
- **[pubspec.yaml](file:///d:/Flutter%20Projects/Personal/ai_algo/pubspec.yaml)**: Project manifest containing dependencies (`fl_chart`, `riverpod`, `google_fonts`, etc.).

### core/ (Logic & Definitions)
- **[app_theme.dart](file:///d:/Flutter%20Projects/Personal/ai_algo/lib/core/app_theme.dart)**: Defines the design system (colors, gradients, glass styles, and terrain colors).
- **[grid_problem.dart](file:///d:/Flutter%20Projects/Personal/ai_algo/lib/core/grid_problem.dart)**: Defines `GridProblem` and `GridCoordinate`, mapping the 2D grid logic to the abstract `Problem` class.
- **[maze_generators.dart](file:///d:/Flutter%20Projects/Personal/ai_algo/lib/core/maze_generators.dart)**: Implements procedural maze generation logic.
- **[problem_definition.dart](file:///d:/Flutter%20Projects/Personal/ai_algo/lib/core/problem_definition.dart)**: The architectural foundation. Defines `Problem`, `SearchAlgorithm`, and `AlgorithmStep` abstractions.
- **[search_algorithms.dart](file:///d:/Flutter%20Projects/Personal/ai_algo/lib/core/search_algorithms.dart)**: Clean implementations of core search logic for all supported algorithms.

### models/ (Data Structures)
- **[grid_node.dart](file:///d:/Flutter%20Projects/Personal/ai_algo/lib/models/grid_node.dart)**: Represents a single cell in a grid (coordinate, type, movement weight).

### screens/ (UI Pages)
- **[algorithm_battle_screen.dart](file:///d:/Flutter%20Projects/Personal/ai_algo/lib/screens/algorithm_battle_screen.dart)**: The benchmarking arena where algorithms compete.
- **[analytics_screen.dart](file:///d:/Flutter%20Projects/Personal/ai_algo/lib/screens/analytics_screen.dart)**: The dashboard for insights, performance distributions, and versus comparisons.
- **[eightpuzzle_visualizer_screen.dart](file:///d:/Flutter%20Projects/Personal/ai_algo/lib/screens/eightpuzzle_visualizer_screen.dart)**: Optimized 8-puzzle solver with victory animations.
- **[history_screen.dart](file:///d:/Flutter%20Projects/Personal/ai_algo/lib/screens/history_screen.dart)**: Searchable log of all historical algorithm runs.
- **[maze_editor_screen.dart](file:///d:/Flutter%20Projects/Personal/ai_algo/lib/screens/maze_editor_screen.dart)**: The "Arena Architect" editor for designing maps and generating mazes.
- **[nqueens_visualizer_screen.dart](file:///d:/Flutter%20Projects/Personal/ai_algo/lib/screens/nqueens_visualizer_screen.dart)**: N-Queens backtracking visualizer.
- **[pathfinding_visualizer_screen.dart](file:///d:/Flutter%20Projects/Personal/ai_algo/lib/screens/pathfinding_visualizer_screen.dart)**: The main performance-optimized grid visualizer.
- **[replay_screen.dart](file:///d:/Flutter%20Projects/Personal/ai_algo/lib/screens/replay_screen.dart)**: Frame-by-frame historical execution playback.
- **[visualizer_base_mixin.dart](file:///d:/Flutter%20Projects/Personal/ai_algo/lib/screens/visualizer_base_mixin.dart)**: The core performance orchestrator. Manages vsync-throttled UI updates, state-driven animations, and deferred loading.
- **[water_jug_visualizer_screen.dart](file:///d:/Flutter%20Projects/Personal/ai_algo/lib/screens/water_jug_visualizer_screen.dart)**: Interactive physics-based jug solver.

### services/ (Business Logic)
- **[algorithm_executor.dart](file:///d:/Flutter%20Projects/Personal/ai_algo/lib/services/algorithm_executor.dart)**: Multi-isolate orchestrator that handles background computation.
- **[api_service.dart](file:///d:/Flutter%20Projects/Personal/ai_algo/lib/services/api_service.dart)**: Manages cloud synchronization of run data and insight retrieval.
- **[battle_analyzer.dart](file:///d:/Flutter%20Projects/Personal/ai_algo/lib/services/battle_analyzer.dart)**: Processes competition results to identify winning margins and efficiency gaps.
- **[map_persistence.dart](file:///d:/Flutter%20Projects/Personal/ai_algo/lib/services/map_persistence.dart)**: Handles JSON serialization for grid configurations.
- **[run_optimizer.dart](file:///d:/Flutter%20Projects/Personal/ai_algo/lib/services/run_optimizer.dart)**: Contains logic to minimize UI updates and batch data processing.

### widgets/ (UI Components)
- **[visualizer_widgets.dart](file:///d:/Flutter%20Projects/Personal/ai_algo/lib/widgets/visualizer_widgets.dart)**: A collection of high-quality components including:
    - `PerformanceChart`: Real-time line graphs of search metrics.
    - `StatusBanner`: Animated state-driven indicator (Pulse/Shimmer).
    - `VisualizerHeader`: Cinematic, performance-cached top bar.
    - `GlassStatCard`: Semi-transparent metric displays.
    - `ToolSelector`: Interactive mode/weight switching UI.

---

## Technical Stack

- **Framework**: [Flutter](https://flutter.dev/) (SDK ^3.10.4)
- **State Management**: [Riverpod](https://riverpod.dev/) (`flutter_riverpod`)
- **Graphics & Visualization**: 
    - `fl_chart`: For real-time performance analytics.
    - `CustomPainter`: For high-performance grid rendering.
    - `flutter_animate`: For high-fidelity, state-driven UI feedback.
- **Rendering Engines**: Optimized for both **Skia** and **Impeller** (with `RepaintBoundary` isolation).
- **Responsive Engine**: `flutter_screenutil` + `responsive_builder`
- **Typography**: Space Grotesk (Headers) & Manrope (Body)

---

## How to Run

1.  **Get Dependencies**:
    ```bash
    flutter pub get
    ```
2.  **Run on Device/Emulator**:
    ```bash
    flutter run
    ```
3.  **Run Tests**:
    ```bash
    flutter test
    ```
