// ignore_for_file: use_key_in_widget_constructors

import 'package:diurecycle/Screen/home.dart';
import 'package:diurecycle/Screen/login.dart';
import 'package:diurecycle/Screen/update_screens.dart';
import 'package:diurecycle/services/update_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _checkVersionAndLogin();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.0, 0.5, curve: Curves.easeOutBack),
    ));

    // Start animation
    _animationController.forward();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
 
    await Future.delayed(Duration(seconds: 3));

    if (!mounted) return;


    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;


    if (isFirstLaunch) {
      await prefs.setBool('isFirstLaunch', false);
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OnboardingScreen(
          onComplete: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
            );
          },
        )),
      );
      return;
    }

    User? currentUser = FirebaseAuth.instance.currentUser;
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (currentUser != null && isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      await prefs.setBool('isLoggedIn', false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
              Colors.green.shade50,
              Colors.white,
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        height: 150,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.2),
                              blurRadius: 15,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.asset(
                            'lib/assets/logo.png',
                            height: 100, 
                            width: 100,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // App Name
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'DIU ReCycle',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),

                  // Tagline
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'Buy, sell, reduce, reuse!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  SizedBox(height: 48),

                  // Loading indicator
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.green.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  
  void _checkVersionAndLogin() async {
    if (!mounted) return;
    final updateService = UpdateService();
    final updateStatus = await updateService.checkUpdate();

    if (!mounted) return;

    if (updateStatus['isUnderMaintenance']) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MaintenancePage()),
      );
      return;
    }

    if (updateStatus['needsUpdate']) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => UpdatePromptPage(
            onUpdate: () {
            },
          ),
        ),
      );
      return;
    }
  }
}

// Onboarding screen class
class OnboardingScreen extends StatelessWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // App Logo
                          Container(
                            height: 120,
                            width: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.2),
                                  blurRadius: 15,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Image.asset(
                                'lib/assets/logo.png',
                                height: 80,
                                width: 80,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          SizedBox(height: 40),
                          
                          // Thank you header
                          Text(
                            'Welcome to DIU ReCycle!',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          
                          // Thank you message
                          Text(
                            'Thank you for installing my app and helping me to test it! Your feedback will be invaluable as i work to improve your experience.\n Thank you!\n -Rafi', 
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: Colors.grey.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 32),
                          
                          // App features
                          _buildFeatureItem(
                            Icons.sync, 
                            'Buy & Sell Used Items',
                            'Find great deals on pre-owned items or sell items you no longer need'
                          ),
                          SizedBox(height: 24),
                          _buildFeatureItem(
                            Icons.eco, 
                            'Support Sustainability',
                            'Reduce waste by giving items a second life through reuse and recycling'
                          ),
                          SizedBox(height: 24),
                          _buildFeatureItem(
                            Icons.school, 
                            'Campus Community',
                            'Connect with other students and faculty members at DIU'
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Get started button
                Padding(
                  padding: const EdgeInsets.only(bottom: 32.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: onComplete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
    );
  }
  
  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.green.shade700,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}