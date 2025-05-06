import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
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
    
    return Container(
      margin: const EdgeInsets.only(top: 24.0),
      decoration: BoxDecoration(
        border: Border.all(color: primaryPurple.withAlpha(128)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: (_isAuthenticating || _isLoggingIn) ? null : _authenticateWithBiometrics,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _isAuthenticating
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryPurple),
                    ),
                  )
                : Icon(
                    biometricIcon,
                    size: 24,
                    color: (_isLoggingIn) ? Colors.grey : primaryPurple,
                  ),
              const SizedBox(width: 12),
              Text(
                _isAuthenticating 
                  ? 'Authenticating...' 
                  : (_isLoggingIn ? 'Please wait...' : biometricText),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: (_isLoggingIn) ? Colors.grey : primaryPurple,
                ),
              ),
            ],
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
    
    return Theme(
      data: ThemeData(
        primaryColor: primaryPurple,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryPurple,
          primary: primaryPurple,
          secondary: lightPurple,
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryPurple, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryPurple,
            foregroundColor: Colors.white,
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStatePropertyAll<Color>(primaryPurple),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryPurple,
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
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
              colors: [
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
                      horizontal: screenSize.width * 0.06, // Responsive padding
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
                            // App logo
                            Container(
                              padding: const EdgeInsets.all(16),
                              height: isSmallScreen ? 120 : 150,
                              child: Hero(
                                tag: 'app_logo', // For animation when navigating
                                child: Image.asset(
                                  'assets/images/ICON_APP.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 16 : 24),
                            // Welcome text
                            const Text(
                              'Welcome to MHR-HRIS',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: primaryPurple,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Human Resource Information System',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Sign in to continue',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: isSmallScreen ? 24 : 40),
                            // Login error message
                            if (_loginError != null)
                              Container(
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _loginError!,
                                        style: TextStyle(color: Colors.red[700], fontSize: 13),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      color: Colors.red[700],
                                      onPressed: _clearLoginError,
                                    ),
                                  ],
                                ),
                              ),
                            // Login form
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Email field
                                  TextFormField(
                                    controller: _emailController,
                                    focusNode: _emailFocusNode,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autocorrect: false,
                                    enabled: !_isLoggingIn,
                                    onFieldSubmitted: (_) {
                                      FocusScope.of(context).requestFocus(_passwordFocusNode);
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      hintText: 'Enter your email',
                                      prefixIcon: const Icon(Icons.email, color: primaryPurple),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                        horizontal: 16,
                                      ),
                                      labelStyle: TextStyle(color: Colors.grey[600]),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: primaryPurple,
                                          width: 2,
                                        ),
                                      ),
                                      errorText: _emailError,
                                      errorMaxLines: 2,
                                      errorStyle: const TextStyle(
                                        fontSize: 12,
                                      ),
                                    ),
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
                                  ),
                                  SizedBox(height: isSmallScreen ? 16 : 20),
                                  // Password field
                                  TextFormField(
                                    controller: _passwordController,
                                    focusNode: _passwordFocusNode,
                                    obscureText: !_isPasswordVisible,
                                    textInputAction: TextInputAction.done,
                                    enabled: !_isLoggingIn,
                                    onFieldSubmitted: (_) => _login(),
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      hintText: 'Enter your password',
                                      prefixIcon: const Icon(Icons.lock, color: primaryPurple),
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
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                        horizontal: 16,
                                      ),
                                      labelStyle: TextStyle(color: Colors.grey[600]),
                                      errorText: _passwordError,
                                      errorMaxLines: 2,
                                      errorStyle: const TextStyle(
                                        fontSize: 12,
                                      ),
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
                                  ),
                                  const SizedBox(height: 16),
                                  // Remember me and Contact System Admin
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: _rememberMe,
                                            onChanged: _isLoggingIn 
                                              ? null 
                                              : (value) {
                                                  setState(() {
                                                    _rememberMe = value ?? false;
                                                  });
                                                },
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ),
                                          Text(
                                            'Remember me',
                                            style: TextStyle(
                                              color: _isLoggingIn ? Colors.grey : Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                      TextButton(
                                        onPressed: _isLoggingIn ? null : () {
                                          // Navigate to Forgot Password screen
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Forgot Password feature coming soon'),
                                              backgroundColor: primaryPurple,
                                            ),
                                          );
                                        },
                                        child: const Text(
                                          'Forgot Password?',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isSmallScreen ? 20 : 24),
                                  // Login button with animation
                                  ScaleTransition(
                                    scale: _buttonAnimation,
                                    child: ElevatedButton(
                                      onPressed: _isLoggingIn ? null : _login,
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size.fromHeight(50),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 3,
                                        shadowColor: primaryPurple.withAlpha(128),
                                        disabledBackgroundColor: primaryPurple.withAlpha(153),
                                        disabledForegroundColor: Colors.white70,
                                      ),
                                      child: _isLoggingIn
                                        ? const Row(
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
                                              SizedBox(width: 12),
                                              Text(
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
                                            ),
                                          ),
                                    ),
                                  ),
                                  // Biometric login
                                  if (_canCheckBiometrics && _isBiometricSupported)
                                    Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Divider(
                                                  color: Colors.grey[400],
                                                  thickness: 1,
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                                child: Text(
                                                  'OR',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Divider(
                                                  color: Colors.grey[400],
                                                  thickness: 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        _buildBiometricButton(),
                                      ],
                                    ),
                                ],
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