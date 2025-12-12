// Tests de base pour MyGlobalDC

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:myglobaldc/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MyGlobalDCApp(),
      ),
    );

    // Verify that app starts (splash screen)
    await tester.pump();
    expect(find.text('MyGlobalDC'), findsOneWidget);
  });
}
