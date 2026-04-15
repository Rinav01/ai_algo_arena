// Widget smoke test for AI Algorithm Arena.
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_algo_app/main.dart';

void main() {
  testWidgets('App smoke test — HomeScreen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const AiAlgoApp());
    expect(find.text('AI Algorithm'), findsAny);
  });
}
