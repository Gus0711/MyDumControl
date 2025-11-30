// Tests de base pour MyDumControl

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mydumcontrol/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MyDumControlApp(),
      ),
    );

    // Verify that app starts (splash screen)
    await tester.pump();
    expect(find.text('MyDumControl'), findsOneWidget);
  });
}
