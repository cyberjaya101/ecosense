import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ecosense/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('admin login test', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Find the "Admin" text
    final adminTab = find.text('Admin');
    expect(adminTab, findsOneWidget);

    // Tap on Admin
    await tester.tap(adminTab);
    await tester.pumpAndSettle();

    // Find the "Sign In" button
    final signInBtn = find.text('Sign In');
    expect(signInBtn, findsOneWidget);

    // Tap on Sign In
    await tester.tap(signInBtn);

    // Try pumping, this is where it should crash
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // If it survives, check for something on AdminMapScreen
    expect(find.text('ECO-COMMAND'), findsWidgets);
  });
}
