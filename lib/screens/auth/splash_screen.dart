import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';
import '../home/home_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late AuthProvider authProvider;
  bool _showGoButton = false;

  @override
  void initState() {
    super.initState();
    authProvider = Provider.of<AuthProvider>(context, listen: false);

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    // Show go button after animations complete
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showGoButton = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleGoButton() {
    authProvider.authState.first.then((user) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) =>
                  user != null ? HomeScreen() : LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade600, Colors.teal.shade900],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 32.0,
              vertical: 40.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // App Logo/Image
                Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Icon(
                          Icons.eco,
                          size: 60,
                          color: Colors.teal.shade600,
                        ),
                      ),
                    )
                    .animate()
                    .scale(delay: 200.ms, duration: 800.ms)
                    .fadeIn(duration: 800.ms),

                const SizedBox(height: 40),

                // Car animation (smaller size)
                // Lottie.network(
                //   'https://assets10.lottiefiles.com/packages/lf20_khzniaya.json',
                //   width: 150,
                //   height: 150,
                //   fit: BoxFit.contain,
                // ),
                const SizedBox(height: 32),

                // App name with animation
                Text(
                      'GreenRide',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .then()
                    .shimmer(
                      duration: 1200.ms,
                      color: Colors.white.withOpacity(0.8),
                    ),

                const SizedBox(height: 16),

                // Description
                Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Join the eco-friendly revolution! Share rides, reduce emissions, and make a positive impact on our planet while saving money.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          letterSpacing: 0.5,
                          height: 1.4,
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 800.ms)
                    .slideY(begin: 0.3, end: 0),

                const Spacer(),

                // Go Button
                if (_showGoButton)
                  Container(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _handleGoButton,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.teal.shade700,
                            elevation: 8,
                            shadowColor: Colors.black.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Get Started',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 24),
                            ],
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.5, end: 0)
                      .then()
                      .animate(
                        onPlay:
                            (controller) => controller.repeat(reverse: true),
                      )
                      .shimmer(
                        duration: 2000.ms,
                        color: Colors.teal.shade200.withOpacity(0.3),
                      ),

                const SizedBox(height: 20),

                // Alternative: Skip for now option
                // if (_showGoButton)
                //   TextButton(
                //     onPressed: _handleGoButton,
                //     child: Text(
                //       'Continue',
                //       style: TextStyle(
                //         color: Colors.white.withOpacity(0.8),
                //         fontSize: 16,
                //         decoration: TextDecoration.underline,
                //       ),
                //     ),
                //   ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
