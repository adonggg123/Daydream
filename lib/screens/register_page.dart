import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/otp_service.dart';
import 'home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
  with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isSendingOTP = false;
  bool _otpSent = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
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
    _confirmPasswordController.dispose();
    _otpController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSendingOTP = true;
      });

      try {
        await OTPService.sendOTP(_emailController.text.trim());
        
        if (mounted) {
          setState(() {
            _otpSent = true;
            _isSendingOTP = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP sent to your email!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSendingOTP = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _verifyOTPAndRegister() async {
    if (_otpFormKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final otp = _otpController.text.trim();

      // Verify OTP
      if (!OTPService.verifyOTP(email, otp)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid or expired OTP. Please request a new one.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // OTP verified, proceed with registration
      setState(() {
        _isLoading = true;
      });

      try {
        await _authService.registerWithEmailAndPassword(
          email,
          _passwordController.text,
        );

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _resetOTPFlow() {
    setState(() {
      _otpSent = false;
      _otpController.clear();
    });
    OTPService.removeOTP(_emailController.text.trim());
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
                                      'Join Our\nHotel Family',
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
                                      'Create an account to unlock exclusive benefits, manage your bookings, and enjoy our premium services.',
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
                                          'Instant booking confirmation',
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
                                          'Personalized room preferences',
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
                                          'Priority customer support',
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
                                          'Exclusive member discounts',
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

                          // Right side - Registration Form
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(isMobile ? 24 : 40),
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
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Logo for mobile
                                  if (isMobile)
                                    Column(
                                      children: [
                                        Container(
                                          width: 100,
                                          height: 100,
                                          margin: const EdgeInsets.only(bottom: 20),
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
                                        const SizedBox(height: 16),
                                        Text(
                                          'Create Account',
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade800,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Sign up to get started',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey.shade600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 32),
                                      ],
                                    )
                                  else
                                    Column(
                                      children: [
                                        Text(
                                          'Create New Account',
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade800,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Fill in your details to register',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey.shade600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 32),
                                      ],
                                    ),

                                  Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
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
                                        const SizedBox(height: 20),

                                        // Password Field
                                        TextFormField(
                                          controller: _passwordController,
                                          obscureText: _obscurePassword,
                                          textInputAction: TextInputAction.next,
                                          decoration: InputDecoration(
                                            labelText: 'Password',
                                            labelStyle: TextStyle(color: Colors.grey.shade600),
                                            prefixIcon: Icon(Icons.lock_outlined, color: Colors.grey.shade600),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
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
                                        const SizedBox(height: 20),

                                        // Confirm Password Field
                                        TextFormField(
                                          controller: _confirmPasswordController,
                                          obscureText: _obscureConfirmPassword,
                                          textInputAction: TextInputAction.done,
                                          onFieldSubmitted: (_) => _sendOTP(),
                                          decoration: InputDecoration(
                                            labelText: 'Confirm Password',
                                            labelStyle: TextStyle(color: Colors.grey.shade600),
                                            prefixIcon: Icon(Icons.lock_outlined, color: Colors.grey.shade600),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                                color: Colors.grey.shade600,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _obscureConfirmPassword = !_obscureConfirmPassword;
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
                                              return 'Please confirm your password';
                                            }
                                            if (value != _passwordController.text) {
                                              return 'Passwords do not match';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 32),

                                        // Send OTP or OTP Input Section
                                        if (!_otpSent) ...[
                                          // Send OTP Button
                                          SizedBox(
                                            height: 56,
                                            child: ElevatedButton(
                                              onPressed: (_isLoading || _isSendingOTP) ? null : _sendOTP,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue.shade600,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                elevation: 3,
                                                shadowColor: Colors.blue.shade200,
                                              ),
                                              child: _isSendingOTP
                                                  ? const SizedBox(
                                                      height: 24,
                                                      width: 24,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                      ),
                                                    )
                                                  : const Text(
                                                      'Send OTP',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ] else ...[
                                          // OTP Input Section
                                          Form(
                                            key: _otpFormKey,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                // OTP Title
                                                Text(
                                                  'Enter OTP',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                
                                                // OTP Description
                                                Text(
                                                  'We sent a 6-digit code to ${_emailController.text}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                
                                                // OTP Input Field
                                                TextFormField(
                                                  controller: _otpController,
                                                  keyboardType: TextInputType.number,
                                                  textAlign: TextAlign.center,
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter.digitsOnly,
                                                    LengthLimitingTextInputFormatter(6),
                                                  ],
                                                  style: const TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 8,
                                                  ),
                                                  decoration: InputDecoration(
                                                    hintText: '000000',
                                                    hintStyle: TextStyle(
                                                      fontSize: 24,
                                                      letterSpacing: 8,
                                                      color: Colors.grey.shade400,
                                                    ),
                                                    prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade600),
                                                    suffixIcon: IconButton(
                                                      icon: Icon(Icons.close, color: Colors.grey.shade600),
                                                      onPressed: _resetOTPFlow,
                                                      tooltip: 'Cancel OTP',
                                                    ),
                                                    filled: true,
                                                    fillColor: Colors.grey.shade50,
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                      borderSide: BorderSide.none,
                                                    ),
                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                                                  ),
                                                  validator: (value) {
                                                    if (value == null || value.isEmpty) {
                                                      return 'Please enter OTP';
                                                    }
                                                    if (value.length != 6) {
                                                      return 'OTP must be 6 digits';
                                                    }
                                                    return null;
                                                  },
                                                ),
                                                const SizedBox(height: 16),
                                                
                                                // Resend OTP Link
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: [
                                                    TextButton(
                                                      onPressed: _isSendingOTP ? null : () {
                                                        _resetOTPFlow();
                                                        _sendOTP();
                                                      },
                                                      child: Text(
                                                        'Resend OTP',
                                                        style: TextStyle(
                                                          color: Colors.blue.shade600,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 16),
                                                
                                                // Verify & Register Button
                                                SizedBox(
                                                  height: 56,
                                                  child: ElevatedButton(
                                                    onPressed: (_isLoading || _isSendingOTP) ? null : _verifyOTPAndRegister,
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
                                                            height: 24,
                                                            width: 24,
                                                            child: CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                            ),
                                                          )
                                                        : const Text(
                                                            'Verify & Register',
                                                            style: TextStyle(
                                                              fontSize: 18,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 32),

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
                                                'Or sign up with',
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
                                        const SizedBox(height: 24),

                                        // Social Registration Buttons
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
                                        const SizedBox(height: 32),

                                        // Login Link
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Already have an account? ',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 15,
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: Text(
                                                'Login',
                                                style: TextStyle(
                                                  color: Colors.blue.shade600,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
      await _authService.signInWithGoogle();
      if (mounted) {
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
      await _authService.signInWithFacebook();
      if (mounted) {
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