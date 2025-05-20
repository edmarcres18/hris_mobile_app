import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'dart:ui';
import 'dart:math' as math;

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
    
    // Set preferred orientation for better UX
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    // Reset orientation settings when leaving this screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  // Function to mark first launch as completed
  Future<void> _setFirstLaunchCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstLaunch', false);
  }

  void _goToNextPage() {
    // Add haptic feedback for better UX
    HapticFeedback.lightImpact();
    
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
    // Add haptic feedback for better UX
    HapticFeedback.mediumImpact();
    
    // Mark first launch as completed and navigate
    _setFirstLaunchCompleted().then((_) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              var begin = const Offset(0.0, 0.1);
              var end = Offset.zero;
              var curve = Curves.easeOutCubic;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);
              
              return SlideTransition(
                position: offsetAnimation,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
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
              _buildAppBar(size, isDarkMode),
              
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
                    // Add haptic feedback for page change
                    HapticFeedback.selectionClick();
                  },
                  itemBuilder: (context, index) {
                    return _pages[index];
                  },
                ),
              ),
              
              // Navigation Controls
              _buildNavigationControls(size, isDarkMode),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAppBar(Size size, bool isDarkMode) {
    return Padding(
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
              TweenAnimationBuilder(
                duration: const Duration(milliseconds: 800),
                tween: Tween<double>(begin: 0.0, end: 1.0),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: _buildLogoContainer(size, isDarkMode),
              ),
              SizedBox(width: size.width * 0.02),
              TweenAnimationBuilder(
                duration: const Duration(milliseconds: 800),
                tween: Tween<double>(begin: 0.0, end: 1.0),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset((1 - value) * 20, 0),
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: Column(
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
              ),
            ],
          ),
          // Skip button
          TweenAnimationBuilder(
            duration: const Duration(milliseconds: 800),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset((1 - value) * 20, 0),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: _buildSkipButton(size),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLogoContainer(Size size, bool isDarkMode) {
    return ClipRRect(
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
            boxShadow: [
              BoxShadow(
                color: _pages[_currentPage].color.withAlpha(26),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Image.asset(
            isDarkMode ? 'assets/images/whiteICON_APP.png' : 'assets/images/ICON_APP.png',
            width: size.width * 0.05,
            height: size.width * 0.05,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
  
  Widget _buildSkipButton(Size size) {
    return ClipRRect(
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
            boxShadow: [
              BoxShadow(
                color: _pages[_currentPage].color.withAlpha(20),
                blurRadius: 8,
                spreadRadius: 0.5,
              ),
            ],
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
    );
  }
  
  Widget _buildNavigationControls(Size size, bool isDarkMode) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.06, 
        vertical: size.height * 0.03
      ),
      child: Column(
        children: [
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(horizontal: size.width * 0.01),
                height: size.height * 0.008,
                width: _currentPage == index ? size.width * 0.08 : size.width * 0.018,
                decoration: BoxDecoration(
                  color: _currentPage == index 
                      ? _pages[_currentPage].color 
                      : _pages[_currentPage].color.withAlpha(77),
                  borderRadius: BorderRadius.circular(size.width * 0.03),
                ),
              );
            }),
          ),
          SizedBox(height: size.height * 0.025),
          
          // Next button with animated ripple effect
          TweenAnimationBuilder(
            duration: const Duration(milliseconds: 600),
            tween: Tween<double>(begin: 0.95, end: 1.0),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: InkWell(
              onTap: _goToNextPage,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: size.height * 0.07,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _pages[_currentPage].color,
                  borderRadius: BorderRadius.circular(size.width * 0.04),
                  boxShadow: [
                    BoxShadow(
                      color: _pages[_currentPage].color.withAlpha(90),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Animated ripple effect
                    if (_currentPage == _pages.length - 1)
                      TweenAnimationBuilder(
                        duration: const Duration(milliseconds: 1500),
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.rotate(
                            angle: value * 2 * math.pi,
                            child: child,
                          );
                        },
                        child: Icon(
                          Icons.check_circle_outline_rounded,
                          color: Colors.white.withOpacity(0.2),
                          size: size.width * 0.15,
                        ),
                      ),
                    Row(
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
                  ],
                ),
              ),
            ),
          ),
        ],
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
          
          // Image with subtle animation
          TweenAnimationBuilder(
            duration: const Duration(milliseconds: 800),
            tween: Tween<double>(begin: 0.6, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Container(
              width: size.width * 0.8,
              height: size.height * 0.35,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size.width * 0.05),
                boxShadow: [
                  BoxShadow(
                    color: color.withAlpha(40),
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
          ),
          
          SizedBox(height: size.height * 0.06),
          
          // Title with colored background chip
          TweenAnimationBuilder(
            duration: const Duration(milliseconds: 800),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, (1 - value) * 30),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Container(
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
                boxShadow: [
                  BoxShadow(
                    color: color.withAlpha(20),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
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
                      boxShadow: [
                        BoxShadow(
                          color: color.withAlpha(128),
                          blurRadius: 5,
                          spreadRadius: 0.5,
                        ),
                      ],
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
          ),
          
          SizedBox(height: size.height * 0.03),
          
          // Description with fade-in animation
          TweenAnimationBuilder(
            duration: const Duration(milliseconds: 1000),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * 20),
                  child: child,
                ),
              );
            },
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: size.width * 0.04,
                color: isDarkMode ? Colors.white70 : Colors.black87,
                height: 1.5,
                letterSpacing: 0.2,
              ),
            ),
          ),
          
          // Flexible spacer at the bottom
          SizedBox(height: size.height * 0.03),
        ],
      ),
    );
  }
} 