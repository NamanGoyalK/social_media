import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_media/helper/helper_functions.dart';

void main() {
  testWidgets('displayMessageToUser shows a dialog with the correct message', (
    WidgetTester tester,
  ) async {
    // Build a testable widget
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () => displayMessageToUser('Test Message', context),
              child: const Text('Show Dialog'),
            );
          },
        ),
      ),
    );

    // Tap the button
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Verify the dialog is displayed with the correct message
    expect(find.text('Test Message'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
  });
}
