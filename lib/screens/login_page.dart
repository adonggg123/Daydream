import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/user.dart';
import 'register_page.dart';
import 'home_page.dart';
import 'admin_dashboard.dart';
import 'receptionist_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _userService = UserService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final credential = await _authService.signInWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
        );

        if (mounted) {
          // Decide destination based on user role
          final user = credential?.user;
          if (user != null) {
            AppUser? appUser = await _userService.getUserProfile(user.uid);

            // Fallback: try lookup by email if profile not found by UID
            if (appUser == null && user.email != null) {
              final matches =
                  await _userService.searchUsersByEmail(user.email!);
              if (matches.isNotEmpty) {
                appUser = matches.first;
              }
            }

            // Check if user is active
            if (appUser != null && !appUser.isActive) {
              // Sign out the user if they're deactivated
              await _authService.signOut();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Your account has been deactivated. Please contact an administrator.'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
              return;
            }

            if (appUser != null) {
              if (appUser.isReceptionist) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const ReceptionistDashboard()),
                );
                return;
              }
              if (appUser.isStaffOrAdmin) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const AdminDashboard()),
                );
                return;
              }
            }
          }

          // Default for non-admins
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: Colors.teal.shade200,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade400,
              Colors.cyan.shade300,
              Colors.teal.shade200,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Stack(
              children: [
                // Background decorative elements
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -100,
                  left: -100,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                
                // Main content - Responsive Layout
                Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 24.0 : 48.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isMobile ? 400 : 800,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Left side - Welcome content (hidden on mobile)
                          if (!isMobile)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 48.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 160,
                                      height: 160,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 3),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: Center(
                                          child: Transform.scale(
                                            scale: 3.0,
                                            child: Image.asset(
                                              'assets/icons/LOGO2.png',
                                              width: 500,
                                              height: 500,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    Text(
                                      'Welcome to\nOur Hotel',
                                      style: TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        height: 1.2,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(0.3),
                                            offset: const Offset(0, 2),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Experience luxury and comfort like never before. Sign in to access your account and manage your bookings.',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white.withOpacity(0.95),
                                        height: 1.5,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(0.2),
                                            offset: const Offset(0, 1),
                                            blurRadius: 3,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.white, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Easy booking management',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.white, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          '24/7 customer support',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.white, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Exclusive member benefits',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Right side - Login Form
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Logo outside card (mobile only)
                                if (isMobile)
                                  Column(
                                    children: [
                                      Container(
                                        width: 100,
                                        height: 100,
                                        margin: const EdgeInsets.only(bottom: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 3),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 20,
                                              offset: const Offset(0, 10),
                                            ),
                                          ],
                                        ),
                                        child: ClipOval(
                                          child: Center(
                                            child: Transform.scale(
                                              scale: 2.8,
                                              child: Image.asset(
                                                'assets/icons/LOGO2.png',
                                                width: 500,
                                                height: 500,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'Welcome Back',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                
                                // Card
                                Container(
                                  padding: EdgeInsets.all(isMobile ? 18 : 28),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 30,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        // Login Label (centered, larger blue text)
                                        Center(
                                          child: Text(
                                            'Login',
                                            style: TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.shade600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        // Email Field
                                        TextFormField(
                                          controller: _emailController,
                                          keyboardType: TextInputType.emailAddress,
                                          textInputAction: TextInputAction.next,
                                          decoration: InputDecoration(
                                            labelText: 'Email',
                                            labelStyle: TextStyle(color: Colors.grey.shade600),
                                            prefixIcon: Icon(Icons.email_outlined, color: Colors.grey.shade600),
                                            filled: true,
                                            fillColor: Colors.grey.shade50,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide.none,
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter your email';
                                            }
                                            if (!value.contains('@')) {
                                              return 'Please enter a valid email';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 14),

                                        // Password Field
                                        TextFormField(
                                          controller: _passwordController,
                                          obscureText: _obscurePassword,
                                          textInputAction: TextInputAction.done,
                                          onFieldSubmitted: (_) => _handleLogin(),
                                          decoration: InputDecoration(
                                            labelText: 'Password',
                                            labelStyle: TextStyle(color: Colors.grey.shade600),
                                            prefixIcon: Icon(Icons.lock_outlined, color: Colors.grey.shade600),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                                color: Colors.grey.shade600,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _obscurePassword = !_obscurePassword;
                                                });
                                              },
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey.shade50,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide.none,
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter your password';
                                            }
                                            if (value.length < 6) {
                                              return 'Password must be at least 6 characters';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 16),

                                        // Login Button
                                        SizedBox(
                                          height: 50,
                                          child: ElevatedButton(
                                            onPressed: _isLoading ? null : _handleLogin,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue.shade600,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              elevation: 3,
                                              shadowColor: Colors.blue.shade200,
                                            ),
                                            child: _isLoading
                                                ? const SizedBox(
                                                    height: 20,
                                                    width: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                    ),
                                                  )
                                                : const Text(
                                                    'Login',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),

                                        // Divider with "Or"
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Divider(
                                                color: Colors.grey.shade300,
                                                thickness: 1,
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 16),
                                              child: Text(
                                                'OR',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Divider(
                                                color: Colors.grey.shade300,
                                                thickness: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),

                                        // Social Login Buttons
                                        Row(
                                          children: [
                                            Expanded(
                                              child: SizedBox(
                                                height: 50,
                                                child: OutlinedButton.icon(
                                                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                                                  icon: Image.network(
                                                    'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                                                    height: 20,
                                                    width: 20,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return const Icon(
                                                        Icons.g_mobiledata,
                                                        color: Colors.red,
                                                        size: 20,
                                                      );
                                                    },
                                                  ),
                                                  label: const Text(
                                                    'Google',
                                                    style: TextStyle(
                                                      color: Colors.black87,
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  style: OutlinedButton.styleFrom(
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    side: BorderSide(color: Colors.grey.shade300),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: SizedBox(
                                                height: 50,
                                                child: OutlinedButton.icon(
                                                  onPressed: _isLoading ? null : _handleFacebookSignIn,
                                                  icon: const Icon(
                                                    Icons.facebook,
                                                    color: Color(0xFF1877F2),
                                                    size: 20,
                                                  ),
                                                  label: const Text(
                                                    'Facebook',
                                                    style: TextStyle(
                                                      color: Colors.black87,
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  style: OutlinedButton.styleFrom(
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    side: BorderSide(color: Colors.grey.shade300),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),

                                        // Sign Up Link
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "Don't have an account? ",
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) => const RegisterPage(),
                                                  ),
                                                );
                                              },
                                              child: Text(
                                                'Sign up',
                                                style: TextStyle(
                                                  color: Colors.blue.shade600,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final credential = await _authService.signInWithGoogle();
      if (mounted) {
        final user = credential?.user;
        if (user != null) {
          AppUser? appUser = await _userService.getUserProfile(user.uid);

          if (appUser == null && user.email != null) {
            final matches =
                await _userService.searchUsersByEmail(user.email!);
            if (matches.isNotEmpty) {
              appUser = matches.first;
            }
          }

          // Check if user is active
          if (appUser != null && !appUser.isActive) {
            // Sign out the user if they're deactivated
            await _authService.signOut();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Your account has been deactivated. Please contact an administrator.'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return;
          }

          if (appUser != null) {
            if (appUser.isReceptionist) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const ReceptionistDashboard()),
              );
              return;
            }
            if (appUser.isStaffOrAdmin) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const AdminDashboard()),
              );
              return;
            }
          }
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleFacebookSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final credential = await _authService.signInWithFacebook();
      if (mounted) {
        final user = credential?.user;
        if (user != null) {
          AppUser? appUser = await _userService.getUserProfile(user.uid);

          if (appUser == null && user.email != null) {
            final matches =
                await _userService.searchUsersByEmail(user.email!);
            if (matches.isNotEmpty) {
              appUser = matches.first;
            }
          }

          // Check if user is active
          if (appUser != null && !appUser.isActive) {
            // Sign out the user if they're deactivated
            await _authService.signOut();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Your account has been deactivated. Please contact an administrator.'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return;
          }

          if (appUser != null) {
            if (appUser.isReceptionist) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const ReceptionistDashboard()),
              );
              return;
            }
            if (appUser.isStaffOrAdmin) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const AdminDashboard()),
              );
              return;
            }
          }
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}