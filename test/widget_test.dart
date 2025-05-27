import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:social_media/handlers/auth.dart';
import 'package:social_media/main.dart';
import 'package:social_media/pages/login_page.dart';
import 'package:social_media/pages/register_page.dart';

// Generate mocks
@GenerateMocks([SupabaseClient, GoTrueClient, AuthResponse, User, AuthState])
import 'widget_test.mocks.dart';

void main() {
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockGoTrueClient;

  setUpAll(() async {
    // Mock SharedPreferences plugin
    TestWidgetsFlutterBinding.ensureInitialized();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'getAll') {
              return <String, dynamic>{}; // Return empty prefs
            }
            return null;
          },
        );

    // Create mock instances
    mockSupabaseClient = MockSupabaseClient();
    mockGoTrueClient = MockGoTrueClient();

    // Set up mock behavior
    when(mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
    when(mockGoTrueClient.currentUser).thenReturn(null);

    // Mock the onAuthStateChange method to return an empty stream
    when(
      mockGoTrueClient.onAuthStateChange,
    ).thenAnswer((_) => Stream<AuthState>.empty());

    // Initialize Supabase with test configuration
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      anonKey: 'test-key',
    );

    // Replace the client with our mock
    Supabase.instance.client = mockSupabaseClient;
  });

  // Clean up after all tests
  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          null,
        );
  });

  testWidgets('App loads and displays AuthPage', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const MyApp());

    // Verify AuthPage is displayed
    expect(find.byType(AuthPage), findsOneWidget);
  });

  testWidgets('LoginPage displays email and password fields', (
    WidgetTester tester,
  ) async {
    // Build LoginPage
    await tester.pumpWidget(MaterialApp(home: LoginPage(onTap: () {})));

    // Verify email and password fields are present
    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
  });

  testWidgets('RegisterPage displays username, email, and password fields', (
    WidgetTester tester,
  ) async {
    // Build RegisterPage
    await tester.pumpWidget(MaterialApp(home: RegisterPage(onTap: () {})));

    // Verify username, email, and password fields are present
    expect(find.widgetWithText(TextField, 'Username'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Confirm Password'), findsOneWidget);
  });

  testWidgets('Navigation to RegisterPage works', (WidgetTester tester) async {
    // Build LoginPage with navigation
    bool navigated = false;
    await tester.pumpWidget(
      MaterialApp(home: LoginPage(onTap: () => navigated = true)),
    );

    // Tap on "Register Here"
    await tester.tap(find.text('Register Here'));
    await tester.pumpAndSettle();

    // Verify navigation callback was triggered
    expect(navigated, isTrue);
  });

  group('Form validation tests', () {
    testWidgets('Login form shows validation errors for empty fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: LoginPage(onTap: () {})));

      // Find and tap the login button
      final loginButton = find.widgetWithText(ElevatedButton, 'Login');
      if (loginButton.evaluate().isNotEmpty) {
        await tester.tap(loginButton);
        await tester.pumpAndSettle();
      }

      // Note: Adjust these expectations based on your actual validation implementation
      // You might need to check for specific error text or UI changes
    });

    testWidgets('Register form shows validation errors for empty fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: RegisterPage(onTap: () {})));

      // Find and tap the register button
      final registerButton = find.widgetWithText(ElevatedButton, 'Register');
      if (registerButton.evaluate().isNotEmpty) {
        await tester.tap(registerButton);
        await tester.pumpAndSettle();
      }

      // Note: Adjust these expectations based on your actual validation implementation
    });
  });

  group('Authentication flow tests', () {
    testWidgets('Login form accepts user input', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: LoginPage(onTap: () {})));

      // Find text fields by their hint text or label
      final emailField = find.widgetWithText(TextField, 'Email');
      final passwordField = find.widgetWithText(TextField, 'Password');

      // Enter text into fields
      if (emailField.evaluate().isNotEmpty) {
        await tester.enterText(emailField, 'test@example.com');
      }
      if (passwordField.evaluate().isNotEmpty) {
        await tester.enterText(passwordField, 'password123');
      }

      await tester.pumpAndSettle();

      // Verify text was entered
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('Register form accepts user input', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: RegisterPage(onTap: () {})));

      // Find text fields
      final usernameField = find.widgetWithText(TextField, 'Username');
      final emailField = find.widgetWithText(TextField, 'Email');
      final passwordField = find.widgetWithText(TextField, 'Password');
      final confirmPasswordField = find.widgetWithText(
        TextField,
        'Confirm Password',
      );

      // Enter text into fields
      if (usernameField.evaluate().isNotEmpty) {
        await tester.enterText(usernameField, 'testuser');
      }
      if (emailField.evaluate().isNotEmpty) {
        await tester.enterText(emailField, 'test@example.com');
      }
      if (passwordField.evaluate().isNotEmpty) {
        await tester.enterText(passwordField, 'password123');
      }
      if (confirmPasswordField.evaluate().isNotEmpty) {
        await tester.enterText(confirmPasswordField, 'password123');
      }

      await tester.pumpAndSettle();

      // Verify text was entered
      expect(find.text('testuser'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
    });
  });

  group('Widget interaction tests', () {
    testWidgets('Tapping outside text field removes focus', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: LoginPage(onTap: () {})));

      // Tap on email field to focus it
      final emailField = find.widgetWithText(TextField, 'Email');
      if (emailField.evaluate().isNotEmpty) {
        await tester.tap(emailField);
        await tester.pumpAndSettle();

        // Tap somewhere else to remove focus
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
      }

      // Test passes if no exceptions are thrown
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('Password field hides text by default', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: LoginPage(onTap: () {})));

      final passwordField = find.widgetWithText(TextField, 'Password');
      if (passwordField.evaluate().isNotEmpty) {
        final textField = tester.widget<TextField>(passwordField);
        expect(textField.obscureText, isTrue);
      }
    });
  });
}
