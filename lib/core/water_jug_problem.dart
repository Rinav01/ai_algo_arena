import 'package:algo_arena/core/problem_definition.dart';
import 'dart:math';

/// Represents the state of the two jugs
class WaterJugState {
  final int jugA;
  final int jugB;
  final String operation;

  WaterJugState(this.jugA, this.jugB, [this.operation = 'Initial State']);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WaterJugState &&
          runtimeType == other.runtimeType &&
          jugA == other.jugA &&
          jugB == other.jugB;

  @override
  int get hashCode => jugA.hashCode ^ jugB.hashCode;

  @override
  String toString() => '($jugA, $jugB) - $operation';
}

/// The Water Jug Problem definition
class WaterJugProblem extends Problem<WaterJugState> {
  final int capacityA;
  final int capacityB;
  final int target;

  WaterJugProblem({
    required this.capacityA,
    required this.capacityB,
    required this.target,
  });

  @override
  WaterJugState get initialState => WaterJugState(0, 0);

  @override
  bool isGoal(WaterJugState state) {
    return state.jugA == target || state.jugB == target;
  }

  @override
  List<WaterJugState> getNeighbors(WaterJugState state) {
    final List<WaterJugState> neighbors = [];

    // 1. Fill Jug A
    if (state.jugA < capacityA) {
      neighbors.add(WaterJugState(capacityA, state.jugB, 'Fill Jug A'));
    }

    // 2. Fill Jug B
    if (state.jugB < capacityB) {
      neighbors.add(WaterJugState(state.jugA, capacityB, 'Fill Jug B'));
    }

    // 3. Empty Jug A
    if (state.jugA > 0) {
      neighbors.add(WaterJugState(0, state.jugB, 'Empty Jug A'));
    }

    // 4. Empty Jug B
    if (state.jugB > 0) {
      neighbors.add(WaterJugState(state.jugA, 0, 'Empty Jug B'));
    }

    // 5. Pour A to B
    if (state.jugA > 0 && state.jugB < capacityB) {
      int amountToPour = min(state.jugA, capacityB - state.jugB);
      neighbors.add(WaterJugState(
        state.jugA - amountToPour,
        state.jugB + amountToPour,
        'Pour A ➔ B',
      ));
    }

    // 6. Pour B to A
    if (state.jugB > 0 && state.jugA < capacityA) {
      int amountToPour = min(state.jugB, capacityA - state.jugA);
      neighbors.add(WaterJugState(
        state.jugA + amountToPour,
        state.jugB - amountToPour,
        'Pour B ➔ A',
      ));
    }

    return neighbors;
  }

  @override
  double heuristic(WaterJugState state) {
    // A simple heuristic: absolute distance to target
    double distA = (state.jugA - target).abs().toDouble();
    double distB = (state.jugB - target).abs().toDouble();
    return min(distA, distB);
  }

  @override
  double moveCost(WaterJugState a, WaterJugState b) => 1.0;

  @override
  String stateToString(WaterJugState state) => '(${state.jugA}L, ${state.jugB}L)';

  @override
  bool isValid(WaterJugState state) => true;

  @override
  Map<String, dynamic> toSnapshot() => {
    'type': 'water_jug',
    'capacityA': capacityA,
    'capacityB': capacityB,
    'target': target,
  };

  static WaterJugProblem fromSnapshot(Map<String, dynamic> snapshot) {
    return WaterJugProblem(
      capacityA: (snapshot['capacityA'] as num).toInt(),
      capacityB: (snapshot['capacityB'] as num).toInt(),
      target: (snapshot['target'] as num).toInt(),
    );
  }
  
  @override
  WaterJugState get goalState => WaterJugState(target, 0, 'Goal State');
}
