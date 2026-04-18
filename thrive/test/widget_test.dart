import 'package:flutter_test/flutter_test.dart';
import 'package:thrive/main.dart';

void main() {
  testWidgets('Thrive app launches', (WidgetTester tester) async {
    await tester.pumpWidget(const ThriveApp());
    await tester.pump();
  });
}
