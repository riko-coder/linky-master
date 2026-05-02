import 'package:flutter_test/flutter_test.dart';

import 'package:linky_2/main.dart';

void main() {
  testWidgets('Linky app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const LinkyApp());
    expect(find.text('Welcome to Linky 🚀'), findsOneWidget);
  });
}
