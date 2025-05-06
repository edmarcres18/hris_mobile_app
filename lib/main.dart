import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/intro_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'routes/app_router.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';

// Define the app's main color scheme for consistency
const Color primaryPurple = Color(0xFF6A1B9A); // Deep Purple 800
const Color lightPurple = Color(0xFF9C27B0);   // Purple 500
const Color accentPurple = Color(0xFFE1BEE7);  // Purple 100

// Utility function to reset first launch state (for testing)
Future<void> resetFirstLaunch() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isFirstLaunch', true);
}

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Uncomment the line below to reset first launch state (for testing)
  // await resetFirstLaunch();
  
  // Check if it's the first app launch
  final prefs = await SharedPreferences.getInstance();
  final bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
  
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
    ],
    child: MyApp(isFirstLaunch: isFirstLaunch),
  ));
}

class MyApp extends StatelessWidget {
  final bool isFirstLaunch;
  
  const MyApp({super.key, required this.isFirstLaunch});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MHR-HRIS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryPurple,
          primary: primaryPurple,
          secondary: lightPurple,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryPurple,
            foregroundColor: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryPurple, width: 2),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      // Set up the initial route based on first launch status
      home: isFirstLaunch ? const IntroScreen() : const LoginScreen(),
      // Register the onGenerateRoute handler to enable navigation throughout the app
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isLoading = true;
  bool _isFirstLaunch = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAppState();
  }

  Future<void> _checkAppState() async {
    // Check if this is the first app launch
    final prefs = await SharedPreferences.getInstance();
    _isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

    if (!mounted) return;

    // Initialize auth provider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initialize();
    
    if (!mounted) return;
    
    _isLoggedIn = authProvider.isLoggedIn;

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_isFirstLaunch) {
      return const IntroScreen();
    }

    if (_isLoggedIn) {
      return const HomeScreen();
    }

    return const LoginScreen();
  }

  Widget _buildLoadingScreen() {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6A1B9A), // Deep Purple
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/ICON_APP.png',
                width: 120,
                height: 120,
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              const Text(
                'Starting MHR-HRIS...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
