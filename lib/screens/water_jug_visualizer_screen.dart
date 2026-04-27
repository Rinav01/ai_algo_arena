import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:algo_arena/core/app_theme.dart';
import 'package:algo_arena/core/water_jug_problem.dart';
import 'package:algo_arena/core/problem_definition.dart';
import 'package:algo_arena/screens/visualizer_base_mixin.dart';
import 'package:algo_arena/widgets/visualizer_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:algo_arena/widgets/water_jug_phase_space.dart';
import 'dart:math' as math;

class WaterJugVisualizerScreen extends ConsumerStatefulWidget {
  const WaterJugVisualizerScreen({super.key});

  @override
  ConsumerState<WaterJugVisualizerScreen> createState() =>
      _WaterJugVisualizerScreenState();
}

class _WaterJugVisualizerScreenState extends ConsumerState<WaterJugVisualizerScreen>
    with TickerProviderStateMixin, VisualizerBaseMixin<WaterJugVisualizerScreen, WaterJugState> {
  
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

  // Animation controllers for sloshing
  late AnimationController _sloshController;

  @override
  void initState() {
    super.initState();
    executionSpeed = 0.3; // Default to slower speed for better visualization
    _sloshController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
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
    setState(() {
      statusMessage = 'Goal Reached: Found $target Liters!';
    });
  }

  @override
  Future<void> onStep(AlgorithmStep<WaterJugState> step) async {
    final state = step.currentState;
    if (state == null) return;
    
    setState(() {
      currentJugA = state.jugA;
      currentJugB = state.jugB;
      currentOp = state.operation;
      
      // Update Telemetry
      nodesExpanded = step.stepCount;
      frontierSize = step.frontierSize ?? 0;
      historyPath = step.path;
      
      if (executor != null) {
        exploredStates = executor!.exploredSet.cast<WaterJugState>();
      }
    });
  }

  @override
  Future<void> onAutoSave() async {
    // Optional: save to history
  }

  void _reset() {
    resetBase();
    setState(() {
      currentJugA = 0;
      currentJugB = 0;
      currentOp = 'Initial State';
      historyPath = [];
      exploredStates = {};
      nodesExpanded = 0;
      frontierSize = 0;
    });
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
              decoration: BoxDecoration(
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
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildSettingsCard(),
                        const SizedBox(height: 30),
                        _buildVisualizerArea(),
                        const SizedBox(height: 20),
                        _buildPhaseSpaceAndStats(),
                        const SizedBox(height: 20),
                        _buildControlPanel(),
                        const SizedBox(height: 20),
                        StatusBanner(
                          message: statusMessage,
                          isSolving: isSolving,
                          isSolved: isSolved,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Water Jug Problem',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'State-Space Search Visualization',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textMuted,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const Spacer(),
          _buildAlgoSelector(),
        ],
      ),
    );
  }

  Widget _buildAlgoSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _currentAlgo,
          dropdownColor: AppTheme.surfaceHighest,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.accent),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          items: ['BFS', 'A*'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: isSolving ? null : (val) {
            if (val != null) {
              setState(() {
                _currentAlgo = val;
              });
            }
          },
        ),
      ),
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
                icon: const Icon(Icons.remove_rounded, size: 18),
                onPressed: value > 1 ? () => onChanged(value - 1) : null,
              ),
              Text(
                '$value',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.add_rounded, size: 18),
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
    final isPouringAtoB = currentOp.contains('A to B');
    final isPouringBtoA = currentOp.contains('B to A');

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
          ).animate().fadeIn(),

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
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0);
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
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
    ).animate(key: ValueKey(currentOp)).scale(duration: 200.ms, curve: Curves.easeOutBack).fadeIn();
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
          boxShadow: [
            BoxShadow(
              color: (aToB ? AppTheme.cyan : AppTheme.accent).withValues(alpha: 0.5),
              blurRadius: 8,
            ),
          ],
          borderRadius: BorderRadius.circular(2),
        ),
      ).animate().scaleX(begin: 0, end: 1, duration: 300.ms),
    );
  }

  Widget _buildPhaseSpaceAndStats() {
    return Container(
      height: 180,
      decoration: AppTheme.glassCard(radius: 24),
      child: Row(
        children: [
          // 1. Phase Space Map
          Expanded(
            flex: 2,
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
              
              // 2. Water Fill with Sloshing
              AnimatedBuilder(
                animation: _sloshController,
                builder: (context, child) {
                  // Subtle sloshing calculation
                  double slosh = math.sin(_sloshController.value * 2 * math.pi) * 2 * (fillPercentage > 0 ? 1 : 0);
                  
                  return AnimatedContainer(
                    duration: 600.ms,
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
                        topLeft: Radius.circular(fillPercentage > 0.9 ? 22 : 4 + slosh.abs()),
                        topRight: Radius.circular(fillPercentage > 0.9 ? 22 : 4 + slosh.abs()),
                      ),
                    ),
                    child: child,
                  );
                },
                child: CustomPaint(
                  painter: _JugGlossPainter(),
                ),
              ),

              // 3. Capacity Markers
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(max, (i) => Container(
                      height: 1,
                      width: 12,
                      color: Colors.white.withValues(alpha: 0.1),
                    )).reversed.toList(),
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
                  onSolve: () => solve(),
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
