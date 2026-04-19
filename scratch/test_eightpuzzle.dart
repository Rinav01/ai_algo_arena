
import 'package:ai_algo_app/core/eightpuzzle_problem.dart';
import 'package:ai_algo_app/core/search_algorithms.dart';

void main() {
  print('Testing 8-Puzzle Solver efficiency...');
  final problem = EightPuzzleProblem(
    initialState: PuzzleState([1, 2, 3, 4, 0, 5, 7, 8, 6]) // A very simple 2-move puzzle
  );
  final algorithm = AStarAlgorithm<PuzzleState>();
  
  int steps = 0;
  bool found = false;
  
  for (final step in algorithm.solve(problem)) {
    steps++;
    if (step.isGoalReached) {
      print('SUCCESS: Solution found in $steps steps!');
      print('Path length: ${step.path.length}');
      found = true;
      break;
    }
    
    if (steps > 1000) {
      print('FAILURE: 8-Puzzle took too many steps for a simple configuration.');
      break;
    }
  }
}
