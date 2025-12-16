import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'models/user.dart';
import 'screens/admin_dashboard.dart';
import 'screens/login_page_admin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AdminDashboardApp());
}

class AdminDashboardApp extends StatelessWidget {
  const AdminDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daydream Admin Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const AdminAuthWrapper(),
    );
  }
}

class AdminAuthWrapper extends StatelessWidget {
  const AdminAuthWrapper({super.key});

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

        // If user is authenticated, check if they are admin/staff
        if (snapshot.hasData && snapshot.data != null) {
          final currentUser = authService.currentUser;

          if (currentUser == null) {
            return const LoginPageAdmin();
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

              // Only allow admin/staff/receptionist access
              if (appUser != null && (appUser.isStaffOrAdmin || appUser.isReceptionist)) {
                if (appUser.isReceptionist) {
                  // For receptionist, you might want to show a different dashboard
                  // For now, showing admin dashboard
                  return const AdminDashboard();
                }
                return const AdminDashboard();
              }

              // User is not authorized - show login with error message
              return const LoginPageAdmin();
            },
          );
        }

        // If user is not authenticated, show login page
        return const LoginPageAdmin();
      },
    );
  }
}

