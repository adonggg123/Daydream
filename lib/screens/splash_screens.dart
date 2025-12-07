import 'package:flutter/material.dart';
import 'login_page.dart'; // Your existing landing page

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _buttonOpacityAnimation;
  late Animation<double> _logoScaleAnimation;
  
  bool _showGetStarted = false;
  bool _logoEnlarged = false;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Create animations
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    _textSlideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    // Logo scale animation for enlargement
    _logoScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Button fade-in animation
    _buttonOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.8, 1.0, curve: Curves.easeIn),
      ),
    );

    // Start initial animation
    _controller.forward().then((_) {
      // After initial animation completes, wait 1 second then show Get Started
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _showGetStarted = true;
          _logoEnlarged = true;
        });
      });
    });
  }

  void _navigateToLandingPage() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade900,
              Colors.cyan.shade800,
              Colors.teal.shade700,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated background elements
            Positioned(
              top: -100,
              right: -100,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _controller.value * 1.5,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05 * _controller.value),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: -150,
              left: -150,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _controller.value * 1.2,
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.03 * _controller.value),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Star particles
            ...List.generate(20, (index) {
              return Positioned(
                top: MediaQuery.of(context).size.height * (0.1 + index * 0.04),
                left: MediaQuery.of(context).size.width * (0.1 + (index % 5) * 0.2),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _opacityAnimation.value,
                      child: Transform.scale(
                        scale: 0.5 + _controller.value * 0.5,
                        child: Icon(
                          Icons.star,
                          size: 12 + index % 3 * 4,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with animation and enlargement
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final scaleValue = _logoEnlarged 
                          ? _logoScaleAnimation.value 
                          : _scaleAnimation.value;
                      
                      return Transform.scale(
                        scale: scaleValue,
                        child: Opacity(
                          opacity: _opacityAnimation.value,
                          child: Container(
                            width: 200, // Increased from 180
                            height: 200, // Increased from 180
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 10),
                                ),
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.4),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Center(
                                child: Transform.scale(
                                  scale: _logoEnlarged ? 1.5 : 1.0, // Scale up the logo inside
                                  child: Image.asset(
                                    'assets/icons/LOGO2.png',
                                    width: _logoEnlarged ? 170 : 140, // Adjust size when enlarged
                                    height: _logoEnlarged ? 170 : 140,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // App name with animation
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _textSlideAnimation.value),
                        child: Opacity(
                          opacity: _opacityAnimation.value,
                          child: Text(
                            'DreamScape Resort',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Tagline with animation
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _textSlideAnimation.value),
                        child: Opacity(
                          opacity: _opacityAnimation.value,
                          child: Text(
                            'Where Technology Meets Paradise',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.9),
                              letterSpacing: 1.1,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _textSlideAnimation.value),
                        child: Opacity(
                          opacity: _opacityAnimation.value,
                          child: Text(
                            'Book, Pay, and Stay the Smart Way',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withOpacity(0.8),
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 60),

                  // Loading indicator (only shows before Get Started appears)
                  if (!_showGetStarted)
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _controller.value > 0.7 ? 1.0 : 0.0,
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              value: _controller.value > 0.7
                                  ? (_controller.value - 0.7) / 0.3
                                  : 0,
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withOpacity(0.8),
                              ),
                              backgroundColor: Colors.white.withOpacity(0.2),
                            ),
                          ),
                        );
                      },
                    ),

                  // Get Started Button (fades in after animation)
                  if (_showGetStarted)
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return AnimatedOpacity(
                          opacity: _buttonOpacityAnimation.value,
                          duration: const Duration(milliseconds: 800),
                          child: Container(
                            height: 56,
                            margin: const EdgeInsets.symmetric(horizontal: 40),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.shade700,
                                  Colors.cyan.shade600,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                                BoxShadow(
                                  color: Colors.blue.shade800.withOpacity(0.4),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _navigateToLandingPage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Get Started',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 24,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),

            // Bottom text
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _controller.value > 0.8 ? 1.0 : 0.0,
                    child: Column(
                      children: [
                        Text(
                          'DreamScape Resort System',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap "Get Started" to begin your journey',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.6),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}