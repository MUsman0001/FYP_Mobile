import 'package:flutter/material.dart';
import 'features/notifications/notifications_service.dart';
import 'core/api_client.dart';
import 'features/auth/auth_api.dart';
import 'features/auth/auth_repository.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize push service early (best-effort, safe if Firebase missing)
  NotificationsService.I.initPushIfPossible();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> _checkLoggedIn() async {
    final api = AuthApi(ApiClient());
    final repo = AuthRepository(api: api, storage: api.client.secureStorage);
    return repo.isLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AeroCrew Flow',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: FutureBuilder<bool>(
        future: _checkLoggedIn(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // If user is logged in, show HomeScreen
          // If not logged in, show LoginScreen (MFA flow is handled in login_screen.dart)
          return snapshot.data! ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }
}
