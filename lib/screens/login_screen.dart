import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import 'dart:ui';
import 'package:device_info_plus/device_info_plus.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';

// Define purple theme colors
const Color primaryPurple = Color(0xFF6A1B9A); // Deep Purple 800
const Color lightPurple = Color(0xFF9C27B0);   // Purple 500
const Color accentPurple = Color(0xFFE1BEE7);  // Purple 100

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isAuthenticating = false;
  bool _isLoggingIn = false;
  String? _emailError;
  String? _passwordError;
  String? _loginError;

  // Shared preferences keys
  static const String _emailKey = 'email';
  static const String _passwordKey = 'password';
  static const String _rememberMeKey = 'rememberMe';

  // Animation controller for button press effect
  late AnimationController _animationController;
  late Animation<double> _buttonAnimation;

  // For biometric authentication
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  bool _isBiometricSupported = false;
  List<BiometricType> _availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    _checkBiometricSupport();
    _loadSavedCredentials();
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _buttonAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Add listeners to clear errors when typing
    _emailController.addListener(_clearEmailError);
    _passwordController.addListener(_clearPasswordError);
    
    // Schedule a post-frame callback to safely access context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_emailFocusNode);
      }
    });
  }

  // Load saved credentials from shared preferences
  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
      
      if (rememberMe) {
        final email = prefs.getString(_emailKey) ?? '';
        final password = prefs.getString(_passwordKey) ?? '';
        
        if (mounted) {
          setState(() {
            _emailController.text = email;
            _passwordController.text = password;
            _rememberMe = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading saved credentials: $e');
    }
  }

  // Save or clear credentials based on remember me checkbox
  Future<void> _saveCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (_rememberMe) {
        await prefs.setString(_emailKey, _emailController.text);
        await prefs.setString(_passwordKey, _passwordController.text);
        await prefs.setBool(_rememberMeKey, true);
      } else {
        await prefs.remove(_emailKey);
        await prefs.remove(_passwordKey);
        await prefs.setBool(_rememberMeKey, false);
      }
    } catch (e) {
      debugPrint('Error saving credentials: $e');
    }
  }

  void _clearEmailError() {
    if (_emailError != null) {
      setState(() {
        _emailError = null;
      });
    }
  }

  void _clearPasswordError() {
    if (_passwordError != null) {
      setState(() {
        _passwordError = null;
      });
    }
  }

  // Clear login error message
  void _clearLoginError() {
    if (_loginError != null) {
      setState(() {
        _loginError = null;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricSupport() async {
    bool canCheckBiometrics = false;
    bool isDeviceSupported = false;
    List<BiometricType> availableBiometrics = [];

    try {
      isDeviceSupported = await _localAuth.isDeviceSupported();
      if (isDeviceSupported) {
        canCheckBiometrics = await _localAuth.canCheckBiometrics;
        if (canCheckBiometrics) {
          availableBiometrics = await _localAuth.getAvailableBiometrics();
        }
      }
    } on PlatformException catch (e) {
      debugPrint('Error checking biometric support: $e');
    }

    if (mounted) {
      setState(() {
        _isBiometricSupported = isDeviceSupported;
        _canCheckBiometrics = canCheckBiometrics;
        _availableBiometrics = availableBiometrics;
      });
    }
  }

  // Get device info for login
  Future<String> _getDeviceName() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceName = 'Unknown Device';
    
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceName = '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceName = '${iosInfo.name} ${iosInfo.systemVersion}';
      }
    } catch (e) {
      debugPrint('Error getting device name: $e');
    }
    
    return deviceName;
  }

  Future<void> _authenticateWithBiometrics() async {
    if (_isAuthenticating) return;
    
    setState(() {
      _isAuthenticating = true;
      _clearLoginError();
    });
    
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to log in',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      
      if (!mounted) return;
      
      if (didAuthenticate) {
        setState(() {
          _isLoggingIn = true;
        });
        
        // Now try to login with saved credentials
        final prefs = await SharedPreferences.getInstance();
        final email = prefs.getString(_emailKey) ?? '';
        final password = prefs.getString(_passwordKey) ?? '';
        
        if (!mounted) return;
        
        if (email.isEmpty || password.isEmpty) {
          // If no saved credentials, show error
          setState(() {
            _isLoggingIn = false;
            _isAuthenticating = false;
            _loginError = 'No saved credentials for biometric login. Please login with email and password first.';
          });
          return;
        }
        
        final deviceName = await _getDeviceName();
        
        if (!mounted) return;
        
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        final success = await authProvider.login(
          email: email,
          password: password,
          deviceName: deviceName,
        );
        
        if (!mounted) return;
        
        if (success) {
          // Show success animation before navigating
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Authentication successful'),
                ],
              ),
              backgroundColor: primaryPurple,
              duration: Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          // Navigate after a short delay for better UX
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            }
          });
        } else {
          // Authentication failed
          setState(() {
            _isLoggingIn = false;
            _isAuthenticating = false;
            _loginError = authProvider.error ?? 'Authentication failed';
          });
        }
      } else {
        setState(() {
          _isAuthenticating = false;
        });
      }
    } on PlatformException catch (e) {
      debugPrint('Error authenticating: $e');
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
          _loginError = 'Biometric authentication error: ${e.message}';
        });
      }
    } catch (e) {
      debugPrint('General error during authentication: $e');
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
          _loginError = 'Authentication error: $e';
        });
      }
    }
  }

  void _login() async {
    // Hide keyboard when login button is pressed
    FocusScope.of(context).unfocus();
    
    // Clear any previous login errors
    _clearLoginError();
    
    if (_formKey.currentState!.validate()) {
      // Store credentials if "Remember Me" is checked
      await _saveCredentials();
      
      setState(() {
        _isLoggingIn = true;
      });
      
      try {
        final deviceName = await _getDeviceName();
        
        if (!mounted) return;
        
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        final success = await authProvider.login(
          email: _emailController.text,
          password: _passwordController.text,
          deviceName: deviceName,
        );
        
        if (!mounted) return;
        
        if (success) {
          // Show success animation before navigating
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Login successful'),
                ],
              ),
              backgroundColor: primaryPurple,
              duration: Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          // Navigate after a short delay for better UX
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            }
          });
        } else {
          // Login failed
          setState(() {
            _isLoggingIn = false;
            _loginError = authProvider.error ?? 'Login failed';
          });
          
          // Vibrate to indicate login failure
          HapticFeedback.mediumImpact();
          
          // Play button animation for visual feedback
          _animationController.forward().then((_) {
            _animationController.reverse();
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoggingIn = false;
            _loginError = 'Error during login: $e';
          });
          
          // Vibrate to indicate login failure
          HapticFeedback.mediumImpact();
        }
      }
    } else {
      // Vibrate to indicate validation failure
      HapticFeedback.mediumImpact();
      
      // Play button animation for visual feedback
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    }
  }

  // Helper method to build consistent text form fields
  Widget _buildTextFormField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    required String? errorText,
    required FormFieldValidator<String> validator,
    required bool isDarkMode,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    bool obscureText = false,
    Widget? suffixIcon,
    Function(String)? onFieldSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        obscureText: obscureText,
        autocorrect: false,
        enabled: !_isLoggingIn,
        onFieldSubmitted: onFieldSubmitted,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black87,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          hintStyle: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[400],
            fontSize: 14,
          ),
          labelStyle: TextStyle(
            color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
            fontSize: 16,
          ),
          prefixIcon: Icon(prefixIcon, color: primaryPurple),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: isDarkMode ? Colors.grey[900] : Colors.white,
          errorText: errorText,
          errorMaxLines: 2,
          errorStyle: const TextStyle(
            fontSize: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: primaryPurple,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
        validator: validator,
      ),
    );
  }
  
  // Enhanced biometric button with better visual design
  Widget _buildBiometricButton() {
    IconData biometricIcon = Icons.fingerprint;
    String biometricText = 'Fingerprint Login';
    
    if (_availableBiometrics.contains(BiometricType.face)) {
      biometricIcon = Icons.face;
      biometricText = 'Face ID Login';
    } else if (_availableBiometrics.contains(BiometricType.iris)) {
      biometricIcon = Icons.remove_red_eye;
      biometricText = 'Iris Login';
    }
    
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      height: 55,
      margin: const EdgeInsets.only(top: 8.0),
      decoration: BoxDecoration(
        border: Border.all(
          color: _isAuthenticating || _isLoggingIn 
              ? primaryPurple.withOpacity(0.3) 
              : primaryPurple.withOpacity(0.6),
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        color: isDarkMode 
            ? Colors.grey[900]!.withOpacity(0.5) 
            : Colors.white.withOpacity(0.8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: (_isAuthenticating || _isLoggingIn) ? null : () {
            HapticFeedback.mediumImpact();
            _authenticateWithBiometrics();
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: primaryPurple.withOpacity(0.1),
          highlightColor: primaryPurple.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _isAuthenticating
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _isLoggingIn 
                              ? primaryPurple.withOpacity(0.5) 
                              : primaryPurple
                        ),
                      ),
                    )
                  : Icon(
                      biometricIcon,
                      size: 24,
                      color: (_isLoggingIn) 
                          ? primaryPurple.withOpacity(0.5) 
                          : primaryPurple,
                    ),
                const SizedBox(width: 12),
                Text(
                  _isAuthenticating 
                    ? 'Authenticating...' 
                    : (_isLoggingIn ? 'Please wait...' : biometricText),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: (_isLoggingIn || _isAuthenticating) 
                        ? primaryPurple.withOpacity(0.5) 
                        : primaryPurple,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive design
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = brightness == Brightness.dark;
    
    return Theme(
      data: ThemeData(
        primaryColor: primaryPurple,
        brightness: brightness,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryPurple,
          primary: primaryPurple,
          secondary: lightPurple,
          brightness: brightness,
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primaryPurple, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryPurple,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: primaryPurple.withAlpha(100),
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.disabled)) {
                return Colors.grey.withOpacity(.32);
              }
              return primaryPurple;
            },
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryPurple,
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDarkMode 
                ? [
                    Colors.black,
                    Color(0xFF1A1A1A),
                  ]
                : [
                    accentPurple.withAlpha(77),
                    Colors.white,
                  ],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  // Dismiss keyboard when tapping outside form fields
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenSize.width * 0.06,
                      vertical: 16,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 32, // Account for padding
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: isSmallScreen ? 20 : 40),
                            // App logo with animation
                            TweenAnimationBuilder(
                              duration: const Duration(milliseconds: 800),
                              tween: Tween<double>(begin: 0.8, end: 1.0),
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
                                padding: const EdgeInsets.all(16),
                                height: isSmallScreen ? 120 : 150,
                                child: Hero(
                                  tag: 'app_logo',
                                  child: Image.asset(
                                    isDarkMode 
                                        ? 'assets/images/whiteICON_APP.png'
                                        : 'assets/images/ICON_APP.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 16 : 24),
                            // Welcome text with animation
                            TweenAnimationBuilder(
                              duration: const Duration(milliseconds: 800),
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
                              child: Column(
                                children: [
                                  Text(
                                    'Welcome to MHR-HRIS',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: primaryPurple,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Human Resource Information System',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Sign in to continue',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 24 : 40),
                            // Login error message with animation
                            if (_loginError != null)
                              TweenAnimationBuilder(
                                duration: const Duration(milliseconds: 300),
                                tween: Tween<double>(begin: 0.0, end: 1.0),
                                curve: Curves.easeOut,
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(0, (1 - value) * -10),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.red[isDarkMode ? 900 : 50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.red.shade200),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withAlpha(isDarkMode ? 40 : 20),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error_outline, 
                                          color: Colors.red[isDarkMode ? 300 : 700], 
                                          size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _loginError!,
                                          style: TextStyle(
                                            color: Colors.red[isDarkMode ? 300 : 700], 
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 18),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        color: Colors.red[isDarkMode ? 300 : 700],
                                        onPressed: _clearLoginError,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            // Login form with staggered animation
                            TweenAnimationBuilder(
                              duration: const Duration(milliseconds: 800),
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, (1 - value) * 30),
                                    child: child,
                                  ),
                                );
                              },
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Email field with enhanced design
                                    _buildTextFormField(
                                      controller: _emailController,
                                      focusNode: _emailFocusNode,
                                      labelText: 'Email',
                                      hintText: 'Enter your email',
                                      prefixIcon: Icons.email,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      errorText: _emailError,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          setState(() {
                                            _emailError = 'Please enter your email';
                                          });
                                          return '';
                                        }
                                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                          setState(() {
                                            _emailError = 'Please enter a valid email address';
                                          });
                                          return '';
                                        }
                                        return null;
                                      },
                                      onFieldSubmitted: (_) {
                                        FocusScope.of(context).requestFocus(_passwordFocusNode);
                                      },
                                      isDarkMode: isDarkMode,
                                    ),
                                    
                                    SizedBox(height: isSmallScreen ? 16 : 20),
                                    
                                    // Password field with enhanced design
                                    _buildTextFormField(
                                      controller: _passwordController,
                                      focusNode: _passwordFocusNode,
                                      labelText: 'Password',
                                      hintText: 'Enter your password',
                                      prefixIcon: Icons.lock,
                                      obscureText: !_isPasswordVisible,
                                      textInputAction: TextInputAction.done,
                                      errorText: _passwordError,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isPasswordVisible
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          color: primaryPurple,
                                        ),
                                        onPressed: _isLoggingIn ? null : () {
                                          setState(() {
                                            _isPasswordVisible = !_isPasswordVisible;
                                          });
                                        },
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          setState(() {
                                            _passwordError = 'Please enter your password';
                                          });
                                          return '';
                                        }
                                        if (value.length < 6) {
                                          setState(() {
                                            _passwordError = 'Password must be at least 6 characters';
                                          });
                                          return '';
                                        }
                                        return null;
                                      },
                                      onFieldSubmitted: (_) => _login(),
                                      isDarkMode: isDarkMode,
                                    ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Remember me and Forgot Password row
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: Checkbox(
                                                value: _rememberMe,
                                                onChanged: _isLoggingIn 
                                                  ? null 
                                                  : (value) {
                                                      setState(() {
                                                        _rememberMe = value ?? false;
                                                      });
                                                      // Add haptic feedback
                                                      HapticFeedback.selectionClick();
                                                    },
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Remember me',
                                              style: TextStyle(
                                                color: _isLoggingIn 
                                                    ? (isDarkMode ? Colors.grey[400] : Colors.grey[500])
                                                    : (isDarkMode ? Colors.grey[300] : Colors.black87),
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        TextButton(
                                          onPressed: _isLoggingIn ? null : () {
                                            // Navigate to Forgot Password screen
                                            HapticFeedback.lightImpact();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Forgot Password feature coming soon'),
                                                backgroundColor: primaryPurple,
                                              ),
                                            );
                                          },
                                          child: Text(
                                            'Forgot Password?',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: _isLoggingIn 
                                                  ? primaryPurple.withOpacity(0.5)
                                                  : primaryPurple,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    SizedBox(height: isSmallScreen ? 20 : 30),
                                    
                                    // Enhanced login button with better animation
                                    ScaleTransition(
                                      scale: _buttonAnimation,
                                      child: Container(
                                        height: 55,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: primaryPurple.withOpacity(0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton(
                                          onPressed: _isLoggingIn ? null : _login,
                                          style: ElevatedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            elevation: 0,
                                            backgroundColor: primaryPurple,
                                            disabledBackgroundColor: primaryPurple.withOpacity(0.5),
                                            disabledForegroundColor: Colors.white70,
                                            padding: EdgeInsets.zero,
                                          ),
                                          child: _isLoggingIn
                                            ? Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  const Text(
                                                    'Signing in...',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : const Text(
                                                'Sign In',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                        ),
                                      ),
                                    ),
                                    
                                    // Biometric login with enhanced animation
                                    if (_canCheckBiometrics && _isBiometricSupported)
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
                                        child: Column(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Divider(
                                                      color: isDarkMode 
                                                          ? Colors.grey[700] 
                                                          : Colors.grey[300],
                                                      thickness: 1,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                                    child: Text(
                                                      'OR',
                                                      style: TextStyle(
                                                        color: isDarkMode 
                                                            ? Colors.grey[400] 
                                                            : Colors.grey[600],
                                                        fontWeight: FontWeight.w500,
                                                        letterSpacing: 1.0,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Divider(
                                                      color: isDarkMode 
                                                          ? Colors.grey[700] 
                                                          : Colors.grey[300],
                                                      thickness: 1,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            _buildBiometricButton(),
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
                );
              },
            ),
          ),
        ),
      ),
    );
  }
} 