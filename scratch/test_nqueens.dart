
import 'package:ai_algo_app/core/nqueens_problem.dart';
import 'package:ai_algo_app/core/search_algorithms.dart';

void main() {
  print('Testing N-Queens Solver stability and correctness...');
  final problem = NQueensProblem(n: 8);
  final algorithm = DFSAlgorithm<QueensState>();
  
  int steps = 0;
  bool found = false;
  final visited = <QueensState>{};
  
  for (final step in algorithm.solve(problem)) {
    final state = step.currentState;
    if (state == null) continue;
    
    steps++;
    if (visited.contains(state)) {
      print('ERROR: Redundant state visited at step $steps: $state');
      // No more printing after first error to avoid spam
      return;
    }
    visited.add(state);
    
    if (step.isGoalReached) {
      print('SUCCESS: Solution found in $steps steps!');
      print(problem.getBoardString(state));
      found = true;
      break;
    }
    
    if (steps > 5000) {
      print('FAILURE: Search exceeded 5000 steps without finding a solution.');
      break;
    }
  }
  
  if (!found) {
    print('No solution found.');
  }
}
