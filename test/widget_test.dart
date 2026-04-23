// Widget smoke test for Algo Arena.
import 'package:flutter_test/flutter_test.dart';
import 'package:algo_arena/main.dart';

void main() {
  testWidgets('App smoke test — HomeScreen renders', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AlgoArenaApp());
    expect(find.text('ALGO ARENA'), findsAny);
  });
}
