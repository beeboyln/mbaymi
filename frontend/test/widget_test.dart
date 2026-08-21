import 'package:flutter_test/flutter_test.dart';

import 'package:mbaymi/main.dart';

void main() {
  testWidgets('app starts on the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MbaymiApp());

    expect(find.text('Savana'), findsOneWidget);
    expect(find.text('Chargement...'), findsOneWidget);
  });
}
