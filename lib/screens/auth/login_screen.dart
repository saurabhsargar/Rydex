import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rydex/screens/home/home_screen.dart';
import '../../providers/auth_provider.dart';
import 'signup_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String email = '', password = '';
  bool loading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => loading = true);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final error = await authProvider.signIn(email, password);
      setState(() => loading = false);

      if (error == null) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.teal.shade700,
              Colors.teal.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo and App Name
                  Icon(
                    Icons.directions_car_rounded,
                    size: 80,
                    color: Colors.white,
                  )
                  .animate(controller: _animationController)
                  .scale(duration: 600.ms, curve: Curves.easeOutBack)
                  .then()
                  .shimmer(duration: 1200.ms),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    "GreenRide",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  )
                  .animate(controller: _animationController)
                  .fadeIn(duration: 800.ms, delay: 300.ms)
                  .moveY(begin: 20, end: 0, curve: Curves.easeOutQuad),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    "Welcome back",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  )
                  .animate(controller: _animationController)
                  .fadeIn(duration: 800.ms, delay: 500.ms),
                  
                  const SizedBox(height: 40),
                  
                  // Login Form
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade800,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Email Field
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined, color: Colors.teal.shade600),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.teal.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.teal.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.teal.shade600, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.teal.shade50.withOpacity(0.3),
                            ),
                            onChanged: (val) => email = val,
                            validator: (val) => val!.isEmpty ? 'Enter email' : null,
                            keyboardType: TextInputType.emailAddress,
                          )
                          .animate(controller: _animationController)
                          .fadeIn(duration: 600.ms, delay: 700.ms)
                          .moveX(begin: -20, end: 0, curve: Curves.easeOutQuad),
                          
                          const SizedBox(height: 16),
                          
                          // Password Field
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline, color: Colors.teal.shade600),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.teal.shade600,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.teal.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.teal.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.teal.shade600, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.teal.shade50.withOpacity(0.3),
                            ),
                            obscureText: _obscurePassword,
                            onChanged: (val) => password = val,
                            validator: (val) => val!.length < 6 ? 'Min 6 characters' : null,
                          )
                          .animate(controller: _animationController)
                          .fadeIn(duration: 600.ms, delay: 900.ms)
                          .moveX(begin: -20, end: 0, curve: Curves.easeOutQuad),
                          
                          const SizedBox(height: 24),
                          
                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: loading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal.shade600,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: loading
                                  ? SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      "Login",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          )
                          .animate(controller: _animationController)
                          .fadeIn(duration: 600.ms, delay: 1100.ms)
                          .moveY(begin: 20, end: 0, curve: Curves.easeOutQuad),
                        ],
                      ),
                    ),
                  )
                  .animate(controller: _animationController)
                  .fadeIn(duration: 800.ms, delay: 600.ms)
                  .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutQuad),
                  
                  const SizedBox(height: 24),
                  
                  // Sign Up Link
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => const SignUpScreen(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                          transitionDuration: const Duration(milliseconds: 800),
                        ),
                      );
                    },
                    child: Text(
                      "Don't have an account? Sign up",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  )
                  .animate(controller: _animationController)
                  .fadeIn(duration: 600.ms, delay: 1300.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}