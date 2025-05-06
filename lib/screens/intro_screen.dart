import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'dart:ui';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  int _currentPage = 0;

  final List<IntroPage> _pages = [
    const IntroPage(
      title: 'Welcome to MHR-HRIS',
      description: 'Your complete HR management solution in one app',
      icon: Icons.business,
      color: Color(0xFF6A1B9A), // Deep Purple 800
      assetImage: 'assets/images/ICON_APP.png',
    ),
    const IntroPage(
      title: 'Track Attendance',
      description: 'Monitor your attendance, leaves and schedule',
      icon: Icons.today,
      color: Color(0xFF2196F3), // Blue 500
      assetImage: 'assets/images/track_attendance.png',
    ),
    const IntroPage(
      title: 'View Payslips',
      description: 'Access your payslips and financial information securely',
      icon: Icons.attach_money,
      color: Color(0xFF4CAF50), // Green 500
      assetImage: 'assets/images/payroll.png',
    ),
  ];

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
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Function to mark first launch as completed
  Future<void> _setFirstLaunchCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstLaunch', false);
  }

  void _goToNextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _navigateToLogin();
    }
  }
  
  // Extracted method to avoid BuildContext across async gaps
  void _navigateToLogin() {
    // Mark first launch as completed and navigate
    _setFirstLaunchCompleted().then((_) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isDarkMode ? Colors.black : Colors.white,
              _pages[_currentPage].color.withAlpha(isDarkMode ? 38 : 13),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: EdgeInsets.fromLTRB(
                  size.width * 0.05, 
                  size.height * 0.02, 
                  size.width * 0.05, 
                  0
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo or brand icon
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: EdgeInsets.all(size.width * 0.025),
                              decoration: BoxDecoration(
                                color: _pages[_currentPage].color.withAlpha(26),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _pages[_currentPage].color.withAlpha(51),
                                  width: 1,
                                ),
                              ),
                              child: Image.asset(
                                isDarkMode ? 'assets/images/whiteICON_APP.png' : 'assets/images/ICON_APP.png',
                                width: size.width * 0.05,
                                height: size.width * 0.05,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: size.width * 0.02),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MHR-HRIS',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: size.width * 0.042,
                                color: _pages[_currentPage].color,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'Human Resource Information System',
                              style: TextStyle(
                                fontSize: size.width * 0.025,
                                color: _pages[_currentPage].color.withAlpha(204),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Skip button
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _pages[_currentPage].color.withAlpha(13),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: _pages[_currentPage].color.withAlpha(51),
                              width: 1,
                            ),
                          ),
                          child: TextButton(
                            onPressed: _navigateToLogin,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: size.width * 0.04,
                                vertical: size.height * 0.01,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              'Skip',
                              style: TextStyle(
                                color: _pages[_currentPage].color,
                                fontWeight: FontWeight.w600,
                                fontSize: size.width * 0.035,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Page View
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                      _animationController.reset();
                      _animationController.forward();
                    });
                  },
                  itemBuilder: (context, index) {
                    return _pages[index];
                  },
                ),
              ),
              
              // Navigation Controls
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.06, 
                  vertical: size.height * 0.03
                ),
                child: Column(
                  children: [
                    // Progress indicator
                    Container(
                      height: size.height * 0.006,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(size.width * 0.03),
                      ),
                      child: Stack(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            width: size.width * ((_currentPage + 1) / _pages.length) * 0.88,
                            decoration: BoxDecoration(
                              color: _pages[_currentPage].color,
                              borderRadius: BorderRadius.circular(size.width * 0.03),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: size.height * 0.025),
                    
                    // Next button
                    InkWell(
                      onTap: _goToNextPage,
                      child: Container(
                        height: size.height * 0.07,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _pages[_currentPage].color,
                          borderRadius: BorderRadius.circular(size.width * 0.04),
                          boxShadow: [
                            BoxShadow(
                              color: _pages[_currentPage].color.withAlpha(77),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: size.width * 0.045,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(width: size.width * 0.02),
                            Icon(
                              _currentPage < _pages.length - 1 
                                  ? Icons.arrow_forward_rounded 
                                  : Icons.check_circle_outline_rounded,
                              color: Colors.white,
                              size: size.width * 0.055,
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
    );
  }
}

class IntroPage extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String assetImage;

  const IntroPage({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.assetImage,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = brightness == Brightness.dark;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Spacer to push content down a bit
          SizedBox(height: size.height * 0.02),
          
          // Image
          Container(
            width: size.width * 0.8,
            height: size.height * 0.35,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size.width * 0.05),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(26),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(size.width * 0.05),
              child: Image.asset(
                assetImage,
                fit: BoxFit.contain,
              ),
            ),
          ),
          
          SizedBox(height: size.height * 0.06),
          
          // Title with colored background chip
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.05,
              vertical: size.height * 0.01,
            ),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(size.width * 0.05),
              border: Border.all(
                color: color.withAlpha(77),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: EdgeInsets.all(size.width * 0.02),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(size.width * 0.02),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: size.width * 0.05,
                  ),
                ),
                SizedBox(width: size.width * 0.02),
                // Title
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: size.width * 0.05,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: size.height * 0.03),
          
          // Description
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: size.width * 0.04,
              color: isDarkMode ? Colors.white70 : Colors.black87,
              height: 1.5,
            ),
          ),
          
          // Flexible spacer at the bottom
          SizedBox(height: size.height * 0.03),
        ],
      ),
    );
  }
} 