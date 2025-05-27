import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'handlers/auth.dart';
import 'handlers/login_or_register.dart';
import 'pages/home_page.dart';
import 'pages/profile_page.dart';
import 'pages/users_page.dart';
import 'theme/theme.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    debugPrint('Loading environment variables...');
    await dotenv.load();

    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    debugPrint('Supabase URL: $supabaseUrl');
    debugPrint('Starting Supabase initialization...');

    await Supabase.initialize(
      url: supabaseUrl!,
      anonKey: supabaseAnonKey!,
      debug: true,
    );

    debugPrint('Supabase initialization completed successfully');
    runApp(const MyApp());
  } catch (error) {
    debugPrint('X Initialization error: $error');
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthPage(),
      theme: lightMode,
      darkTheme: darkMode,
      routes: {
        '/login_register_page': (context) => const LoginOrRegister(),
        '/home_page': (context) => HomePage(),
        '/profile_page': (context) => ProfilePage(),
        '/users_page': (context) => const UsersPage(),
      },
    );
  }
}
