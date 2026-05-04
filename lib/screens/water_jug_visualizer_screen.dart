import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:algo_arena/core/app_theme.dart';
import 'package:algo_arena/core/water_jug_problem.dart';
import 'package:algo_arena/core/problem_definition.dart';
import 'package:algo_arena/screens/visualizer_base_mixin.dart';
import 'package:algo_arena/widgets/visualizer_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:algo_arena/widgets/water_jug_phase_space.dart';
import 'package:algo_arena/models/algo_info.dart';
import 'dart:math' as math;
import 'package:algo_arena/widgets/feature_tour.dart';


class WaterJugVisualizerScreen extends ConsumerStatefulWidget {
  const WaterJugVisualizerScreen({super.key});

  @override
  ConsumerState<WaterJugVisualizerScreen> createState() =>
      _WaterJugVisualizerScreenState();
}

class _WaterJugVisualizerScreenState extends ConsumerState<WaterJugVisualizerScreen>
    with TickerProviderStateMixin, VisualizerBaseMixin<WaterJugVisualizerScreen, WaterJugState> {
  
  final GlobalKey _settingsKey = GlobalKey();
  final GlobalKey _visualizerKey = GlobalKey();
  final GlobalKey _phaseSpaceKey = GlobalKey();
  final GlobalKey _manualKey = GlobalKey();
  final GlobalKey _controlsKey = GlobalKey();

  // Jug Configurations
  int capacityA = 4;
  int capacityB = 3;
  int target = 2;

  // Current Algorithm
  String _currentAlgo = 'BFS';

  // Current Animation State
  int currentJugA = 0;
  int currentJugB = 0;
  String currentOp = 'Initial State';
  
  // HUD Telemetry
  int nodesExpanded = 0;
  int frontierSize = 0;
  List<WaterJugState> historyPath = [];
  Set<WaterJugState> exploredStates = {};

  // Widget caching: static sections only rebuild when config changes
  Widget? _cachedSettingsCard;
  Widget? _cachedManualControls;
  Widget? _cachedAlgoSelector;
  Widget? _cachedControlPanel;
  int _lastConfigHash = 0;

  /// Hash of all config state that static widgets depend on
  int get _configHash => Object.hash(
    capacityA, capacityB, target, _currentAlgo,
    isSolving, isSolved, stepCount, executionSpeed,
  );

  // Animation controllers for sloshing
  late AnimationController _sloshController;

  // Deferred loading: prevent ANR by not building heavy widgets on first frame
  bool _isContentReady = false;

  @override
  void initState() {
    super.initState();
    executionSpeed = 0.3; // Default to slower speed for better visualization
    _sloshController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    // Don't start repeating immediately - only during solve to save frames

    // Defer heavy content build to avoid ANR during navigation transition.
    // Use a 300ms delay to let the route transition animation finish first.
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _isContentReady = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          FeatureTour.startTour(
            context: context,
            tourKey: 'water_jug',
            steps: [
              TourStep(
                targetKey: _settingsKey,
                title: 'Problem Configuration',
                description: 'Adjust the capacities of Jug A, Jug B, and the target amount to solve.',
              ),
              TourStep(
                targetKey: _visualizerKey,
                title: 'Jugs Visualization',
                description: 'See dynamic sloshing and pouring animations as the AI progresses through each step.',
              ),
              TourStep(
                targetKey: _phaseSpaceKey,
                title: 'Phase Space Analysis',
                description: 'Explore state transitions in the visual phase space map.',
              ),
              TourStep(
                targetKey: _manualKey,
                title: 'Manual Controls',
                description: 'Perform individual pour, fill, and empty steps yourself.',
              ),
              TourStep(
                targetKey: _controlsKey,
                title: 'Execution Controls',
                description: 'Run the AI solver, pause, or clear to reset the state.',
              ),
            ],
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _sloshController.dispose();
    super.dispose();
  }

  @override
  String get algorithmId => _currentAlgo;

  @override
  Map<String, dynamic> getProblemSnapshot() {
    return {
      'type': 'water_jug',
      'capacityA': capacityA,
      'capacityB': capacityB,
      'target': target,
    };
  }

  @override
  Future<void> onGoalReached(AlgorithmStep<WaterJugState> step) async {
    _sloshController.stop();
    setState(() {
      statusMessage = 'Goal Reached: Found $target Liters!';
    });
  }

  @override
  Future<void> onStep(AlgorithmStep<WaterJugState> step) async {
    final state = step.currentState;
    if (state == null) return;
    
    // Update local variables WITHOUT calling setState here.
    // The mixin's _handleStep will call setState() at 30fps to throttle updates.
    currentJugA = state.jugA;
    currentJugB = state.jugB;
    currentOp = state.operation;
    
    nodesExpanded = step.stepCount;
    frontierSize = step.frontierSize ?? 0;
    historyPath = step.path;
    
    if (executor != null) {
      exploredStates = executor!.exploredSet.cast<WaterJugState>();
    }
  }

  @override
  Future<void> onAutoSave() async {
    // Optional: save to history
  }

  void _reset() {
    resetBase();
    _sloshController.stop();
    setState(() {
      currentJugA = 0;
      currentJugB = 0;
      currentOp = 'Initial State';
      historyPath = [WaterJugState(0, 0, 'Initial State')];
      exploredStates = {WaterJugState(0, 0, 'Initial State')};
      nodesExpanded = 0;
      frontierSize = 0;
    });
  }

  void _randomizeProblem() {
    final rand = math.Random();
    setState(() {
      capacityA = 3 + rand.nextInt(10); // 3-12
      capacityB = 3 + rand.nextInt(10); // 3-12
      // Avoid capacityA == capacityB for better problems
      if (capacityA == capacityB) capacityB++;
      
      // Target must be achievable (multiples of GCD) or just random <= max
      target = 1 + rand.nextInt(math.max(capacityA, capacityB));
      _reset();
    });
  }

  void _performManualAction(String type) {
    if (isSolving) return;
    
    setState(() {
      int newA = currentJugA;
      int newB = currentJugB;
      String op = '';

      switch (type) {
        case 'fillA':
          newA = capacityA;
          op = 'Fill Jug A';
          break;
        case 'fillB':
          newB = capacityB;
          op = 'Fill Jug B';
          break;
        case 'emptyA':
          newA = 0;
          op = 'Empty Jug A';
          break;
        case 'emptyB':
          newB = 0;
          op = 'Empty Jug B';
          break;
        case 'pourAtoB':
          int amount = math.min(currentJugA, capacityB - currentJugB);
          newA -= amount;
          newB += amount;
          op = 'Pour A → B';
          break;
        case 'pourBtoA':
          int amount = math.min(currentJugB, capacityA - currentJugA);
          newB -= amount;
          newA += amount;
          op = 'Pour B → A';
          break;
      }

      currentJugA = newA;
      currentJugB = newB;
      currentOp = op;
      
      final newState = WaterJugState(newA, newB, op);
      
      // Update history and explored set for manual solving
      if (historyPath.isEmpty || historyPath.last != newState) {
        historyPath = List.from(historyPath)..add(newState);
        exploredStates = Set.from(exploredStates)..add(newState);
        nodesExpanded++;
      }

      if (newA == target || newB == target || (newA + newB) == target) {
        isSolved = true;
        statusMessage = 'Goal Reached Manually!';
      }
    });
  }

  Widget _buildManualControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCard(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.touch_app_rounded, color: AppTheme.accent, size: 20),
              const SizedBox(width: 10),
              Text(
                'MANUAL INTERACTION',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.accentLight,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              if (isSolved)
                const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 18),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final buttonWidth = (constraints.maxWidth - 20) / 3;
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildManualBtn('FILL A', 'fillA', AppTheme.cyan, Icons.add_circle_outline, buttonWidth),
                      _buildManualBtn('POUR A→B', 'pourAtoB', Colors.white, Icons.swap_horiz_rounded, buttonWidth),
                      _buildManualBtn('EMPTY A', 'emptyA', AppTheme.cyan, Icons.remove_circle_outline, buttonWidth),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildManualBtn('FILL B', 'fillB', AppTheme.accent, Icons.add_circle_outline, buttonWidth),
                      _buildManualBtn('POUR B→A', 'pourBtoA', Colors.white, Icons.swap_horiz_rounded, buttonWidth),
                      _buildManualBtn('EMPTY B', 'emptyB', AppTheme.accent, Icons.remove_circle_outline, buttonWidth),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildManualBtn(String label, String action, Color color, IconData icon, double width) {
    bool isEnabled = !isSolving;
    return SizedBox(
      width: width,
      child: Material(
        color: isEnabled ? AppTheme.surfaceHighest.withValues(alpha: 0.3) : Colors.black12,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isEnabled ? () => _performManualAction(action) : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Icon(icon, color: isEnabled ? color : AppTheme.textMuted, size: 18),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isEnabled ? Colors.white : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.background,
                    AppTheme.surfaceHigh,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                VisualizerHeader(
                  title: 'Water Jug Problem',
                  subtitle: 'STATE-SPACE VIZ',
                  onBackTap: () => Navigator.pop(context),
                  comparisonInfos: AlgoInfo.waterJug,
                  initialKey: _currentAlgo,
                ),
                Expanded(
                  child: _isContentReady
                      ? _buildFullContent()
                      : _buildLoadingSkeleton(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Lightweight placeholder shown during the first frame to prevent ANR.
  Widget _buildLoadingSkeleton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.accent.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading visualizer...',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// Full content built after the defer period.
  /// Uses ListView for viewport culling — off-screen sections don't build.
  Widget _buildFullContent() {
    // Rebuild cached widgets only when their dependencies change
    final currentConfigHash = _configHash;
    if (currentConfigHash != _lastConfigHash) {
      _lastConfigHash = currentConfigHash;
      _cachedAlgoSelector = _buildAlgoSelector();
      _cachedSettingsCard = _buildSettingsCard();
      _cachedManualControls = RepaintBoundary(child: _buildManualControls());
      _cachedControlPanel = RepaintBoundary(child: _buildControlPanel());
    }

    // ListView provides viewport culling: only visible items are built/painted.
    // This prevents all sections from being laid out + painted on every frame
    // during scroll, which was the root cause of ANR on high-res debug builds.
    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.05,
        vertical: 20,
      ),
      children: [
        _cachedAlgoSelector!,
        const SizedBox(height: 20),
        KeyedSubtree(key: _settingsKey, child: _cachedSettingsCard!),
        const SizedBox(height: 30),
        KeyedSubtree(key: _visualizerKey, child: _buildVisualizerArea()),
        const SizedBox(height: 20),
        KeyedSubtree(key: _phaseSpaceKey, child: _buildPhaseSpaceAndStats()),
        const SizedBox(height: 20),
        KeyedSubtree(key: _manualKey, child: _cachedManualControls!),
        const SizedBox(height: 20),
        KeyedSubtree(key: _controlsKey, child: _cachedControlPanel!),
        const SizedBox(height: 20),
        StatusBanner(
          message: statusMessage,
          isSolving: isSolving,
          isSolved: isSolved,
        ),
      ],
    );
  }


  Widget _buildAlgoSelector() {
    return Row(
      children: [
        Text(
          'SELECT ALGORITHM:',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.textMuted,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: AppTheme.glassCard(radius: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _currentAlgo,
                isExpanded: true,
                dropdownColor: AppTheme.surfaceHighest,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.accent,
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                items: ['BFS', 'A*'].map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged:
                    isSolving
                        ? null
                        : (val) {
                          if (val != null) {
                            setState(() {
                              _currentAlgo = val;
                            });
                          }
                        },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCard(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: AppTheme.accent, size: 20),
              const SizedBox(width: 10),
              Text(
                'PROBLEM CONFIGURATION',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.accentLight,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: isSolving ? null : _randomizeProblem,
                icon: const Icon(Icons.casino_rounded, color: AppTheme.warning, size: 20),
                tooltip: 'Randomize Parameters',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildValueStepper(
                  'Jug A Max',
                  capacityA,
                  (v) => setState(() => capacityA = v),
                  Icons.opacity_rounded,
                  AppTheme.cyan,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildValueStepper(
                  'Jug B Max',
                  capacityB,
                  (v) => setState(() => capacityB = v),
                  Icons.opacity_rounded,
                  AppTheme.accent,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildValueStepper(
                  'Target',
                  target,
                  (v) => setState(() => target = v),
                  Icons.track_changes_rounded,
                  AppTheme.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValueStepper(String label, int value, Function(int) onChanged, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.surfaceHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.remove_rounded, size: 16),
                onPressed: value > 1 ? () => onChanged(value - 1) : null,
              ),
              Text(
                '$value',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.add_rounded, size: 16),
                onPressed: value < 15 ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVisualizerArea() {
    // Determine if we are pouring
    final isPouringAtoB = currentOp.contains('Pour A ➔ B') || currentOp.contains('A to B');
    final isPouringBtoA = currentOp.contains('Pour B ➔ A') || currentOp.contains('B to A');

    return Container(
      height: 340,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. HUD Overlay (Algorithm Telemetry)
          Positioned(
            top: 15,
            left: 15,
            child: _buildTelemetryHUD(),
          ),

          // 2. Target Line Overlay
          Positioned(
            left: 0,
            right: 0,
            top: 60,
            child: Column(
              children: [
                Text(
                  'TARGET: $target L',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.warning.withValues(alpha: 0.8),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 1,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.warning.withValues(alpha: 0),
                        AppTheme.warning.withValues(alpha: 0.3),
                        AppTheme.warning.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Jugs Area
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildJug(
                  'JUG A',
                  currentJugA,
                  capacityA,
                  AppTheme.cyan,
                  isPouringAtoB ? 15.0 : 0.0,
                ),
                _buildJug(
                  'JUG B',
                  currentJugB,
                  capacityB,
                  AppTheme.accent,
                  isPouringBtoA ? -15.0 : 0.0,
                ),
              ],
            ),
          ),
          
          // 4. Pouring Stream Effect
          if (isPouringAtoB || isPouringBtoA)
            Positioned(
              top: 120,
              left: 0,
              right: 0,
              child: _buildPourStream(isPouringAtoB),
            ),

          // 5. Current Operation Label
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: _buildOperationBadge(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryHUD() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHUDItem('EXPANDED', '$nodesExpanded', AppTheme.accent),
          const SizedBox(height: 4),
          _buildHUDItem('FRONTIER', '$frontierSize', AppTheme.cyan),
        ],
      ),
    );
  }

  Widget _buildHUDItem(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 4, height: 4, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 9, color: AppTheme.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
        ),
      ],
    );
  }

  Widget _buildOperationBadge() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: historyPath.isEmpty ? null : _showStepsHistory,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceHighest.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bolt_rounded, color: AppTheme.warning, size: 14),
              const SizedBox(width: 8),
              Text(
                currentOp.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (historyPath.isNotEmpty) ...[
                const SizedBox(width: 8),
                const Icon(Icons.history_rounded, color: AppTheme.textMuted, size: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showStepsHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.history_edu_rounded, color: AppTheme.accent),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SOLUTION STEPS',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '${historyPath.length} steps to reach goal',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            // Steps List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: historyPath.length,
                itemBuilder: (context, index) {
                  final state = historyPath[index];
                  final isLast = index == historyPath.length - 1;
                  
                  return IntrinsicHeight(
                    child: Row(
                      children: [
                        // Timeline line
                        Column(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: isLast ? AppTheme.warning : AppTheme.accent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (isLast ? AppTheme.warning : AppTheme.accent).withValues(alpha: 0.3),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            if (!isLast)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color: Colors.white.withValues(alpha: 0.05),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        // Content
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceHighest.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isLast ? AppTheme.warning.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'STEP ${index + 1}',
                                        style: TextStyle(
                                          color: isLast ? AppTheme.warning : AppTheme.accentLight,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        state.operation,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  _buildSmallJug(state.jugA, capacityA, AppTheme.cyan),
                                  const SizedBox(width: 8),
                                  _buildSmallJug(state.jugB, capacityB, AppTheme.accent),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallJug(int current, int max, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: 20,
              height: 30,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Container(
              width: 20,
              height: (current / max) * 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text('$current L', style: const TextStyle(fontSize: 8, color: AppTheme.textMuted)),
      ],
    );
  }

  Widget _buildPourStream(bool aToB) {
    return Center(
      child: Container(
        width: 100,
        height: 4,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: aToB 
              ? [AppTheme.cyan, AppTheme.accent]
              : [AppTheme.accent, AppTheme.cyan],
          ),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildPhaseSpaceAndStats() {
    final bool isNarrow = MediaQuery.of(context).size.width < 400;
    
    return Container(
      height: isNarrow ? 260 : 180,
      decoration: AppTheme.glassCard(radius: 24),
      child: isNarrow 
          ? Column(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _showExpandedPhaseSpace,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.hub_rounded, color: AppTheme.accent, size: 14),
                              const SizedBox(width: 8),
                              Text(
                                'PHASE SPACE MAP',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppTheme.textMuted,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.fullscreen_rounded, color: AppTheme.textMuted, size: 14),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: CustomPaint(
                                painter: PhaseSpacePainter(
                                  capacityA: capacityA,
                                  capacityB: capacityB,
                                  exploredStates: exploredStates,
                                  currentPath: historyPath,
                                  currentState: historyPath.isNotEmpty ? historyPath.last : null,
                                  target: target,
                                ),
                                size: Size.infinite,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildLegendItem('Path', AppTheme.accent),
                      _buildLegendItem('Explored', Colors.white.withValues(alpha: 0.2)),
                      _buildLegendItem('Target', AppTheme.warning.withValues(alpha: 0.3)),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              children: [
                // 1. Phase Space Map
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: _showExpandedPhaseSpace,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.hub_rounded, color: AppTheme.accent, size: 14),
                              const SizedBox(width: 8),
                              Text(
                                'PHASE SPACE MAP',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppTheme.textMuted,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.fullscreen_rounded, color: AppTheme.textMuted, size: 14),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: CustomPaint(
                                painter: PhaseSpacePainter(
                                  capacityA: capacityA,
                                  capacityB: capacityB,
                                  exploredStates: exploredStates,
                                  currentPath: historyPath,
                                  currentState: historyPath.isNotEmpty ? historyPath.last : null,
                                  target: target,
                                ),
                                size: Size.infinite,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // 2. Legend / Side Info
                Container(width: 1, color: Colors.white.withValues(alpha: 0.05)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendItem('Path', AppTheme.accent),
                        const SizedBox(height: 8),
                        _buildLegendItem('Explored', Colors.white.withValues(alpha: 0.2)),
                        const SizedBox(height: 8),
                        _buildLegendItem('Target', AppTheme.warning.withValues(alpha: 0.3)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
      ],
    );
  }

  Widget _buildJug(String name, int current, int max, Color color, double tiltAngle) {
    double fillPercentage = current / max;
    
    return AnimatedRotation(
      duration: 400.ms,
      turns: tiltAngle / 360,
      curve: Curves.easeInOutBack,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // 1. Jug Frame (Glass effect)
              Container(
                width: 90,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 2),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
              ),
              
              // 2. Water Fill - uses a simple AnimatedContainer (no per-frame sloshing)
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOutSine,
                width: 86,
                height: 156 * fillPercentage,
                margin: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color.withValues(alpha: 0.6),
                      color.withValues(alpha: 0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: const Radius.circular(22),
                    bottomRight: const Radius.circular(22),
                    topLeft: Radius.circular(fillPercentage > 0.9 ? 22 : 4),
                    topRight: Radius.circular(fillPercentage > 0.9 ? 22 : 4),
                  ),
                ),
                child: CustomPaint(
                  painter: _JugGlossPainter(),
                ),
              ),

              // 3. Capacity Markers (Optimized CustomPaint)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: CustomPaint(
                    painter: _CapacityMarkersPainter(max: max),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12),
          ),
          Text(
            '$current / $max L',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: AppTheme.glassCard(radius: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              // Primary Controls
              Expanded(
                flex: 3,
                child: VisualizerControls(
                  onSolve: () {
                    _sloshController.repeat();
                    solve();
                  },
                  onPauseResume: pauseResume,
                  onClear: _reset,
                  isSolving: isSolving,
                  isSolved: isSolved,
                  stepCount: stepCount,
                ),
              ),
              const SizedBox(width: 24),
              // Speed/Settings Section
              SizedBox(
                width: 120,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.speed_rounded, size: 14, color: AppTheme.textMuted),
                        Text(
                          '${executionSpeed.toStringAsFixed(1)}x',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                        activeTrackColor: AppTheme.accent,
                        inactiveTrackColor: AppTheme.accent.withValues(alpha: 0.1),
                        thumbColor: Colors.white,
                      ),
                      child: Slider(
                        value: executionSpeed,
                        min: 0.3,
                        max: 5.0,
                        onChanged: (val) => setState(() => executionSpeed = val),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  void _showExpandedPhaseSpace() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Phase Space',
      barrierColor: Colors.black.withValues(alpha: 0.9),
      transitionDuration: 300.ms,
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PHASE SPACE ANALYSIS',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          'State Transitions: $capacityA L × $capacityB L',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: CustomPaint(
                      painter: PhaseSpacePainter(
                        capacityA: capacityA,
                        capacityB: capacityB,
                        exploredStates: exploredStates,
                        currentPath: historyPath,
                        currentState: historyPath.isNotEmpty ? historyPath.last : null,
                        target: target,
                        isExpanded: true,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildLegendItem('Explored Path', AppTheme.accent),
                    _buildLegendItem('Discovery Set', Colors.white.withValues(alpha: 0.15)),
                    _buildLegendItem('Goal Threshold', AppTheme.warning.withValues(alpha: 0.2)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Subtle gloss overlay for the jugs to give a glass feel
class _JugGlossPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    if (size.height < 5) return;
    
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.15),
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.05),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(4, 4, size.width * 0.2, size.height - 8), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CapacityMarkersPainter extends CustomPainter {
  final int max;
  _CapacityMarkersPainter({required this.max});

  @override
  void paint(Canvas canvas, Size size) {
    if (max <= 0) return;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1;
    
    final double spacing = size.height / (max + 1);
    for (int i = 1; i <= max; i++) {
      final y = size.height - (i * spacing);
      canvas.drawLine(Offset((size.width - 12) / 2, y), Offset((size.width + 12) / 2, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CapacityMarkersPainter oldDelegate) => oldDelegate.max != max;
}
