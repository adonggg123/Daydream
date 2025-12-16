import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/user.dart';
import 'admin_dashboard.dart';

class LoginPageAdmin extends StatefulWidget {
  const LoginPageAdmin({super.key});

  @override
  State<LoginPageAdmin> createState() => _LoginPageAdminState();
}

class _LoginPageAdminState extends State<LoginPageAdmin>
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
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
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
              await _authService.signOut();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Your account has been deactivated. Please contact an administrator.'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
              return;
            }

            // Only allow admin/staff/receptionist access
            if (appUser != null &&
                (appUser.isStaffOrAdmin || appUser.isReceptionist)) {
              // Success - navigate to admin dashboard
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                      builder: (context) => const AdminDashboard()),
                );
              }
              return;
            } else {
              // User is not authorized
              await _authService.signOut();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Access denied. Admin, staff, or receptionist credentials required.'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
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
    final Color primaryColor = Colors.blue.shade700;
    final Color secondaryColor = Colors.cyan.shade600;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.grey.shade50,
                Colors.grey.shade100,
              ],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Stack(
                children: [
                  // Modern background pattern
                  Positioned(
                    top: -100,
                    right: -100,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            primaryColor.withOpacity(0.05),
                            primaryColor.withOpacity(0.02),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -150,
                    left: -150,
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            secondaryColor.withOpacity(0.05),
                            secondaryColor.withOpacity(0.02),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Main content
                  Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 20 : 40,
                        vertical: 20,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isMobile ? 400 : 1000,
                        ),
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Left side - Branding (hidden on mobile)
                              if (!isMobile)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 60),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Logo Container
                                        Container(
                                          width: 140,
                                          height: 140,
                                          margin:
                                              const EdgeInsets.only(bottom: 32),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(24),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.08),
                                                blurRadius: 30,
                                                offset: const Offset(0, 15),
                                              ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(0),
                                            child: Transform.scale(
                                              scale: 1.6,
                                              child: Image.asset(
                                                'assets/icons/LOGO2.png',
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Headline
                                        Text(
                                          'Welcome Back,',
                                          style: TextStyle(
                                            fontSize: 44,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.grey.shade900,
                                            height: 1.1,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Administrator',
                                          style: TextStyle(
                                            fontSize: 44,
                                            fontWeight: FontWeight.w800,
                                            color: primaryColor,
                                            height: 1.1,
                                          ),
                                        ),
                                        const SizedBox(height: 24),

                                        // Description
                                        Text(
                                          'Access your resort management dashboard to handle bookings, manage users, and oversee operations with our comprehensive admin tools.',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.grey.shade600,
                                            height: 1.6,
                                          ),
                                        ),
                                        const SizedBox(height: 40),

                                        // Feature List
                                        _buildFeatureItem(
                                          Icons.dashboard_outlined,
                                          'Complete Dashboard',
                                          'Manage all resort operations from one place',
                                        ),
                                        const SizedBox(height: 16),
                                        _buildFeatureItem(
                                          Icons.people_outline,
                                          'User Management',
                                          'Control staff access and user permissions',
                                        ),
                                        const SizedBox(height: 16),
                                        _buildFeatureItem(
                                          Icons.analytics_outlined,
                                          'Real-time Analytics',
                                          'Track performance with live data insights',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              // Right side - Login Form
                              Expanded(
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth: isMobile ? 400 : 450,
                                  ),
                                  child: Card(
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Container(
                                      padding: EdgeInsets.all(isMobile ? 32 : 48),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.06),
                                            blurRadius: 40,
                                            offset: const Offset(0, 20),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          // Mobile Logo
                                          if (isMobile)
                                            Column(
                                              children: [
                                                Container(
                                                  width: 100,
                                                  height: 100,
                                                  margin: const EdgeInsets.only(
                                                      bottom: 24),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(20),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.08),
                                                        blurRadius: 20,
                                                        offset:
                                                            const Offset(0, 10),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(4),
                                                    child: Transform.scale(
                                                      scale: 1.5,
                                                      child: Image.asset(
                                                        'assets/icons/LOGO2.png',
                                                        fit: BoxFit.contain,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  'Admin Dashboard',
                                                  style: TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.grey.shade900,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Sign in to continue',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w400,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 32),
                                              ],
                                            ),

                                          // Desktop Header
                                          if (!isMobile)
                                            Column(
                                              children: [
                                                Text(
                                                  'Sign In',
                                                  style: TextStyle(
                                                    fontSize: 32,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.grey.shade900,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Enter your credentials to access the admin panel',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w400,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 40),
                                              ],
                                            ),

                                          // Form
                                          Form(
                                            key: _formKey,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                // Email Field
                                                Text(
                                                  'Email Address',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                TextFormField(
                                                  controller: _emailController,
                                                  keyboardType:
                                                      TextInputType.emailAddress,
                                                  textInputAction:
                                                      TextInputAction.next,
                                                  style: TextStyle(
                                                    color: Colors.grey.shade900,
                                                    fontSize: 15,
                                                  ),
                                                  decoration: InputDecoration(
                                                    hintText: 'admin@resort.com',
                                                    hintStyle: TextStyle(
                                                        color:
                                                            Colors.grey.shade400),
                                                    prefixIcon: Container(
                                                      margin: const EdgeInsets.only(
                                                          left: 16, right: 12),
                                                      child: Icon(
                                                        Icons.email_outlined,
                                                        color: Colors.grey.shade500,
                                                        size: 20,
                                                      ),
                                                    ),
                                                    filled: true,
                                                    fillColor:
                                                        Colors.grey.shade50,
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(12),
                                                      borderSide: BorderSide.none,
                                                    ),
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                            horizontal: 16,
                                                            vertical: 16),
                                                  ),
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return 'Please enter your email';
                                                    }
                                                    if (!value.contains('@')) {
                                                      return 'Please enter a valid email';
                                                    }
                                                    return null;
                                                  },
                                                ),
                                                const SizedBox(height: 20),

                                                // Password Field
                                                Text(
                                                  'Password',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                TextFormField(
                                                  controller: _passwordController,
                                                  obscureText: _obscurePassword,
                                                  textInputAction:
                                                      TextInputAction.done,
                                                  onFieldSubmitted: (_) =>
                                                      _handleLogin(),
                                                  style: TextStyle(
                                                    color: Colors.grey.shade900,
                                                    fontSize: 15,
                                                  ),
                                                  decoration: InputDecoration(
                                                    hintText: 'Enter your password',
                                                    hintStyle: TextStyle(
                                                        color:
                                                            Colors.grey.shade400),
                                                    prefixIcon: Container(
                                                      margin: const EdgeInsets.only(
                                                          left: 16, right: 12),
                                                      child: Icon(
                                                        Icons.lock_outlined,
                                                        color: Colors.grey.shade500,
                                                        size: 20,
                                                      ),
                                                    ),
                                                    suffixIcon: Container(
                                                      margin: const EdgeInsets.only(
                                                          right: 12),
                                                      child: IconButton(
                                                        icon: Icon(
                                                          _obscurePassword
                                                              ? Icons
                                                                  .visibility_off_outlined
                                                              : Icons
                                                                  .visibility_outlined,
                                                          color:
                                                              Colors.grey.shade500,
                                                          size: 20,
                                                        ),
                                                        onPressed: () {
                                                          setState(() {
                                                            _obscurePassword =
                                                                !_obscurePassword;
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                    filled: true,
                                                    fillColor:
                                                        Colors.grey.shade50,
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(12),
                                                      borderSide: BorderSide.none,
                                                    ),
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                            horizontal: 16,
                                                            vertical: 16),
                                                  ),
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return 'Please enter your password';
                                                    }
                                                    if (value.length < 6) {
                                                      return 'Password must be at least 6 characters';
                                                    }
                                                    return null;
                                                  },
                                                ),
                                                const SizedBox(height: 8),

                                                // Forgot Password (optional)
                                                Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: TextButton(
                                                    onPressed: () {
                                                      // Add forgot password functionality
                                                    },
                                                    style: TextButton.styleFrom(
                                                      padding:
                                                          const EdgeInsets.all(8),
                                                      minimumSize: Size.zero,
                                                      tapTargetSize:
                                                          MaterialTapTargetSize
                                                              .shrinkWrap,
                                                    ),
                                                    child: Text(
                                                      'Forgot Password?',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: primaryColor,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 32),

                                                // Login Button
                                                SizedBox(
                                                  height: 52,
                                                  child: ElevatedButton(
                                                    onPressed: _isLoading
                                                        ? null
                                                        : _handleLogin,
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          primaryColor,
                                                      foregroundColor:
                                                          Colors.white,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                12),
                                                      ),
                                                      elevation: 0,
                                                      shadowColor:
                                                          primaryColor.withOpacity(
                                                              0.3),
                                                      padding: EdgeInsets.zero,
                                                    ),
                                                    child: _isLoading
                                                        ? SizedBox(
                                                            height: 20,
                                                            width: 20,
                                                            child:
                                                                CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              valueColor:
                                                                  AlwaysStoppedAnimation<
                                                                          Color>(
                                                                      Colors
                                                                          .white),
                                                            ),
                                                          )
                                                        : Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Text(
                                                                'Sign In',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 15,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  width: 10),
                                                              Icon(
                                                                Icons
                                                                    .arrow_forward,
                                                                size: 18,
                                                              ),
                                                            ],
                                                          ),
                                                  ),
                                                ),

                                                // Divider with text
                                                const SizedBox(height: 40),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Divider(
                                                        color:
                                                            Colors.grey.shade300,
                                                        thickness: 1,
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                              horizontal: 16),
                                                      child: Text(
                                                        'Admin Access Only',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: Colors
                                                              .grey.shade500,
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Divider(
                                                        color:
                                                            Colors.grey.shade300,
                                                        thickness: 1,
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                // Additional Info
                                                const SizedBox(height: 24),
                                                Text(
                                                  'Ensure you are using authorized admin credentials. Unauthorized access attempts are logged and monitored.',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w400,
                                                    color: Colors.grey.shade500,
                                                    height: 1.4,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.blue.shade700,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}