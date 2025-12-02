import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'models/user.dart';
import 'screens/landing_page.dart';
import 'screens/home_page.dart';
import 'screens/admin_dashboard.dart';
import 'screens/receptionist_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daydream Resort',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final userService = UserService();

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user is authenticated, determine destination based on role
        if (snapshot.hasData && snapshot.data != null) {
          // Additional safety: get the user ID via AuthService
          final currentUser = authService.currentUser;

          if (currentUser == null) {
            // Fallback to home if something is inconsistent
            return const HomePage();
          }

          return FutureBuilder<AppUser?>(
            future: userService.getUserProfile(currentUser.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final appUser = userSnapshot.data;

              if (appUser != null) {
                if (appUser.isReceptionist) {
                  return const ReceptionistDashboard();
                }
                if (appUser.isStaffOrAdmin) {
                  return const AdminDashboard();
                }
              }

              // Default for guests/staff or missing profile
              return const HomePage();
            },
          );
        }

        // If user is not authenticated, show landing page
        return const LandingPage();
      },
    );
  }
}
